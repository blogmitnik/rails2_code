 function permission_granted() {  
  $('fb_publish').childElements().each(function(item){   
    item.remove();
  });
  new Ajax.Request('/users/status_updates/fbpublish', {method: 'get'})
}

function populate_date(month, day, year) {
  ge('date_month').value = month;
  ge('date_day').value = day;
  ge('date_year').value = year;
}

function ge(elem) {
  return document.getElementById(elem);
}

/*
 * Ensure Facebook app is initialized and call callback afterward
 *
 */
function ensure_init(callback) {
  if(!window.api_key) {
    window.alert("api_key is not set");
  }

  if(window.is_initialized) {
    callback();
  } else {
    FB_RequireFeatures(["XFBML", "CanvasUtil"], function() {
        FB.FBDebug.logLevel = 4;
        FB.FBDebug.isEnabled = true;
        // xd_receiver.php is a relative path here, because The Run Around
        // could be installed in a subdirectory
        // you should prefer an absolute URL (like "/xd_receiver.php") for more accuracy
        FB.Facebook.init(window.api_key, window.xd_receiver_location);

        window.is_initialized = true;
        callback();
      });
  }
}

/*
 * "Session Ready" handler. This is called when the facebook
 * session becomes ready after the user clicks the "Facebook login" button.
 * In a more complex app, this could be used to do some in-page
 * replacements and avoid a full page refresh. For now, just
 * notify the server the user is logged in, and redirect to home.
 *
 * @param link_to_current_user  if the facebook session should be
 *                              linked to a currently logged in user, or used
 *                              to create a new account anyway
 */
function facebook_button_onclick() {

  ensure_init(function() {
      FB.Facebook.get_sessionState().waitUntilReady(function() {
          var user = FB.Facebook.apiClient.get_session() ?
            FB.Facebook.apiClient.get_session().uid :
            null;

          // probably should give some indication of failure to the user
          if (!user) {
            return;
          }

          // The Facebook Session has been set in the cookies,
          // which will be picked up by the server on the next page load
          // so refresh the page, and let all the account linking be
          // handled on the server side

          // This could be done a myriad of ways; for a page with more content,
          // you could do an ajax call for the account linking, and then
          // just replace content inline without a full page refresh.
          //refresh_page();
          window.location = window.facebook_authenticate_location;
        });
    });
}

/*
 * Do a page refresh after login state changes.
 * This is the easiest but not the only way to pick up changes.
 * If you have a small amount of Facebook-specific content on a large page,
 * then you could change it in Javascript without refresh.
 */
function refresh_page() {
  window.location = '/';
}

function logout() {
  window.location = '/logout';
}

/*
 * Show the feed form. This would be typically called in response to the
 * onclick handler of a "Publish" button, or in the onload event after
 * the user submits a form with info that should be published.
 *
 */
function facebook_publish_feed_story(form_bundle_id, template_data) {
  // Load the feed form
  FB.ensureInit(function() {
          FB.Connect.showFeedDialog(form_bundle_id, template_data);
          //FB.Connect.showFeedDialog(form_bundle_id, template_data, null, null, FB.FeedStorySize.shortStory, FB.RequireConnect.promptConnect);

      // hide the "Loading feed story ..." div
      // ge('feed_loading').style.visibility = "hidden";
  });
}

// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
  // sets up the hover image for activity feed items  
  $(".imgHoverMarker").tooltip({
  showURL: false,
  bodyHandler: function() {
    var i = $(this).children()[0]
    var imgsrc = $(i).attr('src');
    return $('<img src="'+imgsrc+'" />');
  }
  });

  $('input,textarea').focus( function() {
  $(this).css('border-color', '#006699');
  });
  $('input,textarea').blur( function() {
  $(this).css('border-color','#ccc');
  });

  // facebox popups
  jQuery('a[rel*=facebox]').facebox();

});


function updateLocation(point) {
	document.getElementById('photo_geo_lat').value = point.y; 
	document.getElementById('photo_geo_long').value = point.x;
	map.clearOverlays();
	map.addOverlay(new GMarker(new GLatLng(point.y, point.x)));
}

function updateLocation1(point) {
	document.getElementById('entry_geo_lat').value = point.y; 
	document.getElementById('entry_geo_long').value = point.x;
	map.clearOverlays();
	map.addOverlay(new GMarker(new GLatLng(point.y, point.x)));
}


var SLIDE_SPEED = 500

//jQuery.noConflict();

jQuery(document).ajaxSend(function(event, request, settings) {
  if (typeof(AUTH_TOKEN) == "undefined") return;
  settings.data = settings.data || "";
  settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(AUTH_TOKEN);
});


jQuery.jGrowl.info = function(msg){
	jQuery.jGrowl(msg, {position: 'center'}, "Information!", "#BBF66F", "#000");
}

jQuery.jGrowl.warn = function(msg){
	jQuery.jGrowl(msg, {position: 'center'}, "Warning!", "#F6BD6F", "#000");	
}

jQuery.jGrowl.error = function(msg){
	jQuery.jGrowl(msg, {position: 'center'}, "Critical!", "#F66F82", "#000");	
}

function jeval(str){return eval('(' +  str + ');'); }

function tog(clicker, toggler, callback, speed){
  if (speed == undefined)
    speed = SLIDE_SPEED;
  if (callback)
    jQuery(clicker).click(function(){jQuery(toggler).slideToggle(speed, callback); return false;});
  else
    jQuery(clicker).click(function(){jQuery(toggler).slideToggle(speed); return false;});
}
function togger(j, callback, speed){
  if (speed == undefined)
    speed = SLIDE_SPEED;
  if(callback)
  jQuery(j).slideToggle(speed, callback); 
  else 
  jQuery(j).slideToggle(speed); 
}

function async_message(m, d){message(m, d);}
function messages(m, d){message(m, d);}
function message(message, duration){
    if (duration == undefined){
        duration = 3000;
    }
    if (jQuery.browser.msie) { jQuery("#message").css({position: 'absolute'}); }
    jQuery("#message").text(message).fadeIn(1000);
    setTimeout('jQuery("#message").fadeOut(2000)',duration);
    return false;
}

function debug(m){if (typeof console != 'undefined'){console.log(m);}}
function puts(m){debug(m);}

function thickbox(id, title, height, width){
    if (height == undefined){ height = 300}
    if (width == undefined){ width = 300}
    tb_show(title, '#TB_inline?height='+ height +'&amp;width='+ width +'&amp;inlineId='+ id +'', false);
    return false;
}

function tog_login_element() {
	jQuery('.login_element, .checkout_element').toggle();
}

function toggleComments(comment_id)
{
	jQuery('#comment_'+comment_id+'_short, #comment_'+comment_id+'_complete').toggleClass('hidden');
  
	jQuery('#comment_'+comment_id+'_toggle_link').html(
    	jQuery('#comment_'+comment_id+'_toggle_link').html() == "(more)" ? "(less)" : "(more)"
	); 
}

jQuery(document).ready(function() {
	
	jQuery('#search_q').bind('focus.search_query_field', function(){
		if(jQuery(this).val()=='Search for Friends'){
			jQuery(this).val('');
		}
	});
	
	jQuery('#search_q').bind('blur.search_query_field', function(){
		if(jQuery(this).val()==''){
			jQuery(this).val('Search for Friends');
		}
	});
	
	jQuery(".tip-field").focus(function() {
		jQuery(".active").removeClass("active");
		jQuery(".hidden-tips").css("display", "none");
		jQuery("#" + this.id + "-help").show();
		jQuery("#" + this.id + "-container").addClass("active");
	});
	
	jQuery(".hidden-tips").css("display", "none");

	jQuery(".required-value").blur(function() {
		if (jQuery(this).val().length == 0) {
			jQuery('#' + this.id + '_required').show();
		} else {
			jQuery('#' + this.id + '_required').hide();
			jQuery("#" + this.id + "-container").children().removeClass("fieldWithErrors");
			jQuery('#' + this.id + '-label-required').hide();
		}
	});

	jQuery(".submit-delete").click(function() {
		jQuery(this).parents('.delete-container:first').fadeOut();
		var form = jQuery(this).parents('form');
		jQuery.post(form.attr('action') + '.js', form.serialize(),
		  function(data){
				jQuery.jGrowl.info(data);
		  });			
		return false;
	});	
  
});

