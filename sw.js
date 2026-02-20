const CACHE_NAME="wifi-key-pro-v2";

const urlsToCache=[
"/",
"/index.html",
"/manifest.json",
"/icon.png"
];

self.addEventListener("install",event=>{
event.waitUntil(
caches.open(CACHE_NAME)
.then(cache=>cache.addAll(urlsToCache))
);
});

self.addEventListener("fetch",event=>{
event.respondWith(
caches.match(event.request)
.then(response=>response||fetch(event.request))
);
});

self.addEventListener("activate",event=>{
event.waitUntil(
caches.keys().then(names=>{
return Promise.all(
names.map(name=>{
if(name!==CACHE_NAME) return caches.delete(name);
})
);
})
);
});