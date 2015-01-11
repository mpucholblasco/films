(function() {
  $(document).on("page:change", function() {
    $("form#start_process").on("ajax:success", function(e, data, status, xhr) {
      $("#loading").hide();
      eval("var res = " + xhr.responseText);
      $("#process_result").html("<p>" + I18n.t('update_content_finish', { deleted: res.deleted, added: res.added }) + "</p>");
    }).on("ajax:error", function(e, xhr, error) {
      $("#loading").hide();
      eval("var res = " + xhr.responseText);
      $("#process_result").html("<p>" + I18n.t('update_content_error', { message: res.message}) + "</p>");
    }).on("ajax:send", function(e, xhr, error) {
      $("#loading").css('display', 'inline-block');
      $("#process_result").html("");
    });

    // Hide loading initially
    $('#loading').hide();
  });
}).call(this);
