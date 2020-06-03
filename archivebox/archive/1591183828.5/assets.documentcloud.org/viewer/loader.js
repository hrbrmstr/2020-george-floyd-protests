
(function() {
  var DV = window.DV = window.DV || {};
  DV.documentQueue   = DV.documentQueue || [];
  DV.recordHit       = "//www.documentcloud.org/pixel.gif";
  DV.load            = function(url, options) {
    var insertStylesheet = function(href, media) {
      if (!document.querySelector('link[href$="' + href + '"]')) {
        media = media || 'screen';
        var stylesheet       = document.createElement('link');
            stylesheet.rel   = 'stylesheet';
            stylesheet.type  = 'text/css';
            stylesheet.media = media;
            stylesheet.href  = href;
        document.getElementsByTagName('head')[0].appendChild(stylesheet);
      }
    };
    var insertJavaScript = function(src, onLoadCallback) {
      var script = document.querySelector('script[src$="' + src + '"]');
      if (!script) {
        script       = document.createElement('script');
        script.src   = src;
        script.async = true;
        document.getElementsByTagName('head')[0].appendChild(script);
      }
      if (script.addEventListener && !script.getAttribute('data-listening')) {
        script.setAttribute('data-listening', true);
        script.addEventListener('load', onLoadCallback);
      }
    };
    var loadQueuedDocuments = function() {
      var loadDocument = DV.immediatelyLoadDocument || (DV.viewers && DV.load ? DV.load : false);
      if (loadDocument) {
        var q = DV.documentQueue;
        for (var i = 0, qLength = q.length; i < qLength; i++) {
          loadDocument(q[i].url, q[i].options);
        }
        DV.documentQueue = [];
      } else if (window.console) {
        console.error("DocumentCloud embed can't load because of missing components.");
      }
    };
    insertStylesheet('//assets.documentcloud.org/viewer/viewer-datauri.css');
    insertStylesheet('//assets.documentcloud.org/viewer/printviewer.css', 'print');
    if (DV.immediatelyLoadDocument) {
      DV.immediatelyLoadDocument(url, options);
    } else {
      DV.documentQueue.push({url: url, options: options});
      insertJavaScript('//assets.documentcloud.org/viewer/viewer.js', loadQueuedDocuments);
    }
  }
})();
