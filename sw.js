/* Kassan'Mou SW v65b — www.kassanmou.net
   ✅ Push Notifications
   ✅ Cache hors-ligne produits
   ✅ Stratégie Network-first avec fallback
*/

var VERSION   = 'v65b';
var CACHE     = 'km-' + VERSION;
var CACHE_API = 'km-api-' + VERSION;   /* Cache produits Supabase */

/* Fichiers précachés au premier chargement */
var PRECACHE = ['/', '/index.html', '/manifest.json', '/sw.js'];

/* ═══ INSTALL ═══ */
self.addEventListener('install', function(e) {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then(function(c) {
      return c.addAll(PRECACHE).catch(function() { return; });
    })
  );
});

/* ═══ ACTIVATE — nettoyer anciens caches ═══ */
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) {
          return k !== CACHE && k !== CACHE_API;
        }).map(function(k) { return caches.delete(k); })
      );
    })
    .then(function() { return self.clients.claim(); })
  );
});

/* ═══ FETCH — Network-first avec fallback cache ═══ */
self.addEventListener('fetch', function(e) {
  if (e.request.method !== 'GET') return;
  var u = new URL(e.request.url);

  /* Appels API Supabase : cache 5 min (produits marketplace) */
  if (u.hostname.includes('supabase.co') && u.pathname.includes('/rest/')) {
    e.respondWith(kmFetchApiWithCache(e.request));
    return;
  }

  /* Ressources externes : laisser passer sans intercepter */
  if (u.hostname.includes('emailjs.com') ||
      u.hostname.includes('jsdelivr.net') ||
      u.hostname.includes('fonts.g') ||
      u.hostname.includes('wa.me') ||
      u.hostname.includes('cinetpay') ||
      u.hostname.includes('anthropic')) return;

  /* Ressources locales : Network-first, fallback cache */
  e.respondWith(
    fetch(e.request.clone()).then(function(r) {
      if (r && r.ok) {
        var rc = r.clone();
        caches.open(CACHE).then(function(ca) { ca.put(e.request, rc); });
      }
      return r;
    }).catch(function() {
      return caches.match(e.request).then(function(cached) {
        if (cached) return cached;
        /* Fallback page hors-ligne */
        if (e.request.mode === 'navigate') return caches.match('/');
        return new Response('', { status: 408 });
      });
    })
  );
});

/* Cache API Supabase (produits) — durée 5 minutes */
function kmFetchApiWithCache(request) {
  var cacheKey = request.url;
  return caches.open(CACHE_API).then(function(cache) {
    return cache.match(cacheKey).then(function(cached) {
      /* Vérifier si le cache est encore frais (5 min) */
      if (cached) {
        var cachedDate = cached.headers.get('sw-cached-at');
        if (cachedDate && (Date.now() - parseInt(cachedDate)) < 5 * 60 * 1000) {
          return cached;
        }
      }
      /* Fetch réseau */
      return fetch(request.clone()).then(function(r) {
        if (r && r.ok) {
          /* Cloner et ajouter header timestamp */
          var headers = new Headers(r.headers);
          headers.append('sw-cached-at', Date.now().toString());
          return r.clone().blob().then(function(body) {
            var cachedResp = new Response(body, {
              status:  r.status,
              headers: headers
            });
            cache.put(cacheKey, cachedResp);
            return r;
          });
        }
        return r;
      }).catch(function() {
        /* Hors-ligne : retourner cache périmé plutôt que rien */
        return cached || new Response(JSON.stringify([]), {
          headers: { 'Content-Type': 'application/json' }
        });
      });
    });
  });
}

/* ═══════════════════════════════════════════════════
   PUSH NOTIFICATIONS
   Reçoit les messages du serveur (Edge Function notifier)
   et affiche la notification système
═══════════════════════════════════════════════════ */
self.addEventListener('push', function(e) {
  var data = {};
  try { data = e.data ? e.data.json() : {}; } catch(err) { data = { title: 'Kassan\'Mou', body: e.data ? e.data.text() : '' }; }

  var title   = data.title || 'Kassan\'Mou';
  var options = {
    body:    data.body    || 'Nouvelle notification',
    icon:    data.icon    || '/icon-192.png',
    badge:   '/favicon-96x96.png',
    tag:     data.tag     || 'km-notif',
    data:    data.url     ? { url: data.url } : {},
    vibrate: [200, 100, 200],
    actions: data.actions || []
  };

  e.waitUntil(self.registration.showNotification(title, options));
});

/* Clic sur la notification → ouvrir la bonne page */
self.addEventListener('notificationclick', function(e) {
  e.notification.close();
  var targetUrl = (e.notification.data && e.notification.data.url)
    ? e.notification.data.url
    : '/';

  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(wins) {
      /* Si une fenêtre Kassan'Mou est déjà ouverte, la focus */
      for (var i = 0; i < wins.length; i++) {
        if (wins[i].url.includes('kassanmou.net') && 'focus' in wins[i]) {
          wins[i].focus();
          wins[i].navigate(targetUrl);
          return;
        }
      }
      /* Sinon ouvrir un nouvel onglet */
      if (clients.openWindow) return clients.openWindow(targetUrl);
    })
  );
});

/* Message depuis l'app (ex: forcer refresh cache) */
self.addEventListener('message', function(e) {
  if (e.data && e.data.type === 'SKIP_WAITING') self.skipWaiting();
  if (e.data && e.data.type === 'CLEAR_API_CACHE') {
    caches.delete(CACHE_API).then(function() {
      e.ports[0] && e.ports[0].postMessage({ cleared: true });
    });
  }
});

console.log('[KM-SW] ' + VERSION + ' actif — www.kassanmou.net | Push ✅ | Cache offline ✅');
