/* Kassan'Mou SW v64d — www.kassanmou.net */
var CACHE = 'km-v64d';
var PRECACHE = ['/', '/index.html', '/manifest.json'];

self.addEventListener('install', function(e) {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then(function(c) {
      return c.addAll(PRECACHE).catch(function() { return; });
    })
  );
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE; })
            .map(function(k) { return caches.delete(k); })
      );
    })
    .then(function() { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function(e) {
  if (e.request.method !== 'GET') return;
  var u = new URL(e.request.url);
  /* Ne pas intercepter les appels externes */
  if (u.hostname.includes('supabase.co') ||
      u.hostname.includes('emailjs.com') ||
      u.hostname.includes('jsdelivr.net') ||
      u.hostname.includes('fonts.g') ||
      u.hostname.includes('wa.me') ||
      u.hostname.includes('cinetpay')) return;

  e.respondWith(
    fetch(e.request.clone()).then(function(r) {
      /* Cloner AVANT de mettre en cache */
      if (r && r.ok) {
        var rc = r.clone();
        caches.open(CACHE).then(function(ca) { ca.put(e.request, rc); });
      }
      return r;
    }).catch(function() {
      return caches.match(e.request).then(function(cached) {
        return cached || caches.match('/');
      });
    })
  );
});

console.log('[KM-SW] v64d actif — www.kassanmou.net');
