# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
show_message = (result) ->
	eval "var res = " + result
	$("#process_result").html "<p>ERROR: " + res.message + "</p>" 

$(document).on "page:change", -> $("form").on("ajax:success", (e, data, status, xhr) -> $("#process_result").html xhr.responseText).on "ajax:error", (e, xhr, error) -> show_message xhr.responseText
