

$( document ).ready(function() {

  const $html = $('html');
  $html.attr('data-theme', window?.matchMedia?.('(prefers-color-scheme:dark)')?.matches ? 'dark' : 'light');
  
  
  /* Switch Dark/Light Theme */
  $('#theme_btn').on('click', function(e) {
    if ($html.attr('data-theme') === 'dark') {
      $html.attr('data-theme', 'light');
    } else {
      $html.attr('data-theme', 'dark');
    }
  });

});
