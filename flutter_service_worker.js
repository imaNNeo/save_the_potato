'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/canvaskit.js": "eb8797020acdbdf96a12fb0405582c1b",
"canvaskit/canvaskit.wasm": "73584c1a3367e3eaf757647a8f5c5989",
"canvaskit/chromium/canvaskit.js": "0ae8bbcc58155679458a0f7a00f66873",
"canvaskit/chromium/canvaskit.wasm": "143af6ff368f9cd21c863bfa4274c406",
"canvaskit/skwasm.wasm": "2fc47c0a0c3c7af8542b601634fe9674",
"canvaskit/skwasm.js": "87063acf45c5e1ab9565dcf06b0c18b8",
"main.dart.js": "376b35bb95ca5718f962db41d1a5eea0",
"favicon.png": "9406cc5cd47064643ae26406bee4a440",
"CNAME": "b8545cd1f1ae206ace27abb2c970ddc1",
"flutter.js": "7d69e653079438abfbb24b82a655b0a4",
"index.html": "488ef1ee20029b8e4c969279e92cad70",
"/": "488ef1ee20029b8e4c969279e92cad70",
"version.json": "a7c9590613381b5ed461369c9d68dc3a",
"assets/AssetManifest.bin.json": "1cd00f0961427f93d9797980d6eb41ad",
"assets/packages/iconsax_flutter/fonts/FlutterIconsax.ttf": "83c878235f9c448928034fe5bcba1c8a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "89ed8f4e49bcdfc0b5bfc9b24591e347",
"assets/shaders/ink_sparkle.frag": "4096b5150bac93c41cbc9b45276bd90f",
"assets/fonts/MaterialIcons-Regular.otf": "cc55132c6dce61e1f51ec1a40ddf2ed0",
"assets/AssetManifest.bin": "ad87ed9c9caed067f8cade3fa7b4eb43",
"assets/AssetManifest.json": "39630d15af892b400b1b9811dc9e0832",
"assets/FontManifest.json": "a5722e7790fc0b06f1cc38175f910ea3",
"assets/NOTICES": "c4fa5a27446f9aad785f4a41c9f406d9",
"assets/assets/rive/potato.riv": "f46bab11581595283dd50e6a630a778c",
"assets/assets/audio/victory.mp3": "de7c0cf36488e8bae779a91a49d5d0cd",
"assets/assets/audio/bg.mp3": "a101a778f9bbb441522ff50737ee779a",
"assets/assets/fonts/Cookies.ttf": "791ebca99ad006f8c7e6a427381b3678",
"assets/assets/images/sparkle/sparkle1.png": "b2d3fe2ae39273155ff19893cf3350b9",
"assets/assets/images/sparkle/sparkle2.png": "33e260260efbabc29f2cbcb70d191b75",
"assets/assets/images/trophy/trophy.svg": "326ac0206ac8f2f8663275f89a569f3f",
"assets/assets/images/new-score.png": "c42fed49e081515a9d450b68b59f120d",
"assets/assets/images/snow/snowflake1.png": "db9f269fd553ad02413db096bb99102c",
"assets/assets/images/snow/snowflake2.png": "d4fc3be57ab12ad19f00bdfe0ea971b0",
"assets/assets/images/two-way-arrow.png": "cda099044f7422ee60bceb4f57ace5da",
"assets/assets/images/flutter_flame/flame-logo.png": "d7674a78cbe63a6a7406b30976e6ad88",
"assets/assets/images/heart/heart2.png": "446a20cd7834dd98b1e4c531742ed6a7",
"assets/assets/images/heart/heart1.png": "cb62570b7aba4bb374b37d083288feab",
"assets/assets/images/flame/flame5.png": "0d5915a91b932a46acd9fb71e2fae175",
"assets/assets/images/flame/flame2.png": "d6bbeb0dd20b0f4e0fefb0f72399f4b7",
"assets/assets/images/flame/flame1.png": "fae4afd493612f1bda978ba21a2e3134",
"assets/assets/images/flame/flame6.png": "2abd6022f7b123e4cb19bfd6c7c3ea6a",
"assets/assets/images/flame/flame4.png": "e8db03e2785429e644f4c1b6b306e90b",
"assets/assets/images/flame/flame3.png": "85da33625af52ecd52d7f4ab09dceef3",
"assets/assets/images/flame/flame8.png": "a542592cade71fc9c1344d21d8818029",
"assets/assets/images/flame/flame7.png": "91096abe8027299421615711ee58718c",
"assets/assets/logo/logo-512.png": "edc36b2bac4e755757414e14fdcb4d13",
"icons/Icon-512.png": "39a0e718da0e40d18fa5d0b23cc7ce13",
"icons/Icon-192.png": "61740095958a3091d4f8c8b55aac9428",
"icons/Icon-maskable-512.png": "39a0e718da0e40d18fa5d0b23cc7ce13",
"icons/Icon-maskable-192.png": "61740095958a3091d4f8c8b55aac9428",
"manifest.json": "ebf874e75f18d6049f46ce26cdd87b62"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
