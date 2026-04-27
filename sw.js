var CACHE_NAME = "kassanmou-v42";
var ASSETS = ["./kassanmou-v42.html", "./manifest.json"];

self.addEventListener("install", function(e) {
  e.waitUntil(caches.open(CACHE_NAME).then(function(c) { return c.addAll(ASSETS); }));
  self.skipWaiting();
});

self.addEventListener("activate", function(e) {
  e.waitUntil(caches.keys().then(function(keys) {
    return Promise.all(keys.filter(function(k) { return k !== CACHE_NAME; }).map(function(k) { return caches.delete(k); }));
  }));
  self.clients.claim();
});

self.addEventListener("fetch", function(e) {
  if (e.request.url.includes("supabase.co") || e.request.url.includes("emailjs.com") || e.request.url.includes("jsdelivr.net")) return;
  e.respondWith(caches.match(e.request).then(function(cached) {
    return cached || fetch(e.request).catch(function() { return caches.match("./kassanmou-v42.html"); });
  }));
});
