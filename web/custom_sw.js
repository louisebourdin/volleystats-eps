// Ancien service worker de cache hors-ligne, desactive : il empechait les
// mises a jour de l'application de s'afficher chez les visiteurs qui
// l'avaient deja installe (le cache-first servait indefiniment l'ancienne
// version). Cette version se contente de se desinstaller elle-meme et de
// vider les caches qu'elle avait crees, puis ne se reinstallera plus car
// index.html ne l'enregistre plus.
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(names.map((n) => caches.delete(n)));
      await self.registration.unregister();
      const clientsList = await self.clients.matchAll({ type: 'window' });
      clientsList.forEach((client) => {
        if (client.url && 'navigate' in client) client.navigate(client.url);
      });
    })()
  );
});
