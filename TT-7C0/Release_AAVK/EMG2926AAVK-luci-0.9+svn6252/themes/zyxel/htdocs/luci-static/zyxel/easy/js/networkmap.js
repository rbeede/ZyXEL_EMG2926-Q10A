$(document).ready(
	function () {
	
	$(window).scroll(resscrEvt);
	$(window).resize(resscrEvt);		
	
	$(".on_off ul li:first").click(function(){
		alert("john 8");
		if (!easy_job_setting)
		{ 
			alert("john 11"); 
		$(this).addClass("on_on").removeClass("on");
		$(".on_off li:last").addClass("off").removeClass("off_on");
		$(".on_off4 li:first").addClass("on_on").removeClass("on");
		$(".on_off4 li:last").addClass("off").removeClass("off_on");
		easy_set.easy_set_option(1,1);
		}
	});

	$(".on_off li:last").click(function(){
		alert("john 21");
		//if (!easy_job_setting)
		{  
			alert("john 24"); 
		$(this).addClass("off_on").removeClass("off");
		$(".on_off li:first").addClass("on").removeClass("on_on");
		easy_set_info.easy_set_option(1,0);
		}
	});
	
	$(".on_off2 li:first").click(function(){
		//if (!easy_job_setting)
		{  
		$(this).addClass("on_on").removeClass("on");
		$(".on_off2 li:last").addClass("off").removeClass("off_on");
		easy_set.easy_set_option(2,1);
		}
	});

	$(".on_off2 li:last").click(function(){
		//if (!easy_job_setting)
		{  
		$(this).addClass("off_on").removeClass("off");
		$(".on_off2 li:first").addClass("on").removeClass("on_on");
		easy_set.easy_set_option(2,0);
		}
	});
	
	$(".on_off3 li:first").click(function(){
		//if (!easy_job_setting)
		{  
		$(this).addClass("on_on").removeClass("on");
		$(".on_off3 li:last").addClass("off").removeClass("off_on");
		easy_set.easy_set_option(3,1);
		}
	});

	$(".on_off3 li:last").click(function(){
		//if (!easy_job_setting)
		{  
		$(this).addClass("off_on").removeClass("off");
		$(".on_off3 li:first").addClass("on").removeClass("on_on");
		easy_set.easy_set_option(3,0);
		}
	});

	$(".on_off4 li:first").click(function(){
		//if (!easy_job_setting)
		{  
		$(this).addClass("on_on").removeClass("on");
		$(".on_off4 li:last").addClass("off").removeClass("off_on");
		easy_set.easy_set_option(4,1);
		}
	});

	$(".on_off4 li:last").click(function(){
		//if (!easy_job_setting)
		{  
		$(this).addClass("off_on").removeClass("off");
		$(".on_off4 li:first").addClass("on").removeClass("on_on");
		$(".on_off li:last").addClass("off_on").removeClass("off");
		$(".on_off li:first").addClass("on").removeClass("on_on");
		easy_set.easy_set_option(4,0);
	});
	
	$(".on_off5 li:first").click(function(){
		//if (!easy_job_setting)
		{  
		$(this).addClass("on_on").removeClass("on");
		$(".on_off5 li:last").addClass("off").removeClass("off_on");
		easy_set.easy_set_option(5,1);
		}
	});

	$(".on_off5 li:last").click(function(){
		//if (!easy_job_setting)
		{  
		$(this).addClass("off_on").removeClass("off");
		$(".on_off5 li:first").addClass("on").removeClass("on_on");
		easy_set.easy_set_option(5,0);
		}
	});
    $(".on_off6 li:first").click(function(){
		//if (!easy_job_setting)
		{  
		$(this).addClass("on_on").removeClass("on");
		$(".on_off6 li:last").addClass("off").removeClass("off_on");
		easy_set.easy_set_option(6,1);
		}
	});

	$(".on_off6 li:last").click(function(){ 
		//if (!easy_job_setting)
		{ 
		$(this).addClass("off_on").removeClass("off");
		$(".on_off6 li:first").addClass("on").removeClass("on_on");
		easy_set.easy_set_option(6,0);
		}
	});

	//content slide
	$("#i_status").click(function(){
    	$(".widearea").animate({
        marginLeft: "-740px"
        }, 500);
	});
		
    $("#i_map").click(function() {
        $(".widearea").animate({
        marginLeft: "0px"
        }, 500);
    });
	
	$("#housing").showMenu({
		opacity:0.9,
		query: ".popup"
	});
	

	
	// power saving click
	$(".powersafe").click(function() {
		$("#b-title").html("<b>Power Saving</b>");
		$(".unit_bandwidth_icon").css('background-image','url(images/i_powersaving.gif)');
		var bH=$(window).height();
		var bW=$(window).width();

		$("#b-mask").css({width:bW,height:bH,display:"block"});
		$(".layer1").css({display:"block"});
    });
	
	// bandwidth click
	var b='';
   	$.each($.browser, function(i, val) {
    if (i=='safari' && val==true){b='safari';}
	if (i=='opera' && val==true){b='opera';}
	if (i=='msie' && val==true){b='msie';}
	if (i=='mozilla' && val==true){b='mozilla';}
    });

	
	$(".bandwidth").click(function() {
		$("#b-title").html("<b>Bandwidth MGMT</b>");
		$(".unit_bandwidth_icon").css('background-image','url(images/i_bandwidth_c.gif)');
		var bH=$(window).height();
		var bW=$(window).width();
		$("#b-mask").css({width:bW,height:bH,display:"block"});
		$(".layer1").css({display:"block"});
		if (b =='msie')
			$("#load").css({display:"block"});
						   
    });
	
	// firewall saving click
	$(".firewall").click(function() {
		$("#b-title").html("<b>Firewall</b>");
		$(".unit_bandwidth_icon").css('background-image','url(images/i_firewall2.gif)');
		var bH=$(window).height();
		var bW=$(window).width();

		$("#b-mask").css({width:bW,height:bH,display:"block"});
		$(".layer1").css({display:"block"});
    });
	
	// parental control click
	$(".parental").click(function() {
		$("#b-title").html("<b>Parental Control</b>");
		$(".unit_bandwidth_icon").css('background-image','url(images/i_parent.gif)');
		var bH=$(window).height();
		var bW=$(window).width();

		$("#b-mask").css({width:bW,height:bH,display:"block"});
		$(".layer1").css({display:"block"});
    });
	
	// Game Engine click
	$(".game").click(function() {
		$("#b-title").html("<b>Game Engine</b>");
		$(".unit_bandwidth_icon").css('background-image','url(images/i_game2.gif)');
		var bH=$(window).height();
		var bW=$(window).width();

		$("#b-mask").css({width:bW,height:bH,display:"block"});
		$(".layer1").css({display:"block"});
    });
	
	// wireless security click
	$(".wireless").click(function() {
		$("#b-title").html("<b>Wireless Security</b>");		
		$(".unit_bandwidth_icon").css('background-image','url(images/i_wireless_security2.gif)');
		var bH=$(window).height();
		var bW=$(window).width();

		$("#b-mask").css({width:bW,height:bH,display:"block"});
		$(".layer1").css({display:"block"});
    });
	

	
	// b_close
	$("#b-close").click(function() {
        $("#b-mask").hide();
    });
	
	}
);


function resscrEvt(){
	var bjCss=$("#b-mask").css("display");
	if(bjCss=="block"){
	var bH2=$(window).height();
	var bW2=$(window).width();
	$("#b-mask").css({width:bW2,height:bH2});
	}
}
