//= require jquery
//= require jquery_ujs
//= require jquery.cookiebar

$(document).ready(function(){

  // alert cookies (bottom)
  // http://www.primebox.co.uk/projects/jquery-cookiebar/
  $.cookieBar({
    message: $('.js-cookie-message').html(),
    acceptText: 'OK'
  });

  // Enable page level ads
  (adsbygoogle = window.adsbygoogle || []).push({
    google_ad_client: "ca-pub-5360961269901609",
    enable_page_level_ads: true
  });

  // Load adsense units after DOM is ready and styles applied
  $('.adsbygoogle').each(function(){
    (adsbygoogle = window.adsbygoogle || []).push({});
  });
});
