(function() {
  $(document).on("turbolinks:load", function() {
    $("form#start_process").on("ajax:success", function(e, data, status, xhr) {
      $("#loading").hide();
      eval("var res = " + xhr.responseText);
      pollProgressStatus(res.job_url)
    }).on("ajax:error", function(e, xhr, error) {
      $("#loading").hide();
      eval("var res = " + xhr.responseText);
      $('#progresstext').html("Error: " + res.message)
    }).on("ajax:send", function(e, xhr, error) {
      $("#loading").css('display', 'inline-block');
    });

    // Hide loading initially
    $('#loading').hide();
  });
}).call(this);

var pollProgressStatus = function(pollUrl) {
  $(function() {
    $.getJSON(pollUrl, function(response) {
      console.log('poll progress: ' + JSON.stringify(response));
      if (response.progress != 100) {
        setTimeout(function () { pollProgressStatus(pollUrl); }, 1000);
      }
      $('#progressbar').attr('value', response.progress);
      $('#progressnumber').html(response.progress);
      $('#progresstext').html(response.progress_stage);
    });
  });
}
