
      // == Some global variables ==
      var YSLIDERLENGTH = 55;       // maximum length that the knob can move (slide height minus knob height)
      var MAXZOOM = 17;
	  
	  var YSLIDE = '/images/customslider/yslide.png';
	  var YKNOB = '/images/customslider/yknob.png';

      // == Create a Custom GControl ==
      function YSliderControl() { }
      YSliderControl.prototype = new GControl();

      // == This function positions the slider to match the specified zoom level ==
      YSliderControl.prototype.setSlider = function(zoom) {
        var top = Math.round((YSLIDERLENGTH/MAXZOOM*zoom));
        this.slide.top = top;
        this.knob.style.top = top+"px";
        //GLog.write("Map was zoomed to:"+zoom+" new Knob position:"+top);
      }

      // == This function reads the slider and sets the zoom level ==
      YSliderControl.prototype.setZoom = function() {
        var z=Math.round(this.slide.top*MAXZOOM/YSLIDERLENGTH);
        this.map.setZoom(z);
        //GLog.write("New knob position:"+this.slide.top+" new zoom: "+z);
      }


      // == This gets called bu the API when addControl(new YSlider()) is used ==
      YSliderControl.prototype.initialize = function(map) {
        // obtain Function Closure on a reference to "this"
        var that=this;
        // store a reference to the map so that we can call setZoom() on it
        this.map = map;

        // Is this MSIE, if so we need to use AlphaImageLoader
        var agent = navigator.userAgent.toLowerCase();
        if ((agent.indexOf("msie") > -1) && (agent.indexOf("opera") < 1)){this.ie = true} else {this.ie = false}

        // create the background graphic as a <div> containing an image
        var container = document.createElement("div");
        container.style.width="19px";
        container.style.height="74px";

        // Handle transparent PNG files in MSIE
        if (this.ie) {
          var loader = "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src=" + YSLIDE + ", sizingMethod='scale');";
          container.innerHTML = '<div style="height:74px; width:19px; ' +loader+ '" ></div>';
        } else {
          container.innerHTML = '<img src="' + YSLIDE + '"  width=19 height=74 >';
        }

        // create the knob as a GDraggableObject
        // Handle transparent PNG files in MSIE
        if (this.ie) {
          var loader = "progid:DXImageTransform.Microsoft.AlphaImageLoader(src='"+ YKNOB + "', sizingMethod='scale');";
          this.knob = document.createElement("div"); 
          this.knob.style.height="19px";
          this.knob.style.width="19px";
          this.knob.style.filter=loader;
        } else {
          this.knob = document.createElement("img"); 
          this.knob.src = YKNOB;
          this.knob.height = "19";
          this.knob.width = "19";
        }
        container.appendChild(this.knob);
        this.slide=new GDraggableObject(this.knob, {container:container});

        // attach the control to the map
        map.getContainer().appendChild(container);

        // Listen for other things changing the zoom level and move the slider
        GEvent.addListener(map, "zoomend", function(a,b) {that.setSlider(b)});

        // Listen for the slider being moved and set the zoom level
        GEvent.addListener(this.slide, "dragend", function() {that.setZoom()});

        return container;
      }

      // == Set the default position for the control ==
      YSliderControl.prototype.getDefaultPosition = function() {
        return new GControlPosition(G_ANCHOR_TOP_LEFT, new GSize(7, 7));
      }
