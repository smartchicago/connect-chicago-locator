// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

//= require jquery.address.min
//= require maps_lib 

$(window).resize(function () {
  var h = $(window).height(),
    offsetTop = 160; // Calculate the top offset

  $('#mapCanvas').css('height', (h - offsetTop));
}).resize();

 $.address.externalChange(function(event) { console.log("external change!"); }); 
 $.address.internalChange(function(event) { console.log("internal change!"); });

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
    console.log('RESET BUTTON');
    $.address.parameter('address','');
    $.address.parameter('radius','');
    // $.address.parameter('internet','');
    // $.address.parameter('training','');
    // $.address.parameter('wifi','');
    MapsLib.initialize(); 
    return false;
  });
  
  $("#search_address").keydown(function(e){
      var key =  e.keyCode ? e.keyCode : e.which;
      if(key == 13) {
          $('#btnSearch').click();
          return false;
      }
  });

  console.log('more stuff');
});