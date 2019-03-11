var whichDayNum;
  var BigMon=new Array('1','3','5','7','8','10','12');
  var SmallMon=new Array('4','6','9','11');
  var Hour, Min, Sec;
  var Year, Mon, Day;
  var startDay_value, endDay_value;
  
function initDateAndTime()
        {
           //alert("run initDateAndTime");
           Hour=parseInt(document.NTP.mtenCurrent_Hour.value,10);
           Min=parseInt(document.NTP.mtenCurrent_Min.value,10);
           Sec=parseInt(document.NTP.mtenCurrent_Sec.value,10);
           Year=parseInt(document.NTP.mtenCurrent_Year.value,10);
           Mon=parseInt(document.NTP.mtenCurrent_Mon.value,10);
           Day=parseInt(document.NTP.mtenCurrent_Day.value,10);
           document.getElementById("mtenCurrent_Time").innerHTML = DateAndTimeFormat(Hour) + ":"+ DateAndTimeFormat(Min) +":" + DateAndTimeFormat(Sec);
           document.getElementById("mtenCurrent_Date").innerHTML = Year + "-"+ DateAndTimeFormat(Mon) +"-" + DateAndTimeFormat(Day);
       }
function DateAndTimeFormat(num)
        {
                if(String(parseInt(num,10)).length==1)
                        return "0"+num;
                else
                        return num;
        }    

function IncreaseSec()
        {
        Sec = parseInt(document.NTP.mtenCurrent_Sec.value,10);
        Sec = Sec + 1;
        if ( Sec < 60 )
        {
            document.getElementById("mtenCurrent_Time").innerHTML = DateAndTimeFormat(Hour) + ":"+ DateAndTimeFormat(Min) +":" + DateAndTimeFormat(Sec);
            document.NTP.mtenCurrent_Sec.value = Sec;
            setTimeout('IncreaseSec()', 1000);
            return ;
        }

        document.NTP.mtenCurrent_Sec.value = 0;Sec=0;
        Min = parseInt(document.NTP.mtenCurrent_Min.value,10);
        Min = Min + 1;
        if ( Min < 60 )
        {
            document.getElementById("mtenCurrent_Time").innerHTML = DateAndTimeFormat(Hour) + ":"+ DateAndTimeFormat(Min) +":" + DateAndTimeFormat(Sec);
            document.NTP.mtenCurrent_Min.value = Min;
            setTimeout('IncreaseSec()', 1000);
            return;
        }

        document.NTP.mtenCurrent_Min.value = 0;Min=0;
        Hour = parseInt(document.NTP.mtenCurrent_Hour.value,10);
        Hour = Hour + 1;
        if ( Hour < 24 )
        {
            document.getElementById("mtenCurrent_Time").innerHTML = DateAndTimeFormat(Hour) + ":"+ DateAndTimeFormat(Min) +":" + DateAndTimeFormat(Sec);
            document.NTP.mtenCurrent_Hour.value = Hour;
            setTimeout('IncreaseSec()', 1000);
            return;
        }
        document.getElementById("mtenCurrent_Time").innerHTML = "00 : 00 : 00";
        document.NTP.mtenCurrent_Hour.value = 0;Hour=0;
        Day = parseInt(document.NTP.mtenCurrent_Day.value,10);
        Day = Day + 1;
        Mon = parseInt(document.NTP.mtenCurrent_Mon.value,10);
        Year = parseInt(document.NTP.mtenCurrent_Year.value,10);

                for(var i=0;i<BigMon.length;i++)
                        if(Mon.value==BigMon[i]) whichDayNum=31;
                for(var i=0;i<SmallMon.length;i++)
                        if(Mon.value==SmallMon[i]) whichDayNum=30;
                if((Year.value%4)==0)
                        whichDayNum=29;
                else
                        whichDayNum=28;

        if ( Day <= whichDayNum )
        {
            document.getElementById("mtenCurrent_Date").innerHTML = Year + "-"+ DateAndTimeFormat(Mon) +"-" + DateAndTimeFormat(Day);
            document.NTP.mtenCurrent_Day.value = Day;
            setTimeout('IncreaseSec()', 1000);
            return;
                }

        document.NTP.mtenCurrent_Day.value = 1;Day=1;
        Mon = parseInt(document.NTP.mtenCurrent_Mon.value,10);
        Mon = Mon + 1;

        if ( Mon <= 12 )
        {
            document.getElementById("mtenCurrent_Date").innerHTML = Year + "-"+ DateAndTimeFormat(Mon) +"-" + DateAndTimeFormat(Day);
            document.NTP.mtenCurrent_Mon.value = Mon;
            setTimeout('IncreaseSec()', 1000);
            return;
                }

        document.NTP.mtenCurrent_Mon.value = 1;Mon=1;
        Year = parseInt(document.NTP.mtenCurrent_Year.value,10);
        Year = Year + 1;

        if ( Year < 10000)
        {
            document.getElementById("mtenCurrent_Date").innerHTML = Year + "-"+ DateAndTimeFormat(Mon) +"-" + DateAndTimeFormat(Day);
            document.NTP.mtenCurrent_Year.value = Year;
            setTimeout('IncreaseSec()', 1000);
            return;
                }

        document.NTP.mtenCurrent_Year.value = 1900;Year=1900;

        return;
    }

function calculate_target_date(target_year, target_month, target_day, target_num_day)
{

	//alert("calculate=");

	var now=new Date();
	now.setYear(target_year);
	now.setMonth(target_month-1);
	now.setDate(1);
	temp_Month = now.setMonth(target_month-1);
	temp_Day = now.getDay();
	
	//alert("calculate=");
	
	if (target_day>=temp_Day)
		offset_date=target_day-temp_Day+1;
	else	
		offset_date=target_day-temp_Day+8;
		
	target_date	=offset_date+(target_num_day*7);

	if (target_num_day==4)
	{
		if( (target_month==1) || (target_month==3) || (target_month==5) || (target_month==7) || (target_month==8) || (target_month==10) || (target_month==12) )
	    {
	    	max_date=31;
	    }
		
		if( (target_month==4) || (target_month==6) || (target_month==9) || (target_month==11) )
	    {
		    max_date=30;
		}
		
		if (target_month==2)
	    {
			if(((target_year)%4)==0)
		    	max_date=29;
		    else	
		    	max_date=28;
		}
		
		if (target_date>max_date)
			target_date=target_date-7;
	}
	
	return target_date;
}

function onchange_calculate_target_date(change_year)
{
		//alert("onchange="+start_Mon);
		
		if (modes == 'manual')
			temp_yyy=mtensNew_Year;
		else
			temp_yyy=document.NTP.mtenCurrent_Year.value;
			
		if (change_year)
		{
	 	  temp_yyy++;
		}
		
		//alert("onchange="+temp_yyy );		
		
		start_Num--;
		dst_startDay=calculate_target_date(temp_yyy, start_Mon, start_D, start_Num);
		
		//alert("onchange="+start_Mon+);
	
		temp_dst_start_Hour=start_Hour;

		//alert("onchange="+temp_yyy+"/"+start_Mon+"/"+dst_startDay+" "+temp_dst_start_Hour+":0:0");
		
		end_Num--;
		dst_endDay=calculate_target_date(temp_yyy, end_Mon, end_D, end_Num);
		   
		//alert("onchange="+end_Mon+);
		
		temp_dst_end_Hour=end_Hour;
		
		//alert("start timee="+temp_yyy+"/"+start_Mon+"/"+dst_startDay+" "+temp_dst_start_Hour+":0:0"+" end timee="+temp_yyy+"/"+end_Mon+"/"+dst_endDay+" "+temp_dst_end_Hour+":0:0");
		
		temp_dst_start_long_sec = Date.parse(""+temp_yyy+"/"+start_Mon+"/"+dst_startDay+" "+temp_dst_start_Hour+":0:0");
		temp_dst_end_long_sec = Date.parse(""+temp_yyy+"/"+end_Mon+"/"+dst_endDay+" "+temp_dst_end_Hour+":0:0");

		if (temp_dst_end_long_sec < temp_dst_start_long_sec)
		{
			temp_over_year=1;
			//temp_ys=temp_yyy; //test
		}
		else
		{
			temp_over_year=0;
			//temp_ys=temp_yyy; //test
		}
		
		//current time
		temp_now_Hour=parseInt(document.NTP.mtenCurrent_Hour.value,10);
		temp_now_Min=parseInt(document.NTP.mtenCurrent_Min.value,10);
		temp_now_Sec=parseInt(document.NTP.mtenCurrent_Sec.value,10);
		temp_now_Year=parseInt(document.NTP.mtenCurrent_Year.value,10);
		temp_now_Mon=parseInt(document.NTP.mtenCurrent_Mon.value,10);
		temp_now_Day=parseInt(document.NTP.mtenCurrent_Day.value,10);
		temp_now_long_sec = Date.parse(""+temp_now_Year+"/"+temp_now_Mon+"/"+temp_now_Day+" "+temp_now_Hour+":"+temp_now_Min+":"+temp_now_Sec+"");
   
		
		if ( enable_dst=='1' )
		{
			temp_now_long_sec=temp_now_long_sec-3600000;
		}
	
		in_range_park=0;
   
		if(temp_over_year==1)
		{
			if(temp_now_long_sec < temp_dst_end_long_sec)
				in_range_park=1;
	
			if(temp_now_long_sec >= temp_dst_start_long_sec)
				in_range_park=2;

		}
		
		if (start_Mon<10)
			mon_zero_string="0";
		else
			mon_zero_string="";
		
		if (dst_startDay<10)
			day_zero_string="0";
		else 
			day_zero_string="";
		
		if(temp_over_year==1)
		{
			if (in_range_park==0)
			{
				startDay_value= day_zero_string+dst_startDay ;				
			}
			
			if (in_range_park==1)
			{
				temp_y=temp_yyy;
				temp_y--;
				//temp_ys=temp_y; //test
				prev_year_dst_startDay=calculate_target_date(temp_y, start_Mon, start_D, start_Num);
				startDay_value= day_zero_string+prev_year_dst_startDay ;					
			}
		
			if (in_range_park==2)
			{
				startDay_value= day_zero_string+dst_startDay ;			
			}	
		}
		else
		{
			startDay_value= day_zero_string+dst_startDay ;		
		}
		
		
		//temp_ye=temp_yyy; //test
		if (end_Mon<10)
		{
			mon_zero_string="0";
		}
		else
		{	
			mon_zero_string="";
		}
		
		if (dst_endDay<10)
		{
			day_zero_string="0";
		}	
		else
		{
			day_zero_string="";
		}
		
		if(temp_over_year==1) 
		{
			if (in_range_park==0)
			{
				temp_y=temp_yyy;
				temp_y++;
				//temp_yyy=temp_y; //test
				next_year_dst_endDay=calculate_target_date(temp_y, end_Mon, end_D, end_Num);
				endDay_value= day_zero_string+next_year_dst_endDay ;			
			}
		
			if (in_range_park==1)
			{
				endDay_value= day_zero_string+dst_endDay ;
			}
			
			if (in_range_park==2)
			{
				temp_y=temp_yyy;
				temp_y++;
				//temp_ye=temp_y; //test
				next_year_dst_endDay=calculate_target_date(temp_y, end_Mon, end_D, end_Num);
				endDay_value= day_zero_string+next_year_dst_endDay ;			
			}
		}
		else
		{
			endDay_value= day_zero_string+dst_endDay ;	
		}
		
        //alert("start timee="+temp_ys+"/"+start_Mon+"/"+startDay_value+" "+temp_dst_start_Hour+":0:0"+" end timee="+temp_ye+"/"+end_Mon+"/"+endDay_value+" "+temp_dst_end_Hour+":0:0");		
		
}

	
function daylightsaving()
{
/*
	//alert("run daylightsaving");
	var now_sec;
	var dl_start_sec;
	var dl_end_sec;

   onchange_calculate_target_date(0);
   
   
	//current time
   now_Hour=parseInt(document.NTP.mtenCurrent_Hour.value,10);
   now_Min=parseInt(document.NTP.mtenCurrent_Min.value,10);
   now_Sec=parseInt(document.NTP.mtenCurrent_Sec.value,10);
   now_Year=parseInt(document.NTP.mtenCurrent_Year.value,10);
   now_Mon=parseInt(document.NTP.mtenCurrent_Mon.value,10);
   now_Day=parseInt(document.NTP.mtenCurrent_Day.value,10);
   
  //dst start time
   dst_start_Mon=parseInt(start_Mon,10);
   dst_start_Day=parseInt(startDay_value,10);
   dst_start_Hour=parseInt(start_Hour,10);
   //alert("start time=");
   //alert('start time=' start_Mon+startDay_value+start_Hour);
   
   //dst end time
   dst_end_Mon=parseInt(end_Mon,10);
   dst_end_Day=parseInt(endDay_value,10);
   dst_end_Hour=parseInt(end_Hour,10);
   //alert('end time=' end_Mon+endDay_value+end_Hour);
   
   
   
   now_long_sec = Date.UTC(now_Year, now_Mon, now_Day, now_Hour, now_Min, now_Sec);
   dst_start_long_sec = Date.UTC(now_Year, dst_start_Mon, dst_start_Day, dst_start_Hour, now_Min, now_Sec);
   dst_end_long_sec = Date.UTC(now_Year, dst_end_Mon, dst_end_Day, dst_end_Hour, now_Min, now_Sec);
   //alert(now_long_sec);
   //alert(dst_start_long_sec);
   //alert(dst_end_long_sec);
   if(dst_start_long_sec > dst_end_long_sec)
   {
		dst_end_long_sec = Date.UTC(now_Year +1 , dst_end_Mon, dst_end_Day, dst_end_Hour, now_Min, now_Sec);
   }
   
//DST start
   if((now_long_sec >= dst_start_long_sec)&&(now_long_sec < dst_end_long_sec))
   {
     //alert(document.NTP.mtenCurrent_Hour.value);
     //alert("DST start");
     systemhour = document.NTP.mtenCurrent_Hour.value;
     Hour = parseInt(systemhour,10);
     systemDay = document.NTP.mtenCurrent_Day.value;
     Day = parseInt(systemDay,10);
     systemmon = document.NTP.mtenCurrent_Mon.value;
     Mon = parseInt(systemmon,10);
     systemyear = document.NTP.mtenCurrent_Year.value;
     Year = parseInt(systemyear,10);
     
     if(Hour==23)
     {
       
       if(((Mon==2)&&(Day==28))||((Mon==2)&&(Day==29)))
       {
         Day = 0;
         Mon = (Mon+1);
       }
       if(((Mon==4)||(Mon==6)||(Mon==9)||(Mon==11))&&(Day==30))
       {
         Day = 0;
         Mon = (Mon+1);      
       }
       if(((Mon==1)||(Mon==3)||(Mon==5)||(Mon==7)||(Mon==8)||(Mon==10))&&(Day==31))
       {
         Day = 0;
         Mon = (Mon+1);      
       }
       if((Mon==12)&&(Day==31))
       {
         Day = 0;
         Mon = 0;
         Mon = (Mon+1);
         Year = (Year+1);
       }
     Hour=(0-1);
     Day=(Day+1);
      
     }
              
     Hour=(Hour+1);
     document.NTP.mtenCurrent_Year.value = Year;
     document.NTP.mtenCurrent_Mon.value = Mon;
     document.NTP.mtenCurrent_Day.value = Day;
     document.NTP.mtenCurrent_Hour.value = Hour;
        
   }
*/
//DST end
}           