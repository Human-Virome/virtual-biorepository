

$( document ).ready(function() {

  /* Change Page */
  $('nav').on('click', 'a', function (e) {
    
    $('nav a').removeClass('active');
    $(this).addClass('active');
    
    const $target = $('#' + $(this).data('target'));
    
    $target.siblings().removeClass('active');
    $target.addClass('active');
  });

  $('#action_panel').on('click', 'button', function (e) {
    const $target = $('#' + $(this).data('target'));
    $target.trigger('click');
  });

});
