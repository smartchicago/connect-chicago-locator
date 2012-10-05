/*!
 * Searchable Map Template with Google Fusion Tables
 * http://derekeder.com/searchable_map_template/
 *
 * Copyright 2012, Derek Eder
 * Licensed under the MIT license.
 * https://github.com/derekeder/FusionTable-Map-Template/wiki/License
 *
 * Date: 8/15/2012
 * 
 */
 
var MapsLib = MapsLib || {};
var MapsLib = {
  
  //Setup section - put your Fusion Table details here
  //Using the v1 Fusion Tables API. See https://developers.google.com/fusiontables/docs/v1/migration_guide for more info
  
  //the encrypted Table ID of your Fusion Table (found under File => About)
  //NOTE: numeric IDs will be depricated soon
  fusionTableId:      "1uM3e-loECodj00NgNC0b1I1nP5zJLL2UkDkn3Fo",  
  
  //*New Fusion Tables Requirement* API key. found at https://code.google.com/apis/console/   
  //*Important* this key is for demonstration purposes. please register your own.   
  googleApiKey:       "AIzaSyDEr3t9l3rUbE69ZB72Lj7hMVx_R_IXKaE",        
  
  //name of the location column in your Fusion Table. 
  //NOTE: if your location column name has spaces in it, surround it with single quotes 
  //example: locationColumn:     "'my location'",
  locationColumn:     "Latitude",  

  map_centroid:       new google.maps.LatLng(41.8781136, -87.66677856445312), //center that your map defaults to
  locationScope:      "chicago",      //geographical area appended to all address searches
  recordName:         "location",       //for showing number of results
  recordNamePlural:   "locations", 
  
  searchRadius:       805,            //in meters ~ 1/2 mile
  defaultZoom:        11,             //zoom level when map is loaded (bigger is more zoomed in)
  addrMarkerImage: '/assets/blue-pushpin.png',
  markerImage: '/assets/connect-chicago-location.png',
  currentPinpoint: null,
  infoWindow: null,
  markers: [],
  
  initialize: function() {
    $( "#resultCount" ).html("");
  
    geocoder = new google.maps.Geocoder();
    var myOptions = {
      zoom: MapsLib.defaultZoom,
      center: MapsLib.map_centroid,
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      styles: MapsLibStyles.styles
    };
    map = new google.maps.Map($("#mapCanvas")[0],myOptions);
    
    MapsLib.searchrecords = null;
    $("#resultCount").hide();
    
    //reset filters
    $(":checkbox").attr("checked", false);

    var loadAddress = MapsLib.convertToPlainString($.address.parameter('address'));
    $("#search_address").val(loadAddress);
    
    var loadRadius = MapsLib.convertToPlainString($.address.parameter('radius'));
    if (loadRadius != "") $("#search_radius").val(loadRadius);
    else $("#search_radius").val(MapsLib.searchRadius);

    if ($.address.parameter('internet') == "1") 
      $("#filter_internet").attr("checked", true);
    else 
      $("#filter_internet").attr("checked", false);

    if ($.address.parameter('training') == "1")
      $("#filter_training").attr("checked", true);
    else 
      $("#filter_training").attr("checked", false);

    if ($.address.parameter('wifi') == "1") 
      $("#filter_wifi").attr("checked", true);
    else 
      $("#filter_wifi").attr("checked", false);

    var filter_type = MapsLib.convertToPlainString($.address.parameter('filter_type'));
    $("#filter_type").val(filter_type);

    if ($.address.parameter('view_mode') != undefined) 
      MapsLib.setResultsView($.address.parameter('view_mode'));
     
    //run the default search
    MapsLib.doSearch();
  },
  
  doSearch: function(location) {
    MapsLib.clearSearch();
    var address = $("#search_address").val();
    MapsLib.searchRadius = $("#search_radius").val();

    var whereClause = MapsLib.locationColumn + " not equal to ''";

    //checkbox filters
    if ( $("#filter_internet").is(':checked')) {
      whereClause += " AND Internet = 1";
      $.address.parameter('internet', "1");
    }
    else $.address.parameter('internet', '');

    if ( $("#filter_training").is(':checked')) {
      whereClause += " AND Training = 1";
      $.address.parameter('training', "1");
    }
    else $.address.parameter('training', '');
    
    if ( $("#filter_wifi").is(':checked')) {
      whereClause += " AND Wifi = 1";
      $.address.parameter('wifi', "1");
    }
    else $.address.parameter('wifi', '');

    //location type filter
    if ( $("#filter_type").val() != "") {
      whereClause += " AND OrganizationType = '" + $("#filter_type").val() + "'";
      $.address.parameter('filter_type', encodeURIComponent($("#filter_type").val()));
    }
    else $.address.parameter('filter_type', '');
    
    if (address != "") {
      if (address.toLowerCase().indexOf(MapsLib.locationScope) == -1)
        address = address + " " + MapsLib.locationScope;
  
      geocoder.geocode( { 'address': address}, function(results, status) {
        if (status == google.maps.GeocoderStatus.OK) {
          MapsLib.currentPinpoint = results[0].geometry.location;
          
          $.address.parameter('address', encodeURIComponent(address));
          $.address.parameter('radius', encodeURIComponent(MapsLib.searchRadius));
          map.setCenter(MapsLib.currentPinpoint);
          map.setZoom(14);
          
          MapsLib.addrMarker = new google.maps.Marker({
            position: MapsLib.currentPinpoint, 
            map: map, 
            icon: MapsLib.addrMarkerImage,
            animation: google.maps.Animation.DROP,
            title:address
          });
          
          whereClause += " AND ST_INTERSECTS(" + MapsLib.locationColumn + ", CIRCLE(LATLNG" + MapsLib.currentPinpoint.toString() + "," + MapsLib.searchRadius + "))";
          
          MapsLib.drawSearchRadiusCircle(MapsLib.currentPinpoint);
          MapsLib.submitSearch(whereClause, map, MapsLib.currentPinpoint);
        } 
        else {
          alert("We could not find your address: " + status);
        }
      });
    }
    else { //search without geocoding callback
      MapsLib.submitSearch(whereClause, map);
    }
  },
  
  submitSearch: function(whereClause, map, location) {
    MapsLib.getResults(whereClause, location);
  },
  
  clearSearch: function() {
    if (MapsLib.searchrecords != null)
      MapsLib.searchrecords.setMap(null);
    if (MapsLib.addrMarker != null)
      MapsLib.addrMarker.setMap(null);  
    if (MapsLib.searchRadiusCircle != null)
      MapsLib.searchRadiusCircle.setMap(null);

    //clear map markers
    if (MapsLib.markers) {
      for (i in MapsLib.markers) {
        MapsLib.markers[i].setMap(null);
      }
      google.maps.event.clearListeners(map, 'click');
      MapsLib.markers = [];
    }
  },

  setResultsView: function(view_mode) {
    var element = $('#view_mode');
    if (view_mode == undefined)
      view_mode = 'map';

    if (view_mode == 'map') {
      $('#listCanvas').hide();
      $('#mapCanvas').show();
      google.maps.event.trigger(map, 'resize');
      map.setCenter(MapsLib.map_centroid);
      MapsLib.doSearch();
      
      element.html('Show list <i class="icon-list icon-white"></i>');
    }
    else {
      $('#listCanvas').show();
      $('#mapCanvas').hide();
      
      element.html('Show map <i class="icon-map-marker icon-white"></i>');

    }
    return false;
  },

  getResults: function(whereClause, location) {
    var selectColumns = "Slug, OrganizationName, OrganizationType, Address, Hours, Latitude, Longitude ";
    MapsLib.query(selectColumns, whereClause, "", "MapsLib.renderResults");
  },
  
  renderResults: function(json) {
    //console.log(MapsLib.markers);
    MapsLib.handleError(json);
    var data = json["rows"];
    var template = "";
    
    var results = $("#resultsList");
    results.hide().empty(); //hide the existing list and empty it out first
    
    if (data == null) {
      //clear results list
      results.append("<li><span class='lead'>No results found</span></li>");
    }
    else {
      for (var row in data) {
        template = "\
          <div class='row-fluid item-list'>\
            <div class='span8'>\
              <a href='/location/" + data[row][0] + "'>\
                <span class='lead'>" + data[row][1] + "</span>\
              </a>\
              <br />\
              " + data[row][2] + "\
              <br />\
              " + data[row][3] + "\
              <br />\
              " + data[row][4] + "\
            </div>\
            <div class='span4 pull-right hidden-phone'>\
              <a href='/location/" + data[row][0] + "'>\
                <img class='img-polaroid' src='/location/" + data[row][0] + "/m/image.jpg' alt='" + data[row][1] + "' title='" + data[row][1] + "'/>\
              </a>\
            </div>\
          </div>"
        
        results.append(template);
        MapsLib.addMarker(data[row]);
      }
    }
    var resultCount = 0;
    if (data != undefined)
      resultCount = data.length;
    MapsLib.displaySearchCount(resultCount);
    results.fadeIn(); //tada!
  },

  addMarker: function(record) {
    var coordinate = new google.maps.LatLng(record[5],record[6])
    var marker = new google.maps.Marker({
      map: map, 
      position: coordinate,
      icon: new google.maps.MarkerImage(MapsLib.markerImage)
    });
    MapsLib.markers.push(marker);

    var content = "\
        <div class='googft-info-window' style='font-family: sans-serif'>\
          <a href='/location/" + record[0] + "'>\
            <span class='lead'>" + record[1] + "</span>\
          </a>\
          <br />\
          " + record[2] + "\
          <br />\
          " + record[3] + "\
          <br />\
          " + record[4] + "\
        </div>";

    //add a click listener to the marker to open an InfoWindow,
    google.maps.event.addListener(marker, 'click', function(event) {
      if(MapsLib.infoWindow) MapsLib.infoWindow.close();

      MapsLib.infoWindow = new google.maps.InfoWindow( {
        position: coordinate,
        content: content
      });
      MapsLib.infoWindow.open(map);
    });

  },

  displaySearchCount: function(numRows) {     
    var name = MapsLib.recordNamePlural;
    if (numRows == 1)
    name = MapsLib.recordName;
    $( "#resultCount" ).fadeOut(function() {
        $( "#resultCount" ).html(MapsLib.addCommas(numRows) + " " + name + " found");
      });
    $( "#resultCount" ).fadeIn();
  },
  
  findMe: function() {
    // Try W3C Geolocation (Preferred)
    var foundLocation;
    
    if(navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(position) {
        foundLocation = new google.maps.LatLng(position.coords.latitude,position.coords.longitude);
        MapsLib.addrFromLatLng(foundLocation);
      }, null);
    }
    else {
      alert("Sorry, we could not find your location.");
    }
  },
  
  addrFromLatLng: function(latLngPoint) {
    geocoder.geocode({'latLng': latLngPoint}, function(results, status) {
      if (status == google.maps.GeocoderStatus.OK) {
        if (results[1]) {
          $('#search_address').val(results[1].formatted_address);
          $('.hint').focus();
          MapsLib.doSearch();
        }
      } else {
        alert("Geocoder failed due to: " + status);
      }
    });
  },
  
  drawSearchRadiusCircle: function(point) {
      var circleOptions = {
        strokeColor: "#4b58a6",
        strokeOpacity: 0.3,
        strokeWeight: 1,
        fillColor: "#4b58a6",
        fillOpacity: 0.05,
        map: map,
        center: point,
        clickable: false,
        zIndex: -1,
        radius: parseInt(MapsLib.searchRadius)
      };
      MapsLib.searchRadiusCircle = new google.maps.Circle(circleOptions);
  },
  
  query: function(selectColumns, whereClause, orderBy, callback) {
    var queryStr = [];
    queryStr.push("SELECT " + selectColumns);
    queryStr.push(" FROM " + MapsLib.fusionTableId);
    
    if (whereClause != "")
      queryStr.push(" WHERE " + whereClause);

    if (orderBy != "")
      queryStr.push(" ORDER BY " + orderBy);
  
    var sql = encodeURIComponent(queryStr.join(" "));
    $.ajax({
      url: "https://www.googleapis.com/fusiontables/v1/query?sql="+sql+"&callback="+callback+"&key="+MapsLib.googleApiKey, 
      dataType: "jsonp"
    });
  },

  handleError: function(json) {
    if (json["error"] != undefined)
      console.log("Error in Fusion Table call: " + json["error"]["message"]);
  },
  
  addCommas: function(nStr) {
    nStr += '';
    x = nStr.split('.');
    x1 = x[0];
    x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
      x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
  },
  
  //converts a slug or query string in to readable text
  convertToPlainString: function(text) {
    if (text == undefined) return '';
    return decodeURIComponent(text);
  }
}