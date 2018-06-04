* ==============================================================================
*
* this do-file compiles & cleans datasets with code calls
*
* datasets used: - code_201x.xlsx (x = 4-7)
*
* output dataset: - codes_all_2014_2017.dta
* 				  - codes_north_2014_2017.dta
*
* ==============================================================================


// import and save all years
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2014.xlsx", sheet("Sheet1") cellrange(A2:Q997) firstrow case(lower) allstring
drop noctmlaserwhenshouldhave
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2014.dta", replace
clear
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/codes_2015.xlsx", sheet("Sheet1") firstrow case(lower) allstring
drop noctmlaserwhenshouldhave
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2015.dta", replace
clear
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2016.xlsx", sheet("Sheet1") firstrow case(lower) allstring
drop noctmlaserwhenshouldhave
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2016.dta", replace
clear
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2017.xlsx", sheet("Sheet1") firstrow case(lower) allstring
drop noctmlaserwhenshouldhave
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2017.dta", replace
clear

// combine years into flat file
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2014.dta", clear
append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2015.dta""/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2016.dta" "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/code_2017.dta"

// clean up outpatient/visitor/employee rrt calls
foreach var of varlist datetime-callto22700line  {
	gen Z=lower(`var')
	drop `var'
	rename Z `var'
}

// clean date + time
generate code_number = _n

generate year_check = "2014" if code_number <=795
	replace year_check = "2015" if code_number >= 997 & code_number <= 1694
	replace year_check = "2016" if code_number >= 1899 & code_number <= 2813
	replace year_check = "2017" if code_number >= 2816 
	* this will correct for typos (e.g. "2014" in the midst of "2015"s)	
	
gen code_date = regexs(1) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*)")		
	forvalues i = 14(1)17 {
		replace code_date = regexr(code_date, "/[0-9]+$", "/`i'") if regexm(year_check, "20`i'")
	} 
tab datetime if mi(code_date)
	replace code_date = "7/19/2014" if regexm(datetime, "7/19/2014")
	replace code_date = "8/22/16" if regexm(datetime, "8/22/16")
	replace code_date = "12/17/2017" if regexm(datetime, "12/1717")
	replace code_date = "3/24/2015" if regexm(datetime, "3/2415")
	replace code_date = "5/15/2017" if regexm(datetime, "5/15 17")
	replace code_date = "10/22/2015" if regexm(datetime, "10/22/15")
drop if mi(code_date)
	
gen code_time = regexs(2) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*[ ]*)([0-9][0-9][0-9][0-9]$)")
	replace code_time = regexs(0) if code_time=="" & regexm(datetime, "[0-9][0-9][0-9][0-9]$")
	replace code_time = regexs(1) if code_time=="" & regexm(datetime, "([0-9][0-9][0-9][0-9])([ ])$")	
	replace code_time = substr(code_time,1,2)+":"+substr(code_time,3,2)
tab datetime if code_time == ":", mi
	replace code_time = "14:24" if regexm(datetime, "8/22/16 1424")
	replace code_time = "02:57" if regexm(datetime, "10/23/17 0257")
	replace code_time = "10:51" if regexm(datetime, "11/21/16 1051")
	replace code_time = "17:38" if regexm(datetime, "11/23/17 1738")
	replace code_time = "09:27" if regexm(datetime, "2/10/17 0927")
	replace code_time = "02:09" if regexm(datetime, "4/12/17 209")
	replace code_time = "07:23" if regexm(datetime, "6/30/17 0723")
	replace code_time = "07:16" if regexm(datetime, "7/6/16 0716")
	replace code_time = "15:14" if regexm(datetime, "8/13/14 1514")
	replace code_time = "13:50" if regexm(datetime, "9/16/16 1350")
	replace code_time = "08:23" if regexm(datetime, "9/9/17 0823")
		
gen code_datetime = code_date + " " + code_time

gen double code_datetime_2 = Clock(code_datetime, "MD20Yhm")  
	format code_datetime_2 %tC

drop code_date code_time datetime code_datetime year_check
rename code_datetime_2 code_datetime

// drop codes called on non-inpatients
drop if disposition == "ed" | regexm(disposition, " ed")
drop if regexm(disposition, "^ed ") | regexm(disposition, "cam")
drop if regexm(disposition, "home") | regexm(disposition, "children")
drop if regexm(disposition, "cancel") | regexm(disposition, "preg")
drop if regexm(disposition, "security") | regexm(disposition, "app") | regexm(disposition, "testing")
generate keep = 1 if regexm(comments, "pt from [0-9]+00")
drop if keep !=1 & regexm(divisionarea, "cam")
drop q r h callto* keep ctmordered ptname

// drop false alarm calls
drop if regexm(comments, "leads off") | regexm(comments, "no info") | regexm(comments, "no signal")
drop if regexm(comments, "battery") | regexm(comments, "no cpa")
drop if regexm(comments, "cancel") & regexm(comments, "ctm for")
drop if regexm(comments, "cancel") & regexm(comments, "dnr")

preserve
keep if notacodecanceled !="" | notacodenotcpa !=""
* manual inspection
restore

generate keep = 1 if regexm(comments, "pea") | regexm(comments, "pulseless")
	replace keep = 1 if regexm(comments, "arrest") | regexm(comments, "changed to code")
	replace keep = 1 if regexm(comments, "bagged") | regexm(comments, "intubate")
	replace keep = 1 if regexm(comments, "rosc") | regexm(comments, "no pulse")

drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "cancel") & keep !=1
drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "unknown reason") & keep !=1
drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "back to room") & keep !=1
drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "stayed on floor") & keep !=1
drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "changed to act") & keep !=1
drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "probably not true") & keep !=1
drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "dnr") & keep !=1
drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "refuse ed") & keep !=1
drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "trach") & keep !=1
drop if (notacodecanceled !="" | notacodenotcpa !="") & regexm(comments, "seizure") & keep !=1

drop if regexm(comments, "not sure why called")
drop if regexm(comments, "canceled [0-9][0-9][0-9][0-9]") & keep !=1
drop if regexm(comments, "stroke")

drop code_number
generate code_number = _n

generate drop_notcode = .	
local A 294 297 310 324 325 328 339 367 368 376 378 384 404 405 407 434 438 
foreach a of local A {
	replace drop_notcode = 1 if code_number == `a'
}	
local B 440 444 451 452 455 485 488 509 515 522 535 536 537 538 543 547 549 552 
foreach b of local B {
	replace drop_notcode = 1 if code_number == `b'
}	
local C 557 565 572 574 583 592 605 634 637 643 658 659 690 693 694 695 696  
foreach c of local C {
	replace drop_notcode = 1 if code_number == `c'
}	
local D 13 14 16 29 32 38 42 63 66 71 86 93 100 115 117 137 141 142 143 151 167 
foreach d of local D {
	replace drop_notcode = 1 if code_number == `d'
}	
local E 176 183 195 255 259 260 265 279 284
foreach e of local E {
	replace drop_notcode = 1 if code_number == `e'
}

drop if drop_notcode == 1
drop drop_notcode tele*

// create code_death01 variable
generate code_death01 = 1 if regexm(disposition, "exp")
	replace code_death01 = . if regexm(disposition, "cu") 
	replace code_death01 = 1 if code_number == 29 | code_number == 30
	replace code_death01 = 1 if code_number == 36 | code_number == 37
	replace code_death01 = 1 if code_number == 133

	
// encode categorical disposition variable
generate code_result = 1
	replace code_result = 2 if regexm(disposition, "cu") | regexm(disposition, "59")
	replace code_result = 2 if regexm(disposition, "104") | regexm(disposition, "89")
	replace code_result = 1 if regexm(disposition, "ppcu") 
	replace code_result = 3 if code_death==1
	replace code_result = 4 if code_number == 52 | code_number == 155
	replace code_result = . if code_number == 516
label define code_result 1 "no change" 2 "ICU transfer" 3 "death" 4 "cath/OR"
label values code_result code_result

drop if code_result ==1

generate code_disposition = regexs(1) if regexm(disposition, "([0-9]+)(icu)") 
	replace code_disposition = regexs(1) if regexm(disposition, "([0-9]+)(ccu)")
	replace code_disposition = regexs(1) if regexm(disposition, "([0-9]+)(ou)")
	replace code_disposition = code_disposition + "00" if !mi(code_disposition)
	replace code_disposition = regexs(1) if regexm(disposition, "([0-9][0-9]+)") & mi(code_disposition)
	replace code_disposition = "8300" if code_disposition=="83"
	replace code_result = 1 if code_disposition=="163"
	replace code_result = 2 if code_number == 8
	replace code_disposition = "" if code_result ==3
	
generate code_dispo = real(code_disposition)

// destring location details
generate unit = regexs(1) if regexm(divisionarea, "([0-9]*00)([.]*)")
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(ou)")
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(pcu)")
	replace unit = "1" if regexm(divisionarea, "vir") | regexm(divisionarea, "ct") 
	replace unit = "1" if regexm(divisionarea, " us ") | regexm(divisionarea, "endosc")
	replace unit = "1" if regexm(divisionarea, "mall") | regexm(divisionarea, "endosc")
	replace unit = "1" if regexm(divisionarea, "mall")
	replace unit = "1" if mi(unit) & code_result ==2

generate room = regexs(2) if regexm(divisionarea, "([r][m][ ]*)([0-9]*)")
	replace room = regexs(2) if regexm(divisionarea, "([R]*[m][ ]*)([0-9]*)") & mi(room)
	
generate ward = real(unit)
generate room_no = real(room)
	replace room_no = 0 if mi(room_no)
drop unit room
generate room = ward + room_no
drop room_no 
replace ward = 5900 if code_number == 293 | code_number == 317
replace room = 5942 if code_number == 293
replace room = 5915 if code_number == 317
drop if mi(ward) & mi(room)

drop code_disposition keep aed* disposition timetoicu n* divisionarea comments cpap*

// destring registration number (for matching)
destring registration, force generate(reg_number)
	format reg_number %12.0g
drop registration
ren code_datetime time
gen double time_minutes=1000*floor(time/1000)
format time_minutes %tC

// save big file
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/codes_all_2014_2017.dta", replace

// save north campus codes
generate keep_north_units = 1 if ward==1
local K 4900 5900 6900 7900 8900
foreach k of local K {
	replace keep_north_units = 1 if ward == `k'
	}

keep if keep_north_units ==1
drop keep_north_units

save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/codes_north_2014_2017.dta", replace













