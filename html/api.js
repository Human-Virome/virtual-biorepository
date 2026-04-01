

//___________________________________________________________________
// Automatically handle common responses.
//___________________________________________________________________
$( document ).ajaxSuccess(function(event, jqXHR, params, resp) {
  if (resp['message']) display_message('success', resp['message']);
  if (resp['error'])   display_message('error',   resp['error']);
});

$( document ).ajaxError(function(event, jqXHR, params, thrownError) {
  display_message('error', jqXHR.responseText);
});


//___________________________________________________________________
// AJAX wrapper for communicating with backend
//___________________________________________________________________
function api (args) {
  
  
  //-------------------------------------------------------
  // Add a spinner to a button until xhr returns.
  //-------------------------------------------------------
  if (args['busy']) { args['busy'].attr('aria-busy', 'true'); }
  
  
  //-------------------------------------------------------
  // Configure the payload.
  //-------------------------------------------------------
  const payload = args['payload'] || {};
  payload['auth_token'] = localStorage.getItem('auth_token');

  if (args['file']) {
    
    const id        = args['file'];
    const form_data = new FormData();
    form_data.append(id, $('#' + id)[0].files[0]);
    
    $.each(payload, function (key, value) {
      form_data.append(key, value);
    });
    
    xhr = $.ajax({
      url         : 'api',
      type        : 'POST',
      data        : form_data,
      contentType : false,
      processData : false
    });
    
  } else {
    xhr = $.post('api', payload);
  }
  
  
  //-------------------------------------------------------
  // What to do after the xhr completes.
  //-------------------------------------------------------
  if (args['busy'])     { xhr.always(()   => { args['busy'].attr('aria-busy', 'false')    }); }
  if (args['modal'])    { xhr.always(()   => { closeModal(args['modal']);                 }); }
  if (args['callback']) { xhr.done((resp) => { if (!resp['error']) args['callback'](resp) }); }
  
  return xhr;
}
