function ofc_get_data( id )
{
    return JSON.stringify(eval('data_'+id));
}

function findSWF(movieName) {
  if (navigator.appName.indexOf("Microsoft")!= -1) {
    return window[movieName];
  } else {
    return document[movieName];
  }
}

OFC = {};
 
OFC.jquery = {
    name: "jQuery",
    version: function(src) { return $('#'+ src)[0].get_version() },
    rasterize: function (src, dst) { $('#'+ dst).replaceWith(OFC.jquery.image(src)) },
    image: function(src) { return "<img src='data:image/png;base64," + $('#'+src)[0].get_img_binary() + "' />"},
    popup: function(src) {
        var img_win = window.open('', 'Charts: Export as Image')
        with(img_win.document) {
            write('<html><head><title>Charts: Export as Image<\/title><\/head><body>' + OFC.jquery.image(src) + '<\/body><\/html>') }
    // stop the 'loading...' message
    img_win.document.close();
     }
}
 
// Using an object as namespaces is JS Best Practice. I like the Control.XXX style.
//if (!Control) {var Control = {}}
//if (typeof(Control == "undefined")) {var Control = {}}
if (typeof(Control == "undefined")) {var Control = {OFC: OFC.jquery}}

function imprimir_reporte() {
  $("[id^=chart]").each( function() {
    OFC.jquery.rasterize( $(this).attr("id"), 'imagen_'+ $(this).attr("id") );
    $(this).hide();
  });

  window.print();
  window.setTimeout( "window.location.reload()", 3000);

}