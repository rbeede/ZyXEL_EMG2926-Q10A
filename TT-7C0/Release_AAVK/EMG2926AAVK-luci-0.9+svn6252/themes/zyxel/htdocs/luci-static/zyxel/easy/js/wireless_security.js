$(document).ready(
	function () {

	//content slide
	$("#b_wps").click(function(){
    	$(".widearea2").animate({
        marginLeft: "-601px"
        }, 300);
	});
		
    $("#b_ws").click(function() {
        $(".widearea2").animate({
        marginLeft: "0px"
        }, 300);
    });
	
	$('#btnwps input:eq(0)').click(function (e) {
		e.preventDefault();

		// example of calling the confirm function
		// you must use a callback function to perform the "yes" action
		confirm("Device Connected Successful.", function () {
			window.location.href = '';
		});
	});
	
	$('#btnregister input:eq(0)').click(function (e) {
		e.preventDefault();

		// example of calling the confirm function
		// you must use a callback function to perform the "yes" action
		confirm("Device Registerd Successful..", function () {
			window.location.href = '';
		});
	});
	
	}
);


function confirm(message, callback) {
	$('#confirm').modal({
		close:false, 
		overlayId:'confirmModalOverlay',
		containerId:'confirmModalContainer', 
		onShow: function (dialog) {
			dialog.data.find('.message').append(message);

			// if the user clicks "yes"
			dialog.data.find('.yes').click(function () {
				// call the callback
				if ($.isFunction(callback)) {
					callback.apply();
				}
				// close the dialog
				$.modal.close();
			});
		}
	});
}