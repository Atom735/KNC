(function (self: ServiceWorkerGlobalScope) {


  self.addEventListener('install', (event) => {
    console.log('Установлен');
  });

  self.addEventListener('activate', (event) => {
    console.log('Активирован');
  });

  self.addEventListener('fetch', (event) => {
    console.log('Происходит запрос на сервер');
    const url = new URL(event.request.url);
    const path = url.pathname;

    switch (path) {
      case '/signin':
        event.respondWith(fetch(event.request.url.replace('/signin', '/')));
        break;
      default:
        break;
    }
  });


})(self as unknown as ServiceWorkerGlobalScope);
