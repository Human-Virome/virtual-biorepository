

$( document ).ready(function() {
  
  
  /* Validate a metadata XLSX file. */
  $('#md_file_input').on('change', function (e) {
    
    $('#md_file_status').html('&nbsp');
    $('#md_file_issues').html('');
    $('#md_file_save').prop('disabled', true);
    
    if ($('#md_file_input')[0].length) {
      
      $('#md_file_status').html('<span aria-busy="true" aria-invalid="false">validating...</span>');
      
      api({
        file     : 'md_file_input',
        payload  : { action: 'metadata_upload', save: false },
        callback : function (resp) {
          if (resp['issues']) {
            $('#md_file_issues').html(resp['issues']);
            $('#md_file_status').html('<i class="fa fa-times-circle" aria-hidden="true"></i> See issues below.');
          } else {
            $('#md_file_save').prop('disabled', false);
            $('#md_file_status').html('<i class="fa fa-check" aria-hidden="true"></i> Passed Validation Checks');
          }
        }
      });
    }
    
  });
  
  
  /* Validate and SAVE a metadata XLSX file. */
  $('#md_file_save').on('click', function (e) {
    
    $('#md_file_status').html('&nbsp');
    $('#md_file_issues').html('');
    $('#md_file_save').prop('disabled', true);
    
    if ($('#md_file_input')[0].length) {
      
      $('#md_file_status').html('<span aria-busy="true" aria-invalid="false">saving...</span>');
      
      api({
        file     : 'md_file_input',
        payload  : { action: 'metadata_upload', save: true },
        callback : function (resp) {
          if (resp['issues']) {
            $('#md_file_save').prop('disabled', false);
            $('#md_file_issues').html(resp['issues']);
            $('#md_file_status').html('<i class="fa fa-times-circle" aria-hidden="true"></i> See issues below.');
          } else {
            $('#md_file_input').val('');
            $('#md_file_status').html('<i class="fa fa-check" aria-hidden="true"></i> Successfully saved');
          }
        }
      });
    }
    
  });

});
