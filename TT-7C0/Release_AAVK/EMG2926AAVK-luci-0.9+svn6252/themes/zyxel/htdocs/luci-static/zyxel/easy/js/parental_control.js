$(document).ready(
	function () {

	var myindex; 
	var myrowindex=0;
	var checkStatus;

	$(".table tr td").click(function(){
										  
		myindex = $(".table tr td").index(this);
		myrowindex =parseInt(myindex/2);
		
		if ((myindex%2) != 0) {
			checkStatus = $('.table input[@type="checkbox"]:eq('+myrowindex+')').is(':checked');
			if ((checkStatus == true) )
				$('.table input[@type="checkbox"]:eq('+myrowindex+')').attr({checked:false});
			else
			  	$('.table input[@type="checkbox"]:eq('+myrowindex+')').attr({checked:true});
		}
		  					
	});
	
	}
);


