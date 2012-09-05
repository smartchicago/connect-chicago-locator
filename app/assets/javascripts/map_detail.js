var geocoder = new google.maps.Geocoder();
var map = null;
var map_bounds = new google.maps.LatLngBounds();

function initializeMap() {
  var myOptions = {
    zoom: 13,
    center: new google.maps.LatLng(41.37680856570233,-84.287109375),
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    mapTypeControl: false,
    scrollwheel: false,
    draggable: false,
    panControl: true
  };
  map = new google.maps.Map(document.getElementById("mapDetail"), myOptions);
}

function displayPoint(address) {
  geocoder.geocode( { 'address': address}, function(results, status) {
    if (status == google.maps.GeocoderStatus.OK) {
      if (map != null) {
        map.setCenter(results[0].geometry.location);
        var marker = new google.maps.Marker({
          map: map,
          position: results[0].geometry.location,
          icon: "/assets/computers.png"
        });
        map_bounds.extend(results[0].geometry.location);
        map.fitBounds(map_bounds);

        if (map.zoom > 15) {
          map.setZoom(15);
        }
      } else {
        alert("Geocode was not successful for the following reason: " + status);
      }
    }
  });
}