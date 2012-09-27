// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

//= require jquery.address.min
//= require maps_lib 

$(window).resize(function () {
  var h = $(window).height(),
    offsetTop = 160; // Calculate the top offset

  $('#mapCanvas').css('height', (h - offsetTop));
}).resize();

$(function() {
  MapsLib.initialize();

  $(':checkbox').click(function(){
    MapsLib.doSearch();
  });
  
  $('#filter_type').change(function(){
    MapsLib.doSearch();
  });
  
  $('#btnSearch').click(function(){
    MapsLib.doSearch();
  });
  
  $('#findMe').click(function(){
    MapsLib.findMe(); 
    return false;
  });
  
  $('#reset').click(function(){
    $.address.parameter('address','');
    $.address.parameter('radius','');
    $.address.parameter('internet','');
    $.address.parameter('training','');
    $.address.parameter('wifi','');
    $.address.parameter('filter_type','');
    MapsLib.initialize(); 
    return false;
  });

  $('#view_mode').click(function(){
    var element = $('#view_mode');
    if (element.attr('data-mode') == 'list') {
      $('#listCanvas').hide();
      $('#mapCanvas').show();
      google.maps.event.trigger(map, 'resize');
      map.setCenter(MapsLib.map_centroid);
      MapsLib.doSearch();
      
      element.html('Show list');
      element.attr('data-mode', 'map');
    }
    else {
      $('#listCanvas').show();
      $('#mapCanvas').hide();
      
      element.html('Show map');
      element.attr('data-mode', 'list');
    }
    return false;
  });
  
  $("#search_address").keydown(function(e){
      var key =  e.keyCode ? e.keyCode : e.which;
      if(key == 13) {
          $('#btnSearch').click();
          return false;
      }
  });
});