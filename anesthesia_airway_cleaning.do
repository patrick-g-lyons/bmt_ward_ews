* ==============================================================================
*
* this do-file compiles & cleans datasets with anesthesia & diff airway calls
*
* datasets used: - anesthesia_201x.xlsx (x = 4-7)
*				 - difficult_airway_201z.xlsx (z = 4-7)
*
* output dataset: - anesth_airway_all_2014_2017.dta
* 				  - anesth_airway_north_2014_2017.dta
*
* ==============================================================================


// import and save all years for anesthesia
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2014.xlsx", sheet("Sheet1") cellrange(A3:K545) firstrow case(lower) allstring
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2014.dta", replace
clear
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2015.xlsx", sheet("Sheet1") firstrow case(lower) allstring
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2015.dta", replace
clear
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2016.xlsx", sheet("Sheet1") firstrow case(lower) allstring
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2016.dta", replace
clear
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2017.xlsx", sheet("Sheet1") firstrow case(lower) allstring
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2017.dta", replace
clear

// import and save all years for difficult airway
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2014.xlsx", sheet("Sheet1") cellrange(A2:H80) firstrow case(lower) allstring
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2014.dta", replace
clear
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2015.xlsx", sheet("Sheet1") firstrow case(lower) allstring
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2015.dta", replace
clear
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2016.xlsx", sheet("Sheet1") firstrow case(lower) allstring
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2016.dta", replace
clear
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2017.xlsx", sheet("Sheet1") firstrow case(lower) allstring
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2017.dta", replace
clear

// combine anesthesia years into flat file
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2014.dta", clear
append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2015.dta" "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2016.dta" "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesthesia_2017.dta"
replace code7 = "1" if icucode !=""
drop arc noinfo operatorissue l m n icucode
gen airway_during_code = 1 if code7 !=""

// add difficult airway into flat file
append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2014.dta" "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2015.dta" "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2016.dta" "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/difficult_airway_2017.dta"

// clean up outpatient/visitor/employee rrt calls
foreach var of varlist datetime-q  {
	gen Z=lower(`var')
	drop `var'
	rename Z `var'
}

// clean date and time
replace datetime = a if mi(datetime)

generate airway_number = _n

generate year_check = "2014" if airway_number <=542 | (airway_number >=2229 & airway_number <=2305)
	replace year_check = "2015" if (airway_number >= 544 & airway_number <= 1032) | (airway_number >= 2307 & airway_number <= 2401)
	replace year_check = "2016" if (airway_number >= 1034 & airway_number <= 1434) | (airway_number >= 2487 & airway_number <= 2572)
	replace year_check = "2017" if (airway_number >= 1436 & airway_number <= 1733) | (airway_number >= 3293 & airway_number <= 3373)
	* this will correct for typos (e.g. "2014" in the midst of "2015"s)	
	
gen airway_date = regexs(1) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*)")		
	forvalues i = 14(1)17 {
		replace airway_date = regexr(airway_date, "/[0-9]+$", "/`i'") if regexm(year_check, "20`i'")
} 
	
tab datetime if mi(airway_date)
	replace airway_date = "5/14/2014" if regexm(datetime, "5/14/14")
	replace airway_date = "1/08/16" if regexm(datetime, "1/8 16")
	replace airway_date = "11/14/2015" if regexm(datetime, "11/14 15")
	replace airway_date = "5/16/2015" if regexm(datetime, "5/16 15")
	replace airway_date = "6/16/2016" if regexm(datetime, "6/16 16")
drop if mi(airway_date)
	
gen airway_time = regexs(2) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*[ ]*)([0-9][0-9][0-9][0-9]$)")
	replace airway_time = regexs(0) if airway_time=="" & regexm(datetime, "[0-9][0-9][0-9][0-9]$")
	replace airway_time = regexs(1) if airway_time=="" & regexm(datetime, "([0-9][0-9][0-9][0-9])([ ])$")	
tab datetime if mi(airway_time)
	replace airway_time = "0128" if regexm(datetime, "10/28/14 182")
	replace airway_time = "0138" if regexm(datetime, "11/15/14 138")
	replace airway_time = "0231" if regexm(datetime, "11/20/14 231")
	replace airway_time = "0543" if regexm(datetime, "11/24/17 0543/546")
	replace airway_time = "0457" if regexm(datetime, "12/12/17 0457/503")
	replace airway_time = "0110" if regexm(datetime, "3/5/15 110")
	replace airway_time = "0407" if regexm(datetime, "4/1/14 407")
	replace airway_time = "0643" if regexm(datetime, "4/16/17 0643")
	replace airway_time = "0153" if regexm(datetime, "6/8/17 0153/158")
	replace airway_time = "0852" if regexm(datetime, "8/31/17 0852")
	replace airway_time = "0929" if regexm(datetime, "8/8/2017 929")
replace airway_time = substr(airway_time,1,2)+":"+substr(airway_time,3,2)

gen airway_datetime = airway_date + " " + airway_time

gen double airway_datetime_2 = Clock(airway_datetime, "MD20Yhm")  
	format airway_datetime_2 %tC

drop airway_date airway_time datetime airway_datetime year_check a
rename airway_datetime_2 airway_datetime

// generate death variable
replace disposition = d if mi(disposition)
generate airway_death = 1 if regexm(disposition, "exp")
drop d

// drop calls on non-inpatients and false alarms (check w/ *preserve, keep, restore* first)
replace divisionarea = b if mi(divisionarea)
replace divisionarea = area if mi(divisionarea)
drop if disposition == "ed" | disposition == "home"
drop if regexm(disposition, "11[0-9]00") | regexm(disposition, "[8-9]100")
drop if regexm(disposition, "9200") | regexm(disposition, "71ou") | regexm(disposition, "105")
drop if regexm(disposition, "7500") | regexm(disposition, "62") | regexm(disposition, "102")
drop if regexm(disposition, "14") | regexm(disposition, "13") | regexm(disposition, "163")
drop if regexm(disposition, "54") | (regexm(disposition, "49") & died !=1) | regexm(disposition, "12[1-2]00")
generate not_admitted = 1 if regexm(divisionarea, "ed") | regexm(divisionarea, "trauma") | regexm(divisionarea, "tcc")
	replace not_admitted = . if regexm(divisionarea, "bed") | regexm(divisionarea, "med")
	replace not_admitted = 1 if regexm(divisionarea, "cam") | regexm(divisionarea, "valet")
drop if not_admitted == 1
drop not_admitted b

// clean extra vars
replace comments = h if mi(comments)
replace comments = q if mi(comments)
replace patientname = difficultairway if mi(patientname)
replace airway_during_code = f if mi(airway_during_code)
replace registration = r if mi(registration)

// clean location
generate unit = regexs(1) if regexm(divisionarea, "([0-9]*00)([.]*)")
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(icu)") & unit == ""
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(ccu)") & unit == ""
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)([ ]*ou)") & unit == ""
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)([ ]*pcu)") & unit == ""
	replace unit = "1" if regexm(divisionarea, "vir") | regexm(divisionarea, "ct") & unit == ""
	replace unit = "1" if regexm(divisionarea, " us ") | regexm(divisionarea, "endosc") & unit == ""
	replace unit = "1" if regexm(divisionarea, "mall") | regexm(divisionarea, "endosc") & unit == ""
	replace unit = "1" if regexm(divisionarea, "mall") | regexm(divisionarea, "cath") | regexm(divisionarea, "ccl") & unit == ""
drop if mi(unit) & (regexm(comments, "no info") | regexm(comments, "cancel") | regexm(comments, "not needed"))
drop if mi(unit) & mi(patientname)
drop if mi(unit) & disposition =="or"
	replace unit = "1" if mi(unit)
	replace unit = unit + "00" if regex(unit "^[0-9][0-9]$")
	replace unit = unit + "00" if unit == "104" | unit == "163"
drop if unit == "1200" | unit == "400"
	
generate room = regexs(2) if regexm(divisionarea, "([r][m][ ]*)([0-9]*)")
	replace room = regexs(2) if regexm(divisionarea, "([R]*[m][ ]*)([0-9]*)") & mi(room)
drop if airway_number == 1012 | airway_number ==1300
	replace room = "" if unit == "1"
	
generate ward = real(unit)
generate room_no = real(room)
	replace room_no = 0 if mi(room_no)
drop unit room
generate room = ward + room_no
drop room_no 

// clean registration
destring registration, force generate(reg_number)
	format reg_number %12.0g
drop registration

// clean disposition
generate airway_result = 1
	replace airway_result = 2 if regexm(disposition, "cu") | regexm(disposition, "59")
	replace airway_result = 2 if regexm(disposition, "104") | regexm(disposition, "89")
	replace airway_result = 1 if regexm(disposition, "ppcu") 
	replace airway_result = 3 if airway_death==1
	replace airway_result = 2 if regexm(disposition, "82") | regexm(disposition, "84")
	replace airway_result = 4 if regexm(disposition, "cath") | regexm(disposition, "or")
label define airway_result 1 "remained in ICU" 2 "ICU transfer" 3 "death" 4 "cath/OR"
label values airway_result airway_result

drop if regexm(disposition, "[0-9]+/[0-9]+/[0-9]+")
drop if airway_result ==1 & disposition !=""

generate keep_icu = 1 if ward==5900 | ward==8900 | ward==8200 | ward==8300 
	replace keep_icu = 1 if ward==10400 | ward==8400
drop if airway_result ==1 & keep_icu !=1
drop keep_icu

generate airway_disposition = regexs(1) if regexm(disposition, "([0-9]+)(icu)") 
	replace airway_disposition = regexs(1) if regexm(disposition, "([0-9]+)(cc)")
	replace airway_disposition = regexs(1) if regexm(disposition, "([0-9]+)(ou)")
	replace airway_disposition = airway_disposition + "00" if !mi(airway_disposition)
	replace airway_disposition = regexs(1) if regexm(disposition, "([0-9][0-9]+)") & mi(airway_disposition)
	replace airway_disposition = "8300" if airway_disposition=="83"
	replace airway_result = 1 if airway_disposition=="163"
	replace airway_disposition = "" if airway_result ==3
	replace airway_disposition = "10400" if regexm(disposition, "401")
	replace airway_result = 1 if regexm(disposition, "401")
	replace airway_disposition = "8200" if regexm(disposition, "82cu")

generate airway_dispo = real(airway_disposition)
drop airway_disposition

// drop extra vars
drop e-q area-difficultairway patientname comments 
ren airway_datetime time
// save big file
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesth_airway_all_2014_2017.dta", replace

// save north campus codes
generate keep_north_units = 1 if ward==1
local K 4900 5900 6900 7900 8900
foreach k of local K {
	replace keep_north_units = 1 if ward == `k'
	}

keep if keep_north_units ==1
drop keep_north_units

gen double time_minutes=1000*floor(time/1000)
format time_minutes %tC

drop if airway_number == 1700
	* this is a duplicate with airway_number 3372 (one was anesthesia, one was difficult airway)

save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesth_airway_north_2014_2017.dta", replace



