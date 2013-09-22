/*
 * imgPreview jQuery plugin
 * Copyright (c) 2009 James Padolsey
 * j@qd9.co.uk | http://james.padolsey.com
 * Dual licensed under MIT and GPL.
 * Updated: 27/01/09
 * @author James Padolsey
 * @version 0.13
 */
(function($){
    
    $.expr[':'].linkingToImage = function(elem){
        return !! ($(elem).is('a') && elem.href && elem.href.match(/\.(gif|jpe?g|png|bmp)$/i));
    };
    
    $.fn.imgPreview = function(userDefinedSettings){
        
        var s = $.extend({
            imgCSS: {},
            distanceFromCursor: {top:10, left:10},
            preloadImages: true,
            onShow: function(){},
            onHide: function(){},
            onLoad: function(){},
            containerID: 'imgPreviewContainer',
            containerLoadingClass: 'loading',
            thumbPrefix: ''
        }, userDefinedSettings),
        
        $container = $('<div/>').attr('id', s.containerID)
            .append('<img/>').hide().appendTo('body'),
            
        $img = $('img', $container).css(s.imgCSS);
        
        if (s.preloadImages) {
            this.each(function(){
                if ( $(this).is(':linkingToImage') ) {
                    $('<img/>')[0].src = this.href.replace(/\/([^\/]+)$/,'/' + s.thumbPrefix + '$1');
                }
            });
        }
        
        this.filter(':linkingToImage')
            .mousemove(function(e){
                $container.css({
                    top: e.pageY + s.distanceFromCursor.top + 'px',
                    left: e.pageX + s.distanceFromCursor.left + 'px'
                });
            })
            .hover(function(){
                var link = this;
                $container.addClass(s.containerLoadingClass).show();
                $img.load(function(){
                    $container.removeClass(s.containerLoadingClass);
                    s.onLoad.call($img[0], link);
                }).attr('src', link.href.replace(/\/([^\/]+)$/,'/' + s.thumbPrefix + '$1'));
                s.onShow.call($container[0], link);
            }, function(){
                $container.hide();
                $img.unbind('load').attr('src','');
                s.onHide.call($container[0], this);
            });
            
        return this;
        
    }
    
})(jQuery);