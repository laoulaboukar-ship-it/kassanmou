/* Kassan'Mou SW v44c */
var CACHE_NAME = 'kassanmou-v44c';
var OFFLINE_URL = '/kassanmou/';

self.addEventListener('install', function(e) {
  self.skipWaiting();
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.map(function(k) { return caches.delete(k); })
      );
    }).then(function() { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function(e) {
  var req = e.request;
  var url = new URL(req.url);
  if (req.method !== 'GET') return;
  if (url.hostname.includes('supabase.co') ||
      url.hostname.includes('emailjs.com') ||
      url.hostname.includes('jsdelivr.net')) return;
  e.respondWith(
    fetch(req).then(function(res) {
      return res;
    }).catch(function() {
      return caches.match(req);
    })
  );
});

console.log("[KM-SW] v44c actif — tous les anciens caches supprimés");
