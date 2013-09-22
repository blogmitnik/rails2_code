var baseIcon = new GIcon();
baseIcon.iconSize = new GSize(32, 32);
baseIcon.shadowSize=new GSize(56,32);
baseIcon.iconAnchor = new GPoint(16, 32);
baseIcon.infoWindowAnchor = new GPoint(16, 0);

//Initialize the map
function initialize_map() {
    if (GBrowserIsCompatible()) {
        map = new GMap2(document.getElementById("map_div"));
        map.setCenter(new GLatLng(14,0), 1);
        map.addControl(new GSmallMapControl());
        map.addControl(new GMapTypeControl());
        map.addControl(new GScaleControl());
        geocoder = new GClientGeocoder();
    }
}

//puts the new markers up
//for more examples http://econym.googlepages.com/example_zindex.htm
function orderOfCreation(marker,b) {
    return 1;
}

// A function to create the marker and set up the event window
function createMarker(point,html,options) {
    var marker = new GMarker(point,options);
    GEvent.addListener(marker, "click", function() {
        marker.openInfoWindowHtml(html);
    });
    return marker;
}

function addAddressToMap(lat,lng,address) {
    point = new GLatLng(lat,lng);
    //TODO: must change the icon picture
    var icon = new GIcon(baseIcon,"http://maps.google.com/mapfiles/kml/pal3/icon56.png",null,"http://maps.google.com/mapfiles/kml/pal3/icon56s.png");
    event = createMarker(point,address,{icon:icon, title:address});
    map.addOverlay(event);
    return event;
}

function geolocateAddress(lat,lng,address) {
    event = addAddressToMap(lat,lng,address);
    map.setCenter(event.getLatLng(),13);
    GEvent.addListener(event, "dragstart", function() {
        map.closeInfoWindow();
    });
    //TODO: the next for when de event is draggable
    GEvent.addListener(event, "dragend", function() {
        event.openInfoWindowHtml(address);
        document.getElementById("event_lat").value = event.getLatLng().lat();
        document.getElementById("event_lng").value = event.getLatLng().lng();
    });
    document.getElementById("event_lat").value = lat;
    document.getElementById("event_lng").value = lng;
    event.openInfoWindowHtml(address);
}