var MapsDetailLib = MapsDetailLib || {};
var MapsDetailLib = {

  geocoder: new google.maps.Geocoder(),
  map: null,
  map_bounds: new google.maps.LatLngBounds(),

  initializeMap: function() {
    var myOptions = {
      zoom: 13,
      center: new google.maps.LatLng(41.37680856570233,-84.287109375),
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      mapTypeControl: false,
      scrollwheel: false,
      draggable: false,
      panControl: true,
      styles: MapsLibStyles.styles
    };
    MapsDetailLib.map = new google.maps.Map(document.getElementById("mapDetail"), myOptions);
  },

  displayPoint: function(address) {
    MapsDetailLib.geocoder.geocode( { 'address': address}, function(results, status) {
      if (status == google.maps.GeocoderStatus.OK) {
        if (MapsDetailLib.map != null) {
          MapsDetailLib.map.setCenter(results[0].geometry.location);
          var marker = new google.maps.Marker({
            map: MapsDetailLib.map,
            position: results[0].geometry.location,
            icon: "/assets/connect-chicago-location-white.png"
          });
          MapsDetailLib.map_bounds.extend(results[0].geometry.location);
          MapsDetailLib.map.fitBounds(MapsDetailLib.map_bounds);

          if (MapsDetailLib.map.zoom > 15) {
            MapsDetailLib.map.setZoom(15);
          }
        } else {
          alert("Geocode was not successful for the following reason: " + status);
        }
      }
    });
  }
}