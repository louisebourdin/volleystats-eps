// Service worker maison : Flutter a rendu obsolète (et desactive) son
// mecanisme de cache automatique dans les versions recentes, donc on
// implemente nous-memes une strategie "cache-first" simple et fiable pour
// que l'application fonctionne hors-ligne une fois ouverte au moins une fois.
//
// Incrementer CACHE_NAME a chaque nouvelle version deployee : le changement
// d'octets de ce fichier declenche la mise a jour du service worker, qui
// videra alors l'ancien cache.
const CACHE_NAME = 'volleystats-cache-v1';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((names) => Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;

      return fetch(event.request)
        .then((response) => {
          if (response && response.status === 200) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          }
          return response;
        })
        .catch(() => cached);
    })
  );
});
