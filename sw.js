/* ================================================
   Kassan'Mou — Service Worker v43
   Stratégie : Cache-first ressources statiques
   Network-first données dynamiques
   Optimisé pour connexions 3G Niger
   ================================================ */

const CACHE_NAME = 'kassanmou-v44';
const OFFLINE_URL = '/kassanmou/';

const PRECACHE_URLS = [
  '/kassanmou/',
  '/kassanmou/index.html',
  '/kassanmou/manifest.json',
  '/kassanmou/icon-192.png',
  '/kassanmou/icon-512.png'
];

self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(PRECACHE_URLS).catch(function(err) {
        console.warn('[KM-SW-v43] Précache partiel:', err);
        return Promise.resolve();
      });
    }).then(function() { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames
          .filter(function(name) { return name !== CACHE_NAME; })
          .map(function(name) { return caches.delete(name); })
      );
    }).then(function() { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function(event) {
  var request = event.request;
  var url = new URL(request.url);
  if (request.method !== 'GET') return;
  if (url.hostname.includes('supabase.co') ||
      url.hostname.includes('emailjs.com') ||
      url.hostname.includes('api.whatsapp.com')) return;
  if (url.hostname.includes('fonts.googleapis.com') ||
      url.hostname.includes('fonts.gstatic.com') ||
      url.hostname.includes('cdn.jsdelivr.net')) {
    event.respondWith(
      caches.match(request).then(function(cached) {
        if (cached) return cached;
        return fetch(request).then(function(response) {
          if (response && response.status === 200) {
            var clone = response.clone();
            caches.open(CACHE_NAME).then(function(cache) { cache.put(request, clone); });
          }
          return response;
        }).catch(function() { return new Response('', {status: 408}); });
      })
    );
    return;
  }
  event.respondWith(
    caches.match(request).then(function(cached) {
      var networkFetch = fetch(request).then(function(response) {
        if (response && response.status === 200) {
          var clone = response.clone();
          caches.open(CACHE_NAME).then(function(cache) { cache.put(request, clone); });
        }
        return response;
      }).catch(function() { return caches.match(OFFLINE_URL); });
      return cached || networkFetch;
    })
  );
});

self.addEventListener('push', function(event) {
  var data = {};
  if (event.data) {
    try { data = event.data.json(); } catch(e) { data = {title:"Kassan'Mou", body: event.data.text()}; }
  }
  event.waitUntil(
    self.registration.showNotification(data.title || "Kassan'Mou", {
      body: data.body || "Nouvelle activité sur Kassan'Mou",
      icon: '/kassanmou/icon-192.png',
      badge: '/kassanmou/icon-192.png',
      vibrate: [200,100,200],
      data: {url: data.url || '/kassanmou/'}
    })
  );
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  var targetUrl = (event.notification.data && event.notification.data.url) ? event.notification.data.url : '/kassanmou/';
  event.waitUntil(
    clients.matchAll({type:'window', includeUncontrolled:true}).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        if (clientList[i].url === targetUrl && 'focus' in clientList[i]) return clientList[i].focus();
      }
      if (clients.openWindow) return clients.openWindow(targetUrl);
    })
  );
});

console.log("[KM-SW] Kassan'Mou v43 — Service Worker actif");
