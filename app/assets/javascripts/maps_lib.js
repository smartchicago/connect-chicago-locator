/*!
 * Searchable Map Template with Google Fusion Tables
 * http://derekeder.com/searchable_map_template/
 *
 * Copyright 2012, Derek Eder
 * Licensed under the MIT license.
 * https://github.com/derekeder/FusionTable-Map-Template/wiki/License
 *
 * Date: 5/2/2012
 * 
 */

var MapsLib = MapsLib || {};
var MapsLib = {
  
  //Setup - put your Fusion Table details here
  fusionTableId:      4696952,        //the ID of your Fusion Table (found under File => About)
  locationColumn:     "'Full Address'",     //name of the location column in your Fusion Table
  map_centroid:       new google.maps.LatLng(41.8781136, -87.66677856445312), //center that your map defaults to
  locationScope:      "chicago",      //geographical area appended to all address searches
  recordName:         "location",       //for showing number of results
  recordNamePlural:   "locations", 
  
  searchRadius:       805,            //in meters ~ 1/2 mile
  defaultZoom:        11,             //zoom level when map is loaded (bigger is more zoomed in)
  addrMarkerImage: 'http://derekeder.com/images/icons/blue-pushpin.png',
  currentPinpoint: null,
  
  initialize: function() {
    $( "#resultCount" ).html("");
  
    geocoder = new google.maps.Geocoder();
    var myOptions = {
      zoom: MapsLib.defaultZoom,
      center: MapsLib.map_centroid,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map($("#mapCanvas")[0],myOptions);  
    MapsLib.searchrecords = null;
    $("#resultCount").hide();

    //reset filters
    var loadAddress = MapsLib.convertToPlainString($.address.parameter('address'));
    $("#search_address").val(loadAddress);
    var loadRadius = MapsLib.convertToPlainString($.address.parameter('radius'));
    if (loadRadius != "") $("#search_radius").val(loadRadius);
    else $("#search_radius").val(MapsLib.searchRadius);  
    
    if (loadAddress != "")
      MapsLib.doSearch();
    else {
      //default search shows all points on map, but doesn't list results 
      var searchStr = "SELECT " + MapsLib.locationColumn + " FROM " + MapsLib.fusionTableId + " WHERE " + MapsLib.locationColumn + " not equal to ''";
      MapsLib.searchrecords = new google.maps.FusionTablesLayer(MapsLib.fusionTableId, {
        query: searchStr
      });
      MapsLib.searchrecords.setMap(map);
    }
  },
  
  doSearch: function() {
    MapsLib.clearSearch();
    var address = $("#search_address").val();
    MapsLib.searchRadius = $("#search_radius").val();

    var searchStr = "SELECT " + MapsLib.locationColumn + " FROM " + MapsLib.fusionTableId + " WHERE " + MapsLib.locationColumn + " not equal to ''";
    
    //checkbox filters
    if ( $("#filter_internet").is(':checked')) searchStr += " AND Internet = 1";
    if ( $("#filter_training").is(':checked')) searchStr += " AND Training = 1";
    if ( $("#filter_wifi").is(':checked')) searchStr += " AND Wifi = 1";
    
    //location type filter
    if ( $("#filter_type").val() != "") searchStr += " AND OrganizationType = '" + $("#filter_type").val() + "'";
    
    //the geocode function does a callback so we have to handle it in both cases - when they search for and address and when they dont
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
          MapsLib.drawSearchRadiusCircle(MapsLib.currentPinpoint);
          
          searchStr += " AND ST_INTERSECTS(" + MapsLib.locationColumn + ", CIRCLE(LATLNG" + MapsLib.currentPinpoint.toString() + "," + MapsLib.searchRadius + "))";
          
          MapsLib.submitSearch(searchStr, map);
        } 
        else {
          alert("We could not find your address: " + status);
        }
      });
    }
    else { //search without geocoding callback
      MapsLib.submitSearch(searchStr, map);
    }
  },
  
  submitSearch: function(searchStr, map) {
    //get using all filters
    MapsLib.searchrecords = new google.maps.FusionTablesLayer(MapsLib.fusionTableId, {
      query: searchStr
    });
  
    MapsLib.searchrecords.setMap(map);
    MapsLib.getResultsList(searchStr);
    
    //for tablet and phone, scroll to results
    $('html, body').animate({
         scrollTop: $("#resultsList").offset().top
    }, 2000);
  },
  
  getResultsList: function(searchStr) {
    searchStr = searchStr.replace("SELECT " + MapsLib.locationColumn + " ","SELECT Slug, OrganizationName, OrganizationType, Address, Hours ");
    MapsLib.query(searchStr,"MapsLib.renderResultsList");
  },
  
  renderResultsList: function(json) {
    var data = json["table"]["rows"];
    var template = "";
    
    var results = $("#resultsList");
    results.hide().empty(); //hide the existing list and empty it out first
    
    if (data == null) {
      results.append("<li><span class='lead'>No results found</span></li>");
    }
    else {
      for (var row in data) {
        template = "\
          <li>\
            <a href='/location/" + data[row][0] + "'>\
              <span class='lead'>" + data[row][1] + "</span>\
              <br />\
              " + data[row][2] + "\
              <br />\
              " + data[row][3] + "\
              <br />\
              " + data[row][4] + "\
            </a>\
          </li>"
        
        results.append(template);
      }
    }
    
    MapsLib.displaySearchCount(data.length);
    results.fadeIn(); //tada!
  },
  
  clearSearch: function() {
    if (MapsLib.searchrecords != null)
      MapsLib.searchrecords.setMap(null);
    if (MapsLib.addrMarker != null)
      MapsLib.addrMarker.setMap(null);  
    if (MapsLib.searchRadiusCircle != null)
      MapsLib.searchRadiusCircle.setMap(null);
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
          $('#txtSearchAddress').val(results[1].formatted_address);
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
  
  query: function(sql, callback) {
    var sql = encodeURIComponent(sql);
    $.ajax({url: "https://www.google.com/fusiontables/api/query?sql="+sql+"&jsonCallback="+callback, dataType: "jsonp"});
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