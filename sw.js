/* ================================================
   Kassan'Mou — Service Worker PWA v33
   Stratégie : Cache-first pour ressources statiques
   Network-first pour données dynamiques
   Optimisé pour connexions 3G Niger
   ================================================ */

const CACHE_NAME = 'kassanmou-v33-20260418';
const OFFLINE_URL = '/';

/* Ressources à mettre en cache immédiatement à l'installation */
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png'
];

/* Ressources externes à mettre en cache (fonts, libs) */
const EXTERNAL_CACHE = [
  'https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,600;0,700;0,800;1,600&family=Outfit:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap',
  'https://cdn.jsdelivr.net/npm/@emailjs/browser@4/dist/email.min.js'
];

/* ── INSTALLATION : mise en cache des ressources de base ── */
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(PRECACHE_URLS).catch(function(err) {
        console.warn('[KM-SW] Précache partiel:', err);
        return Promise.resolve();
      });
    }).then(function() {
      return self.skipWaiting();
    })
  );
});

/* ── ACTIVATION : nettoyage des anciens caches ── */
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames
          .filter(function(name) { return name !== CACHE_NAME; })
          .map(function(name) { return caches.delete(name); })
      );
    }).then(function() {
      return self.clients.claim();
    })
  );
});

/* ── FETCH : stratégie adaptée au type de ressource ── */
self.addEventListener('fetch', function(event) {
  var request = event.request;
  var url = new URL(request.url);

  /* Ignorer les requêtes non-GET */
  if (request.method !== 'GET') return;

  /* Ignorer les requêtes vers des APIs externes (Supabase, CinetPay, etc.) */
  if (url.hostname.includes('supabase.co') ||
      url.hostname.includes('cinetpay.com') ||
      url.hostname.includes('api.whatsapp.com') ||
      url.hostname.includes('emailjs.com')) {
    return;
  }

  /* Stratégie pour les fonts Google — Cache-first avec fallback réseau */
  if (url.hostname.includes('fonts.googleapis.com') ||
      url.hostname.includes('fonts.gstatic.com')) {
    event.respondWith(
      caches.match(request).then(function(cached) {
        if (cached) return cached;
        return fetch(request).then(function(response) {
          if (response && response.status === 200) {
            var clone = response.clone();
            caches.open(CACHE_NAME).then(function(cache) {
              cache.put(request, clone);
            });
          }
          return response;
        }).catch(function() {
          return new Response('', { status: 408 });
        });
      })
    );
    return;
  }

  /* Stratégie pour les scripts CDN — Cache-first */
  if (url.hostname.includes('cdn.jsdelivr.net')) {
    event.respondWith(
      caches.match(request).then(function(cached) {
        if (cached) return cached;
        return fetch(request).then(function(response) {
          if (response && response.status === 200) {
            var clone = response.clone();
            caches.open(CACHE_NAME).then(function(cache) {
              cache.put(request, clone);
            });
          }
          return response;
        });
      })
    );
    return;
  }

  /* Stratégie principale — Stale-While-Revalidate */
  event.respondWith(
    caches.match(request).then(function(cached) {
      var networkFetch = fetch(request).then(function(response) {
        if (response && response.status === 200) {
          var clone = response.clone();
          caches.open(CACHE_NAME).then(function(cache) {
            cache.put(request, clone);
          });
        }
        return response;
      }).catch(function() {
        return caches.match(OFFLINE_URL);
      });
      return cached || networkFetch;
    })
  );
});

/* ── PUSH NOTIFICATIONS ── */
self.addEventListener('push', function(event) {
  var data = {};
  if (event.data) {
    try { data = event.data.json(); } catch(e) { data = { title: "Kassan'Mou", body: event.data.text() }; }
  }
  var options = {
    body: data.body || "Nouvelle activité sur Kassan'Mou",
    icon: '/icon-192.png',
    badge: '/icon-192.png',
    vibrate: [200, 100, 200],
    data: { url: data.url || '/' },
    actions: data.actions || []
  };
  event.waitUntil(
    self.registration.showNotification(data.title || "Kassan'Mou", options)
  );
});

/* ── CLIC SUR NOTIFICATION ── */
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  var targetUrl = (event.notification.data && event.notification.data.url) ? event.notification.data.url : '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        if (clientList[i].url === targetUrl && 'focus' in clientList[i]) {
          return clientList[i].focus();
        }
      }
      if (clients.openWindow) return clients.openWindow(targetUrl);
    })
  );
});

console.log("[KM-SW] Service Worker Kassan'Mou v33 actif — Cache kassanmou-v33-20260418");
