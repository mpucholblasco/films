$(document).on("ajax:beforeSend", "form[data-turboform]", function(e) {
    Turbolinks.visit(this.action+(this.action.indexOf('?') == -1 ? '?' : '&')+$(this).serialize());
    return false;
});

$(document).on('ready page:load', function(e) {
	var AutofocusInput = $('input[autofocus="autofocus"]');
	var value = AutofocusInput.val();
	AutofocusInput.focus();
	if (value !== undefined) {
		var strLength= AutofocusInput.val().length * 2;
		AutofocusInput[0].setSelectionRange(strLength, strLength);
	}
});
