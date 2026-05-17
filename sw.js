/* Kassan'Mou SW v57 */
var CACHE_NAME = 'kassanmou-v57';
var PRECACHE = ['/kassanmou/', '/kassanmou/index.html', '/kassanmou/manifest.json'];

self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(c){ return c.addAll(PRECACHE).catch(function(){return Promise.resolve();}); })
      .then(function(){ return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys){
      return Promise.all(keys.filter(function(k){return k!==CACHE_NAME;}).map(function(k){return caches.delete(k);}));
    }).then(function(){ return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function(e) {
  if(e.request.method!=='GET') return;
  var u=new URL(e.request.url);
  if(u.hostname.includes('supabase.co')||u.hostname.includes('emailjs.com')||
     u.hostname.includes('jsdelivr.net')||u.hostname.includes('fonts.g')) return;
  e.respondWith(
    fetch(e.request).then(function(r){
      if(r&&r.status===200){var c=r.clone();caches.open(CACHE_NAME).then(function(ca){ca.put(e.request,c);});}
      return r;
    }).catch(function(){
      return caches.match(e.request).then(function(c){return c||caches.match('/kassanmou/');});
    })
  );
});
console.log('[KM-SW] v57 actif');
