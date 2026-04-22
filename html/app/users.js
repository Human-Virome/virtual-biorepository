
$( document ).ready(function() {
  
  api({
    action   : 'whoami',
    callback : function (resp) {
      $('#oauth_email').val(resp['oauth_email']);
    }
  });

});
