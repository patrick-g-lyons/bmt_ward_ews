// rapid response calls - BJH north campus

// 2014 data
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_calls_2014.xlsx", sheet("Sheet1") firstrow case(lower)

* drop blank first row
generate count = _n
drop if count==1
drop count n-ag whocalledact

* destring dates/times
	
	// rrt time
	generate rrt_number = _n
	gen rrt_date = regexs(1) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*)")
		replace rrt_date = "1/1/14" if rrt_number == 5
		replace rrt_date = "2/11/14" if rrt_number == 166
		replace rrt_date = "2/26/14" if rrt_number == 219
		replace rrt_date = "5/14/14" if rrt_number == 481
		replace rrt_date = "5/24/14" if rrt_number == 529
		replace rrt_date = "10/14/14" if rrt_number == 1065
	drop if rrt_number==873
	drop if mi(rrt_date)

	gen rrt_time = regexs(2) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*[ ]*)([0-9][0-9][0-9][0-9]$)")
		replace rrt_time = regexs(0) if rrt_time=="" & regexm(datetime, "[0-9][0-9][0-9][0-9]$")
		replace rrt_time = "0705" if rrt_number==463
		replace rrt_time = "1955" if rrt_number==619	
		replace rrt_time = substr(rrt_time,1,2)+":"+substr(rrt_time,3,2)
		
	gen rrt_datetime = rrt_date + " " + rrt_time
		replace rrt_datetime = "09/11/14 19:27" if rrt_number == 911

	gen double rrt_datetime_2 = Clock(rrt_datetime, "MD20Yhm")  
		format rrt_datetime_2 %tC

	drop rrt_date rrt_time datetime rrt_datetime
	rename rrt_datetime_2 rrt_datetime

	// birthdate (may be useful for matching)
	* some birthdates mistakenly have year of 20xx instead of 19xx
	gen dob_2 = reverse(substr(reverse(dob),1,2)+"91"+substr(reverse(dob),5,(length(dob) - 4)))
		replace dob_2 = "02/15/1940" if regexm(dob, "2.15")
		replace dob_2 = "12/5/1955" if regexm(dob, "//55")
		replace dob_2 = "" if dob_2 =="19"
		replace dob_2 = "06/07/1973" if regexm(dob, "jun")
	gen double birth_date = date(dob_2, "MD19Y")
	format birth_date %td
	drop dob*

	// discharge date
		replace dcdate = "9/14/14" if regexm(dcdate, "sep")
		replace dcdate = substr(dcdate, 6, .) if regexm(dcdate, "inpt")
	gen double dc_date = date(dcdate, "MD20Y")
	format dc_date %td
	drop dcdate
	
* encode expired and alive_at_discharge dummy vars (all entries not mi or 1 are outpatients
preserve
tab alivedc expired, mi
keep if alivedc !="1" & alivedc !=""
restore
drop if alivedc !="1" & alivedc !=""

encode expired, gen(died)
encode alivedc, gen(alive_at_discharge)

drop expired alivedc

* code?
generate rrt_into_code = .
	replace rrt_into_code = 1 if regexm(turnedintocode7, "Y")
	replace rrt_into_code = 0 if regexm(turnedintocode7, "N") | regexm(turnedintocode7, "n")
drop turnedintocode7

* encode categorical disposition variable
generate rrt_result = 1
	replace rrt_result = 2 if regexm(disposition, "CU") | regexm(disposition, "59")
	replace rrt_result = 2 if regexm(disposition, "CIU") | regexm(disposition, "8900")
	replace rrt_result = 1 if regexm(disposition, "non") 
	replace rrt_result = 3 if regexm(disposition, "Exp") | regexm(disposition, "orgue")
  	replace died = 1 if rrt_result ==3
	drop if regexm(disposition, "Conf")
label define rrt_result 1 "no change" 2 "ICU transfer" 3 "death"
label values rrt_result rrt_result
 
generate rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(icu)")
	replace rrt_disposition = rrt_disposition + "00" if !mi(rrt_disposition)
		replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)") & mi(rrt_disposition)
generate rrt_dispo = real(rrt_disposition)
drop rrt_disposition
	
* destring registration number (for matching)
destring registration, force generate(reg_number)
	format reg_number %12.0g
drop registration

* destring length of rrt
generate rrt_duration_hours = regexs(1) if regexm(actrntimethere, "([0-9]*)([ ]*[Hh])")
	replace rrt_duration_hours = "3.5" if regexm(actrntimethere, "3.5")
	
generate rrt_duration_min = regexs(1) if regexm(actrntimethere, "([0-9]*)([ ]*[Mm])")
	replace rrt_duration_min = regexs(2) if regexm(actrntimethere, "([r][s]*[ ]*)([0-9]*)") & rrt_duration_min == ""
	destring actrntimethere, force generate(check_number)
	replace rrt_duration_min = actrntimethere if check_number !=.
	generate still_missing = 1 if mi(rrt_duration_min) & mi(rrt_duration_hours)
	replace rrt_duration_min = "40" if regexm(actrntimethere, "0710, 40")
	replace rrt_duration_min = "120" if regexm(actrntimethere, "70 plus 50")
	replace rrt_duration_min = "40" if regexm(actrntimethere, "0710, 40")
	replace rrt_duration_min = "10" if regexm(actrntimethere, "10") & still_missing==1
	replace rrt_duration_min = "20" if regexm(actrntimethere, "20") & still_missing==1
	replace rrt_duration_min = "20" if regexm(actrntimethere, "20") & still_missing==1
	replace rrt_duration_min = "30" if regexm(actrntimethere, "30") & still_missing==1
	replace rrt_duration_min = "40" if regexm(actrntimethere, "40") & still_missing==1
	replace rrt_duration_min = "60" if regexm(actrntimethere, "60") & still_missing==1
	drop if regexm(actrntimethere, "cancel")
		
generate rrt_hours_numeric = real(rrt_duration_hours)
generate rrt_min_numeric = real(rrt_duration_min)
	replace rrt_min_numeric = . if rrt_min_numeric==0
mvencode *_numeric, mv(0)
generate rrt_hours_to_min = 60*rrt_hours_numeric
generate rrt_duration = rrt_hours_to_min + rrt_min_numeric
	replace rrt_duration = . if rrt_duration==0
drop rrt_hours* rrt_min* rrt_duration_* actrntimethere check_number still_missing

* destring time from act to icu arrival
generate hours_to_icutx = regexs(1) if regexm(timefromacttoicuarrivalicu, "([0-9]*)([ ]*[Hh])") & rrt_result ==2
	
generate minutes_to_icutx = regexs(1) if regexm(timefromacttoicuarrivalicu, "([0-9]*)([ ]*[Mm])")
	replace minutes_to_icutx = regexs(2) if regexm(timefromacttoicuarrivalicu, "([r][s]*[ ]*)([0-9]*)") & minutes_to_icutx == ""
	destring timefromacttoicuarrivalicu, force generate(check_number)
	replace minutes_to_icutx = timefromacttoicuarrivalicu if check_number !=. & minutes_to_icutx == ""
	replace minutes_to_icutx = "40" if regexm(timefromacttoicuarrivalicu, "40") & minutes_to_icutx == ""
	replace minutes_to_icutx = "200" if regexm(timefromacttoicuarrivalicu, "200") & minutes_to_icutx == ""

generate hours = real(hours_to_icutx)
generate minutes = real(minutes_to_icutx)
	replace minutes = . if minutes==0
mvencode hours minutes, mv(0)
generate hours_to_min = 60*hours
generate time_from_rrt_to_icutx = hours_to_min + minutes
	replace time_from_rrt_to_icutx = . if time_from_rrt_to_icutx==0
drop check_number timefromacttoicuarrivalicu hours* minutes*

* rrt location
generate unit = regexs(1) if regexm(divisionarea, "([0-9]*00)([.]*)")
	replace unit = "1" if regexm(divisionarea, "VIR") | regexm(divisionarea, "CT") 
	replace unit = "1" if regexm(divisionarea, "US") | regexm(divisionarea, "ndosc")
	
generate room = regexs(2) if regexm(divisionarea, "([r][m][ ]*)([0-9]*)")
	replace room = regexs(2) if regexm(divisionarea, "([R][m][ ]*)([0-9]*)") & mi(room)

generate ward = real(unit)
generate room_no = real(room)
		replace room_no = 0 if mi(room_no)
drop unit room
generate room = ward + room_no
drop room_no

* clean up outpatient/visitor/employee rrt calls
foreach var of varlist disposition divisionarea comments {
	gen Z=lower(`var')
	drop `var'
	rename Z `var'
}

drop if mi(ward) & mi(room)
drop if disposition == "ed" | regexm(divisionarea, "nurs") | regexm(divisionarea, "fall")
drop if regexm(disposition, "home") | regexm(comments, "family member")

* clean up canceled calls (e.g., some say "cancelled for code")
generate keep = 1 if regexm(comments, "anes") | regexm(comments, "expire") | regexm(comments, "code")
	replace keep = 1 if regexm(comments, "icu") | regexm(comments, "hypo") | regexm(comments, "5900")
	replace keep = 1 if regexm(comments, "rvr") | regexm(comments, "desat") | regexm(comments, "anaphylax")
	replace keep = 1 if regexm(comments, "intub") | regexm(comments, "arrest") | regexm(comments, "bipap")
drop if regexm(comments, "cancel") & mi(keep)

	// could use comments to create rrt_reason (e.g. cardiac, respiratory/airway, seizure, loc) at future time
drop keep comments disposition

* save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_2014.dta", replace
clear


// 2015 data
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_calls_2015.xlsx", sheet("Sheet1") firstrow case(lower)

* drop blank first row
generate count = _n
drop if count==1
drop count n-o whocalledact

* destring dates/times
	
	// rrt time
	generate rrt_number = _n
	gen rrt_date = regexs(1) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*)")
		replace rrt_date = regexr(rrt_date, "/[0-9]+$", "/15")
		replace rrt_date = "11/10/15" if rrt_number == 1388
		replace rrt_date = "1/26/15" if rrt_number == 113
		replace rrt_date = "7/19/15" if rrt_number == 849
		replace rrt_date = "9/17/15" if rrt_number == 1133
	drop if mi(rrt_date)
	
	gen rrt_time = regexs(2) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*[ ]*)([0-9][0-9][0-9][0-9]$)")
		replace rrt_time = regexs(0) if rrt_time=="" & regexm(datetime, "[0-9][0-9][0-9][0-9]$")
		replace rrt_time = regexs(1) if rrt_time=="" & regexm(datetime, "([0-9][0-9][0-9][0-9])([ ])$")	
		replace rrt_time = substr(rrt_time,1,2)+":"+substr(rrt_time,3,2)
		
	gen rrt_datetime = rrt_date + " " + rrt_time

	gen double rrt_datetime_2 = Clock(rrt_datetime, "MD20Yhm")  
		format rrt_datetime_2 %tC

	drop rrt_date rrt_time datetime rrt_datetime
	rename rrt_datetime_2 rrt_datetime

	// birthdate (may be useful for matching)
	* some birthdates mistakenly have year of 20xx instead of 19xx
	gen dob_2 = reverse(substr(reverse(dob),1,2)+"91"+substr(reverse(dob),5,(length(dob) - 4)))
		replace dob_2 = "" if dob_2 =="19"
		replace dob_2 = "09/02/1981" if regexm(dob, "//2/81")
		replace dob_2 = "" if regexm(dob, "none") | regexm(dob, "known")
	gen double birth_date = date(dob_2, "MD19Y")
	format birth_date %td
	drop dob*
	
	// discharge date
		replace dcdate = regexr(dcdate, "/[0-9]*14$", "/2015")
		replace dcdate = substr(dcdate, 6, .) if regexm(dcdate, "inpt")
	gen double dc_date = date(dcdate, "MD20Y")
	format dc_date %td
	drop dcdate	
	
* encode expired and alive_at_discharge dummy vars (all entries not mi or 1 are outpatients
preserve
tab alivedc expired, mi
keep if alivedc !="1" & alivedc !=""
restore
replace alivedc = "1" if alivedc !="1" & alivedc !=""

clonevar died = expired 
encode alivedc, gen(alive_at_discharge)
drop expired alivedc

* code?
generate rrt_into_code = .
	replace rrt_into_code = 1 if regexm(turnedintocode7, "Y")
	replace rrt_into_code = 0 if regexm(turnedintocode7, "N") | regexm(turnedintocode7, "n")
drop turnedintocode7

* encode categorical disposition variable
generate rrt_result = 1
	replace rrt_result = 2 if regexm(disposition, "CU") | regexm(disposition, "59")
	replace rrt_result = 2 if regexm(disposition, "CIU") | regexm(disposition, "8900")
	replace rrt_result = 1 if regexm(disposition, "non") 
	replace rrt_result = 3 if regexm(disposition, "Exp") | regexm(disposition, "orgue")
  	replace died = 1 if rrt_result ==3
	drop if regexm(disposition, "Conf")
label define rrt_result 1 "no change" 2 "ICU transfer" 3 "death"
label values rrt_result rrt_result
 
foreach var of varlist divisionarea-comments {
	gen Z=lower(`var')
	drop `var'
	rename Z `var'
}
 
generate rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(icu)") 
	replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(ccu)")
	replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(ou)")
	replace rrt_disposition = rrt_disposition + "00" if !mi(rrt_disposition)
	replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9][0-9]+)") & mi(rrt_disposition)

generate rrt_dispo = real(rrt_disposition)
drop rrt_disposition
	
* destring registration number (for matching)
destring registration, force generate(reg_number)
	format reg_number %12.0g
drop registration

* destring length of rrt
generate rrt_duration_hours = regexs(1) if regexm(actrntimethere, "([0-9]*)([ ]*[Hh])")
	
generate rrt_duration_min = regexs(1) if regexm(actrntimethere, "([0-9]*)([ ]*[Mm])")
	replace rrt_duration_min = regexs(2) if regexm(actrntimethere, "([r][s]*[ ]*)([0-9]*)") & rrt_duration_min == ""
	destring actrntimethere, force generate(check_number)
	replace rrt_duration_min = actrntimethere if check_number !=.
generate still_missing = 1 if mi(rrt_duration_min) & mi(rrt_duration_hours)
	replace rrt_duration_min = "38" if regexm(actrntimethere, "25-50")
	replace rrt_duration_min = "55" if regexm(actrntimethere, "55ish")
drop if regexm(actrntimethere, "cancel")
		
generate rrt_hours_numeric = real(rrt_duration_hours)
generate rrt_min_numeric = real(rrt_duration_min)
	replace rrt_min_numeric = . if rrt_min_numeric==0
mvencode *_numeric, mv(0)
generate rrt_hours_to_min = 60*rrt_hours_numeric
generate rrt_duration = rrt_hours_to_min + rrt_min_numeric
	replace rrt_duration = . if rrt_duration==0
drop rrt_hours* rrt_min* rrt_duration_* actrntimethere check_number still_missing

* destring time from act to icu arrival
generate hours_to_icutx = regexs(1) if regexm(timefromacttoicuarrivalicu, "([0-9]*)([ ]*[Hh])") & rrt_result ==2
	
generate minutes_to_icutx = regexs(1) if regexm(timefromacttoicuarrivalicu, "([0-9]*)([ ]*[Mm])")
	replace minutes_to_icutx = regexs(2) if regexm(timefromacttoicuarrivalicu, "([r][s]*[ ]*)([0-9]*)") & minutes_to_icutx == ""
	destring timefromacttoicuarrivalicu, force generate(check_number)
	replace minutes_to_icutx = timefromacttoicuarrivalicu if check_number !=. & minutes_to_icutx == ""
	replace minutes_to_icutx = "10" if regexm(timefromacttoicuarrivalicu, "10") & minutes_to_icutx == ""
	replace minutes_to_icutx = "40" if regexm(timefromacttoicuarrivalicu, "40") & minutes_to_icutx == ""

generate hours = real(hours_to_icutx)
generate minutes = real(minutes_to_icutx)
	replace minutes = . if minutes==0
mvencode hours minutes, mv(0)
generate hours_to_min = 60*hours
generate time_from_rrt_to_icutx = hours_to_min + minutes
	replace time_from_rrt_to_icutx = . if time_from_rrt_to_icutx==0
drop check_number timefromacttoicuarrivalicu hours* minutes*

* rrt location
generate unit = regexs(1) if regexm(divisionarea, "([0-9]*00)([.]*)")
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(ou)")
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(pcu)")
	replace unit = "1" if regexm(divisionarea, "vir") | regexm(divisionarea, "ct") 
	replace unit = "1" if regexm(divisionarea, " us ") | regexm(divisionarea, "endosc")
	drop if mi(unit) & mi(rrt_dispo) & rrt_result !=2
	replace unit = "1" if regexm(divisionarea, "mall")
	replace unit = "1" if mi(unit) & rrt_result ==2

generate room = regexs(2) if regexm(divisionarea, "([r][m][ ]*)([0-9]*)")
	replace room = regexs(2) if regexm(divisionarea, "([R]*[m][ ]*)([0-9]*)") & mi(room)
	
generate ward = real(unit)
generate room_no = real(room)
	replace room_no = 0 if mi(room_no)
drop unit room
generate room = ward + room_no
drop room_no 
drop if mi(ward) & mi(room)
drop if disposition == "ed" | regexm(divisionarea, "nurs") | regexm(divisionarea, "fall")
drop if regexm(disposition, "home") | regexm(comments, "family member")

* clean up canceled calls (e.g., some say "cancelled for code")
generate keep = 1 if regexm(comments, "anes") | regexm(comments, "expire") | regexm(comments, "code")
	replace keep = 1 if regexm(comments, "icu") | regexm(comments, "hypo") | regexm(comments, "5900")
	replace keep = 1 if regexm(comments, "rvr") | regexm(comments, "desat") | regexm(comments, "anaphylax")
	replace keep = 1 if regexm(comments, "intub") | regexm(comments, "arrest") | regexm(comments, "bipap")
	replace keep = 1 if regexm(comments, "made comfort") | regexm(comments, "arrest") | regexm(comments, "bipap")

drop if regexm(comments, "cancel") & mi(keep)
drop if mi(rrt_dispo) & mi(rrt_duration)
	// could use comments to create rrt_reason (e.g. cardiac, respiratory/airway, seizure, loc) at future time
drop keep comments disposition

save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_2015.dta", replace
clear


// 2016 data
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_calls_2016.xlsx", sheet("Sheet1") firstrow case(lower)

* drop blank first row
generate count = _n
drop if count==1
drop count m-o

* drop outpatient calls sent to the ED
drop if disposition == "ed"

* remove case-sensitive letters
foreach var of varlist datetime-comments {
	gen Z=lower(`var')
	drop `var'
	rename Z `var'
}

* destring dates/times
	
	// rrt time
	generate rrt_number = _n
	gen rrt_date = regexs(1) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*)")
		replace rrt_date = regexr(rrt_date, "/[0-9]+$", "/16")
		replace rrt_date = "7/7/16" if datetime == "7/7161633"
		replace rrt_date = "7/15/16" if datetime == "7/15 16 2101"
		replace rrt_date = "2/6/16" if rrt_number ==143
	drop if mi(rrt_date)

	gen rrt_time = regexs(2) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*[ ]*)([0-9][0-9][0-9][0-9]$)")
		replace rrt_time = regexs(0) if rrt_time=="" & regexm(datetime, "[0-9][0-9][0-9][0-9]$")
		replace rrt_time = regexs(1) if rrt_time=="" & regexm(datetime, "([0-9][0-9][0-9][0-9])([ ])$")	
		replace rrt_time = substr(rrt_time,1,2)+":"+substr(rrt_time,3,2)
		replace rrt_time = "00:05" if rrt_time == ":"
	
	gen rrt_datetime = rrt_date + " " + rrt_time

	gen double rrt_datetime_2 = Clock(rrt_datetime, "MD20Yhm")  
		format rrt_datetime_2 %tC

	drop rrt_date rrt_time datetime rrt_datetime
	rename rrt_datetime_2 rrt_datetime
	
	// birthdate (may be useful for matching)
	* some birthdates mistakenly have year of 20xx instead of 19xx
	gen dob_2 = reverse(substr(reverse(dob),1,2)+"91"+substr(reverse(dob),5,(length(dob) - 4)))
		replace dob_2 = "" if dob_2 =="19"
		replace dob_2 = "" if regexm(dob, "none") | regexm(dob, "known") | regexm(dob, "cancel")
	gen double birth_date = date(dob_2, "MD19Y")
	format birth_date %td
	drop dob*
	
	// discharge date
		replace dcdate = regexr(dcdate, "/[0-9]*15$", "/2016")
		replace dcdate = substr(dcdate, 6, .) if regexm(dcdate, "inpt")
	gen double dc_date = date(dcdate, "MD20Y")
	format dc_date %td
	drop dcdate	
	
* encode expired and alive_at_discharge dummy vars (all entries not mi or 1 are outpatients
preserve
tab alivedc expired, mi
keep if alivedc !="1" & alivedc !=""
restore
replace alivedc = "1" if alivedc !="1" & alivedc !=""
replace expired = "0" if expired !="1" & expired !=""

encode expired, gen(died) 
encode alivedc, gen(alive_at_discharge)
drop expired alivedc

* code?
generate rrt_into_code = .
	replace rrt_into_code = 1 if regexm(turnedintocode7, "Y")
	replace rrt_into_code = 0 if regexm(turnedintocode7, "N") | regexm(turnedintocode7, "n")
drop turnedintocode7

* encode categorical disposition variable
generate rrt_result = 1
	replace rrt_result = 2 if regexm(disposition, "cu") | regexm(disposition, "59")
	replace rrt_result = 2 if regexm(disposition, "ciu") | regexm(disposition, "8900")
	replace rrt_result = 2 if regexm(disposition, "84[0-9][0-9]") | regexm(disposition, "83[0-9][0-9]")
	replace rrt_result = 1 if regexm(disposition, "non") 
	replace rrt_result = 3 if regexm(disposition, "exp") | regexm(disposition, "morgue")
	drop if regexm(disposition, "conf")
label define rrt_result 1 "no change" 2 "ICU transfer" 3 "death"
label values rrt_result rrt_result
 
generate rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(icu)") 
	replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(ccu)")
	replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(ou)")
	replace rrt_disposition = rrt_disposition + "00" if !mi(rrt_disposition)
	replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9][0-9]+)") & mi(rrt_disposition)

generate rrt_dispo = real(rrt_disposition)
drop rrt_disposition
	
* destring registration number (for matching)
destring registration, force generate(reg_number)
	format reg_number %12.0g
drop registration

* destring length of rrt
generate rrt_duration_hours = regexs(1) if regexm(actrntimethere, "([0-9]*)([ ]*[Hh])")
	
generate rrt_duration_min = regexs(1) if regexm(actrntimethere, "([0-9]*)([ ]*[Mm])")
	replace rrt_duration_min = regexs(2) if regexm(actrntimethere, "([r][s]*[ ]*)([0-9]*)") & rrt_duration_min == ""
	destring actrntimethere, force generate(check_number)
	replace rrt_duration_min = actrntimethere if check_number !=.
generate still_missing = 1 if mi(rrt_duration_min) & mi(rrt_duration_hours)
	replace rrt_duration_min = "25" if regexm(actrntimethere, "104icu cover/25")
	replace rrt_duration_min = "160" if regexm(actrntimethere, "160")
	replace rrt_duration_min = "45" if regexm(actrntimethere, "45")
	replace rrt_duration_min = "5" if regexm(actrntimethere, "5, cancel")

drop if regexm(actrntimethere, "cancel")
		
generate rrt_hours_numeric = real(rrt_duration_hours)
generate rrt_min_numeric = real(rrt_duration_min)
	replace rrt_min_numeric = . if rrt_min_numeric==0
mvencode *_numeric, mv(0)
generate rrt_hours_to_min = 60*rrt_hours_numeric
generate rrt_duration = rrt_hours_to_min + rrt_min_numeric
	replace rrt_duration = . if rrt_duration==0
drop rrt_hours* rrt_min* rrt_duration_* actrntimethere check_number still_missing

* destring time from act to icu arrival
generate hours_to_icutx = regexs(1) if regexm(timefromacttoicuarrivalicu, "([0-9]*)([ ]*[Hh])") & rrt_result ==2
	
generate minutes_to_icutx = regexs(1) if regexm(timefromacttoicuarrivalicu, "([0-9]*)([ ]*[Mm])")
	replace minutes_to_icutx = regexs(2) if regexm(timefromacttoicuarrivalicu, "([r][s]*[ ]*)([0-9]*)") & minutes_to_icutx == ""
	destring timefromacttoicuarrivalicu, force generate(check_number)
	replace minutes_to_icutx = timefromacttoicuarrivalicu if check_number !=. & minutes_to_icutx == ""
	replace minutes_to_icutx = regexs(2) if regexm(timefromacttoicuarrivalicu, "([h][ ]*)([0-9]*)") & minutes_to_icutx == ""
	
generate hours = real(hours_to_icutx)
generate minutes = real(minutes_to_icutx)
	replace minutes = . if minutes==0
mvencode hours minutes, mv(0)
generate hours_to_min = 60*hours
generate time_from_rrt_to_icutx = hours_to_min + minutes
	replace time_from_rrt_to_icutx = . if time_from_rrt_to_icutx==0
drop check_number timefromacttoicuarrivalicu hours* minutes*

* rrt location
generate unit = regexs(1) if regexm(divisionarea, "([0-9]*00)([.]*)")
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(ou)")
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(pcu)")
	replace unit = "1" if regexm(divisionarea, "vir") | regexm(divisionarea, "ct") 
	replace unit = "1" if regexm(divisionarea, " us ") | regexm(divisionarea, "endosc")
	drop if mi(unit) & mi(rrt_dispo) & rrt_result !=2
	replace unit = "1" if regexm(divisionarea, "mall")
	replace unit = "1" if mi(unit) & rrt_result ==2

generate room = regexs(2) if regexm(divisionarea, "([r][m][ ]*)([0-9]*)")
	replace room = regexs(2) if regexm(divisionarea, "([R]*[m][ ]*)([0-9]*)") & mi(room)
	
generate ward = real(unit)
generate room_no = real(room)
	replace room_no = 0 if mi(room_no)
drop unit room
generate room = ward + room_no
drop room_no 

drop if mi(ward) & mi(room)

* clean up canceled calls (e.g., some say "cancelled for code")
generate keep = 1 if regexm(comments, "anes") | regexm(comments, "expire") | regexm(comments, "code")
	replace keep = 1 if regexm(comments, "icu") | regexm(comments, "hypo") | regexm(comments, "5900")
	replace keep = 1 if regexm(comments, "rvr") | regexm(comments, "desat") | regexm(comments, "anaphylax")
	replace keep = 1 if regexm(comments, "intub") | regexm(comments, "arrest") | regexm(comments, "bipap")
	replace keep = 1 if regexm(comments, "made comfort") | regexm(comments, "arrest") | regexm(comments, "bipap")

drop if regexm(comments, "cancel") & mi(keep)
drop if regexm(divisionarea, "nurs") | regexm(divisionarea, "fall") & mi(keep)
drop if regexm(disposition, "home") | regexm(comments, "family member") & mi(keep)

drop if regexm(comments, "not done") | regexm(comments, "mistake") | regexm(comments, "no info")

	// could use comments to create rrt_reason (e.g. cardiac, respiratory/airway, seizure, loc) at future time
drop keep comments disposition

save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_2016.dta", replace
clear


// 2017 data
import excel "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_calls_2017.xlsx", sheet("Sheet1") firstrow case(lower)

* remove case-sensitive letters
foreach var of varlist datetime-comments {
	gen Z=lower(`var')
	drop `var'
	rename Z `var'
}

* drop outpatient calls sent to the ED
drop if disposition == "ed"
drop form-x

* clean up canceled calls (e.g., some say "cancelled for code")
generate keep = 1 if regexm(comments, "anes") | regexm(comments, "expire") | regexm(comments, "code")
	replace keep = 1 if regexm(comments, "icu") | regexm(comments, "hypo") | regexm(comments, "5900")
	replace keep = 1 if regexm(comments, "rvr") | regexm(comments, "desat") | regexm(comments, "anaphylax")
	replace keep = 1 if regexm(comments, "intub") | regexm(comments, "arrest") | regexm(comments, "bipap")
	replace keep = 1 if regexm(comments, "made comfort") | regexm(comments, "arrest") | regexm(comments, "resp distress")

drop if regexm(comments, "cancel") & mi(keep)
drop if (regexm(divisionarea, "nurs") | regexm(divisionarea, "fall")) & mi(keep)
drop if (regexm(disposition, "home") | regexm(comments, "family member")) & mi(keep)
drop if regexm(comments, "not done") | regexm(comments, "mistake") | regexm(comments, "no info")

* code?
generate rrt_into_code = .
	replace rrt_into_code = 1 if regexm(turnedintocode7, "y")
drop turnedintocode7


* encode expired and alive_at_discharge dummy vars (all entries not mi or 1 are outpatients
preserve
tab alivedc expired, mi
keep if alivedc !="1" & alivedc !=""
restore
replace alivedc = "1" if alivedc !="1" & alivedc !=""
replace expired = "0" if expired !="1" & expired !=""

encode expired, gen(died) 
encode alivedc, gen(alive_at_discharge)
drop expired alivedc

* destring dates/times
	
	// rrt time
	generate rrt_number = _n
	gen rrt_date = regexs(1) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*)")
		replace rrt_date = regexr(rrt_date, "/[0-9]+$", "/17")
		replace rrt_date = "1/4/17" if datetime == "1//4/17 2126"
		replace rrt_date = "1/18/17" if datetime == "1/118/17 1141"
		replace rrt_date = "2/3/17" if datetime == "2/3 17 1400"
		replace rrt_date = "2/20/17" if datetime == "2/2/0/17 0434"
		replace rrt_date = "4/25/17" if datetime == "4/15/17 0624"
		replace rrt_date = "9/7/17" if datetime == "9/717"
	drop if mi(rrt_date)

	gen rrt_time = regexs(2) if regexm(datetime, "^([0-9]*/[0-9]*/[0-9]*[ ]*)([0-9][0-9][0-9][0-9]$)")
		replace rrt_time = regexs(0) if rrt_time=="" & regexm(datetime, "[0-9][0-9][0-9][0-9]$")
		replace rrt_time = regexs(1) if rrt_time=="" & regexm(datetime, "([0-9][0-9][0-9][0-9])([ ])$")	
		replace rrt_time = substr(rrt_time,1,2)+":"+substr(rrt_time,3,2)
		replace rrt_time = "04:28" if datetime == "10/6/17 0428/431"
	
	gen rrt_datetime = rrt_date + " " + rrt_time

	gen double rrt_datetime_2 = Clock(rrt_datetime, "MD20Yhm")  
		format rrt_datetime_2 %tC

	drop rrt_date rrt_time datetime rrt_datetime
	rename rrt_datetime_2 rrt_datetime
		
	// birthdate (may be useful for matching)
	* some birthdates mistakenly have year of 20xx instead of 19xx
	gen dob_2 = reverse(substr(reverse(dob),1,2)+"91"+substr(reverse(dob),5,(length(dob) - 4)))
		replace dob_2 = "" if dob_2 =="19" | dob_2=="19-"
		replace dob_2 = "" if regexm(dob, "none") | regexm(dob, "known") | regexm(dob, "cancel")
		replace dob_2 = "2/13/1997" if dob=="2/1397"
		replace dob_2 = "8/6/1952" if dob=="8/652"
		
	gen double birth_date = date(dob_2, "MD19Y")
	format birth_date %td
	drop dob*
	
	// discharge date
		replace dcdate = regexr(dcdate, "/[0-9]*15$", "/2016")
		replace dcdate = substr(dcdate, 6, .) if regexm(dcdate, "inpt")
	gen double dc_date = date(dcdate, "MD20Y")
	format dc_date %td
	drop dcdate	
	
* encode categorical disposition variable
generate rrt_result = 1
	replace rrt_result = 2 if regexm(disposition, "cu") | regexm(disposition, "59")
	replace rrt_result = 2 if regexm(disposition, "ciu") | regexm(disposition, "8900")
	replace rrt_result = 2 if regexm(disposition, "84[0-9][0-9]") | regexm(disposition, "83[0-9][0-9]")
	replace rrt_result = 1 if regexm(disposition, "non") 
	replace rrt_result = 3 if regexm(disposition, "exp") | regexm(disposition, "morgue")
	drop if regexm(disposition, "conf")
label define rrt_result 1 "no change" 2 "ICU transfer" 3 "death"
label values rrt_result rrt_result
 
generate rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(icu)") 
	replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(ccu)")
	replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9]+)(ou)")
	replace rrt_disposition = rrt_disposition + "00" if !mi(rrt_disposition)
	replace rrt_disposition = regexs(1) if regexm(disposition, "([0-9][0-9]+)") & mi(rrt_disposition)
	replace rrt_disposition = "8300" if rrt_disposition=="83"
	replace rrt_result = 1 if rrt_disposition=="163"
	
generate rrt_dispo = real(rrt_disposition)
drop rrt_disposition
	
* destring registration number (for matching)
replace registration = "" if registration == "none" | registration == "-"
destring registration, force generate(reg_number)
	format reg_number %12.0g
drop registration

* destring length of rrt
generate rrt_duration_hours = regexs(1) if regexm(actrntimethere, "([0-9]*)([ ]*[Hh])")
	
generate rrt_duration_min = regexs(1) if regexm(actrntimethere, "([0-9]*)([ ]*[Mm])")
	replace rrt_duration_min = regexs(2) if regexm(actrntimethere, "([r][s]*[ ]*)([0-9]*)") & rrt_duration_min == ""
	destring actrntimethere, force generate(check_number)
	replace rrt_duration_min = actrntimethere if check_number !=.
generate still_missing = 1 if mi(rrt_duration_min) & mi(rrt_duration_hours)
	replace rrt_duration_min = "90" if regexm(actrntimethere, "90ish")
drop if regexm(actrntimethere, "cancel")
		
generate rrt_hours_numeric = real(rrt_duration_hours)
generate rrt_min_numeric = real(rrt_duration_min)
	replace rrt_min_numeric = . if rrt_min_numeric==0
mvencode *_numeric, mv(0)
generate rrt_hours_to_min = 60*rrt_hours_numeric
generate rrt_duration = rrt_hours_to_min + rrt_min_numeric
	replace rrt_duration = . if rrt_duration==0
drop rrt_hours* rrt_min* rrt_duration_* actrntimethere check_number still_missing

* destring time from act to icu arrival
generate hours_to_icutx = regexs(1) if regexm(timefromacttoicuarrivalicu, "([0-9]*)([ ]*[Hh])") & rrt_result ==2
	
generate minutes_to_icutx = regexs(1) if regexm(timefromacttoicuarrivalicu, "([0-9]*)([ ]*[Mm])")
	replace minutes_to_icutx = regexs(2) if regexm(timefromacttoicuarrivalicu, "([r][s]*[ ]*)([0-9]*)") & minutes_to_icutx == ""
	destring timefromacttoicuarrivalicu, force generate(check_number)
	replace minutes_to_icutx = timefromacttoicuarrivalicu if check_number !=. & minutes_to_icutx == ""
	replace minutes_to_icutx = regexs(2) if regexm(timefromacttoicuarrivalicu, "([h][ ]*)([0-9]*)") & minutes_to_icutx == ""
	replace minutes_to_icutx = "15" if timefromacttoicuarrivalicu == "15 charted"
	
generate hours = real(hours_to_icutx)
generate minutes = real(minutes_to_icutx)
	replace minutes = . if minutes==0
mvencode hours minutes, mv(0)
generate hours_to_min = 60*hours
generate time_from_rrt_to_icutx = hours_to_min + minutes
	replace time_from_rrt_to_icutx = . if time_from_rrt_to_icutx==0
drop check_number timefromacttoicuarrivalicu hours* minutes*


* rrt location
generate unit = regexs(1) if regexm(divisionarea, "([0-9]*00)([.]*)")
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(ou)")
	replace unit = regexs(1) if regexm(divisionarea, "([0-9]*)(pcu)")
	replace unit = "1" if regexm(divisionarea, "vir") | regexm(divisionarea, "ct") 
	replace unit = "1" if regexm(divisionarea, " us ") | regexm(divisionarea, "endosc")
	drop if mi(unit) & mi(rrt_dispo) & rrt_result !=2
	replace unit = "1" if regexm(divisionarea, "mall")
	replace unit = "1" if mi(unit) & rrt_result ==2

generate room = regexs(2) if regexm(divisionarea, "([r][m][ ]*)([0-9]*)")
	replace room = regexs(2) if regexm(divisionarea, "([R]*[m][ ]*)([0-9]*)") & mi(room)
	
generate ward = real(unit)
generate room_no = real(room)
	replace room_no = 0 if mi(room_no)
drop unit room
generate room = ward + room_no
drop room_no 

drop if mi(ward) & mi(room)
	// could use comments to create rrt_reason (e.g. cardiac, respiratory/airway, seizure, loc) at future time
drop keep comments disposition

* save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_2017.dta", replace
clear

// merge
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_2014.dta", clear
append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_2015.dta""/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_2016.dta" "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_2017.dta"

drop rrt_number
gen unique_rrt_id = _n

ren rrt_datetime time

// save big file
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_data_all.dta", replace

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

// check for duplicates
duplicates tag time_minutes room, gen(dups)
sample 1 if dups > 0, count by(time_min room reg_number)
drop dups

// prep for merging
gen rrt01 = 1

gen eventdate = dofc(time)
format eventdate %td

gen age = (eventdate - birth_date)/365.25
	replace age=floor(age)
	
drop eventdate

save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_north_2014_2017.dta", replace


