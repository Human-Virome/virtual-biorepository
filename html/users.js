
$( document ).ready(function() {
  
  const update_user = function (resp) {
    
    if   (resp['auth_token'] === '') localStorage.clear()
    else $.each(resp, (k,v) => localStorage.setItem(k,v));
    
    if (localStorage.getItem('auth_token')) {
      $('#username').text(localStorage.getItem('username'));
      $('body').removeClass('guest');
      $('#email').val('');
      $('#password').val('');
    }
    else {
      $('body').addClass('guest');
      $('#username').text('');
      $('#home_link').trigger('click');
    }
    
  }
  
  update_user({});
  
  
  /* Auto Log In */
  api({
    action   : 'token_login',
    callback : update_user
  });

  
  /* Log In */
  $('#login_btn').on('click', function(e) {

    api({
      action   : 'log_in',
      busy     : $(this),
      callback : update_user,
      payload  : { 
        email    : $('#email').val(),
        password : $('#password').val() }
    });
    
  });
  
  
  /* Log Out */
  $('#log_out_icon').on('click', function(e) {
    api({ action: "log_out" });
    update_user({ auth_token: "" });
  });
  
  
  
  /* My Account */
  $('#my_acct_icon').on('click', function(e) {
    $('#full_name').val(localStorage.getItem('full_name'));
    $('#affiliation').val(localStorage.getItem('affiliation'));
    openModal($('#my_acct_modal')[0]);
  });
  
  $('#my_acct_save').on('click', function(e) {
    api({
      action   : 'my_acct',
      busy     : $(this),
      modal    : $('#my_acct_modal')[0],
      callback : update_user,
      payload  : {
        full_name   : $('#full_name').val(),
        affiliation : $('#affiliation').val()
      }
    });
  });
  
  
  /* Add Users */
  $('#add_users_icon').on('click', function(e) {
    openModal($('#add_users_modal')[0]);
  });
  
  $('#add_users_save').on('click', function(e) {
    api({
      action  : 'add_users',
      busy    : $(this),
      modal   : $('#add_users_modal')[0],
      payload : { emails : $('#emails').val() }
    });
  });
  
  
  /* Register Account */
  $('#register_acct_link').on('click', function(e) {
    display_message(
      'Register Account', 
      'Please ask a current user to create a user account for you.' );
  });
  
  
  /* Forgot Password */
  $('#forgot_pw_link').on('click', function(e) {
    $('#forgot_pw_email').val($('#email').val());
    openModal($('#forgot_pw_modal')[0]);
  });
  
  $('#forgot_pw_send').on('click', function(e) {
    api({
      action  : 'forgot_pw',
      busy    : $(this),
      modal   : $('#forgot_pw_modal')[0],
      payload : { email : $('#forgot_pw_email').val() }
    });
  });
  
  
});
