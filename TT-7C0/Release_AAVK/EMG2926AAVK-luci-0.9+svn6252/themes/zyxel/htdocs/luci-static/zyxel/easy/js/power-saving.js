$(document).ready(
	function () {

	var myindex; 

	$("#schedule li").click(function(){
		myindex = $("#schedule li").index(this);
		
		if ($('#schedule li:eq('+myindex+')').is(".sleep"))
			$('#schedule li:eq('+myindex+')').addClass('up').removeClass("sleep");
		else			
			$('#schedule li:eq('+myindex+')').addClass('sleep').removeClass("up");
		
	});


	
	}
);


