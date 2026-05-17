/* Kassan'Mou SW v56b */
var CACHE_NAME = 'kassanmou-v56b';
var OFFLINE_URL = '/kassanmou/';
var PRECACHE_URLS = ['/kassanmou/', '/kassanmou/index.html', '/kassanmou/manifest.json'];

self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_NAME).then(function(c) {
      return c.addAll(PRECACHE_URLS).catch(function() { return Promise.resolve(); });
    }).then(function() { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE_NAME; })
            .map(function(k) { return caches.delete(k); })
      );
    }).then(function() { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function(e) {
  var req = e.request;
  if (req.method !== 'GET') return;
  var url = new URL(req.url);
  if (url.hostname.includes('supabase.co') ||
      url.hostname.includes('emailjs.com') ||
      url.hostname.includes('jsdelivr.net') ||
      url.hostname.includes('fonts.googleapis.com') ||
      url.hostname.includes('fonts.gstatic.com')) return;
  e.respondWith(
    fetch(req).then(function(res) {
      if (res && res.status === 200) {
        var clone = res.clone();
        caches.open(CACHE_NAME).then(function(c) { c.put(req, clone); });
      }
      return res;
    }).catch(function() {
      return caches.match(req).then(function(cached) {
        return cached || caches.match(OFFLINE_URL);
      });
    })
  );
});
console.log("[KM-SW] v56b actif — cache kassanmou-v56b");
