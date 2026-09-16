# Serveur de fichiers statiques minimal pour build/web, en socket brut (pas
# HttpListener/HTTP.sys) afin d'ecouter sur toutes les interfaces
# (localhost + reseau local) SANS droits administrateur.
# Idempotent : si le port est deja occupe (serveur deja lance), on ne fait rien.

$root = Join-Path $PSScriptRoot "..\build\web"
$root = (Resolve-Path $root).Path
$port = 8765

$contentTypes = @{
    ".html"        = "text/html; charset=utf-8"
    ".js"          = "application/javascript"
    ".mjs"         = "application/javascript"
    ".css"         = "text/css"
    ".json"        = "application/json"
    ".png"         = "image/png"
    ".jpg"         = "image/jpeg"
    ".jpeg"        = "image/jpeg"
    ".svg"         = "image/svg+xml"
    ".ico"         = "image/x-icon"
    ".woff"        = "font/woff"
    ".woff2"       = "font/woff2"
    ".ttf"         = "font/ttf"
    ".wasm"        = "application/wasm"
    ".map"         = "application/json"
    ".txt"         = "text/plain"
    ".webmanifest" = "application/manifest+json"
}

Add-Type -AssemblyName System.Net

$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
try {
    $listener.Start()
} catch {
    # Deja lance sur ce port (par ce PC ou pour le reseau local) : rien a faire.
    exit 0
}

function Handle-Client($client) {
    try {
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)

        $requestLine = $reader.ReadLine()
        if ([string]::IsNullOrEmpty($requestLine)) { $client.Close(); return }

        # Consomme les en-tetes de la requete jusqu'a la ligne vide.
        while (-not [string]::IsNullOrEmpty($reader.ReadLine())) { }

        $parts = $requestLine.Split(' ')
        $rawPath = if ($parts.Length -ge 2) { $parts[1] } else { "/" }
        $rawPath = $rawPath.Split('?')[0]
        $localPath = [System.Uri]::UnescapeDataString($rawPath).TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($localPath)) { $localPath = "index.html" }

        $filePath = Join-Path $root $localPath
        $resolvedRoot = $root.TrimEnd('\') + '\'
        $isInsideRoot = $false
        try {
            $fullFilePath = [System.IO.Path]::GetFullPath($filePath)
            $isInsideRoot = $fullFilePath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)
        } catch { $isInsideRoot = $false }

        if (-not $isInsideRoot -or -not (Test-Path $filePath -PathType Leaf)) {
            # SPA fallback : toute route inconnue retombe sur index.html.
            $filePath = Join-Path $root "index.html"
        }

        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $ext = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
        $contentType = $contentTypes[$ext]
        if (-not $contentType) { $contentType = "application/octet-stream" }

        $headerText = "HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`nAccess-Control-Allow-Origin: *`r`n`r`n"
        $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headerText)
        $stream.Write($headerBytes, 0, $headerBytes.Length)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
    } catch {
        # Client parti / requete invalide : on ignore simplement.
    } finally {
        $client.Close()
    }
}

while ($true) {
    try {
        $client = $listener.AcceptTcpClient()
    } catch {
        break
    }
    Handle-Client $client
}
