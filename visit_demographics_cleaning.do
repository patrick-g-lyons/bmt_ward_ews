* ==============================================================================
*
* this do-file cleans and combines visit-level and patient-level data
*
* datasets used: - II-440 Lyons North campus EWS project Visit Times.txt
*				 - II-440 Lyons North campus EWS project Demographics.txt
*
* output dataset: - visit_demographics.dta (primary output)
*				  - visit.dta (intermediate)
*				  - demographics.dta (intermediate)
*
* ==============================================================================

clear
// visit
import delimited "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project Visit Times 20180524.txt"

// rename common variables
ren report_pat patient
ren report_vis encounter

// drop unneeded variables
drop facility*

// destring dates/times
gen double admit_datetime = Clock(admit_date, "YMDhms#")
format admit_datetime %tC

gen double discharge_datetime = Clock(discharge_date, "YMDhms#")
format discharge_datetime %tC

drop admit_date discharge_date

// destring discharge disposition
gen d=lower(discharge_disposition)
	drop discharge_disposition
	rename d discharge_disposition

generate discharge_dispo = .
	replace discharge_dispo = 1 if regexm(discharge_disposition, "home") | regexm(discharge_disposition, "ama") | regexm(discharge_disposition, "op servic")
	replace discharge_dispo = 2 if regexm(discharge_disposition, "nursing") | regexm(discharge_disposition, "rehab")
	replace discharge_dispo = 2 if regexm(discharge_disposition, "term")
	replace discharge_dispo = 3 if regexm(discharge_disposition, "hospice")
	replace discharge_dispo = 4 if regexm(discharge_disposition, "expired")
	replace discharge_dispo = 99 if regexm(discharge_disposition, "bjh") | regexm(discharge_disposition, "still") 
	replace discharge_dispo = 99 if regexm(discharge_disposition, "none")
	replace discharge_dispo = 99 if mi(discharge_dispo)

	label define discharge 1 "home" 2"SNF/rehab/LTACH" 3 "hospice" 4 "died" 99 "other"
	label values discharge_dispo discharge
		
	// create dead01
	generate dead01 = 1 if regexm(discharge_disposition, "expired")

	drop discharge_disposition

// add count variables to match patient ages to encounters when merged
bysort patient (admit_datetime): gen count = _n
bysort patient: gen num_admits = _N
	
// save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/visit.dta", replace
clear

********************************************************************************

// demographics
import delimited "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project Demographics.txt"

// rename common variables
ren report_pat patient

// destring gender
generate female = 1 if gender =="F"
replace female = 0 if gender =="M"
drop gender

// destring race
generate race2=1 if race=="Caucasian"
	replace race2=2 if regexm(race, "Black")
	replace race2=3 if regexm(race, "Asian")
	replace race2=5 if race=="Unknown" 
	replace race2=4 if mi(race2)
label define race 1 "white" 2 "black" 3 "asian" 4 "other" 5 "unknown" 
label values race2 race
drop race
rename race2 race

// destring elixhauser comorbidities
renpfix elix_

foreach v of varlist congestive_heart_failure - depression {
	gen elix_`v' = 1 if `v' == "Y"
	replace elix_`v' = 0 if `v' != "Y"
	drop `v'
}

// some patients appear >1x, due to >1x encounters (tho enc var != here)
duplicates tag patient, gen(dups)
tab dups, mi
drop dups

// reshape age height weight --> 1 observation per patient now
ren pat_age age
ren height height
ren weight weight

bysort patient (age): gen count = _n
reshape wide age height weight, i(patient) j(count)

//save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/demographics.dta", replace
clear

********************************************************************************

// merge visit and demographics
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/visit.dta", clear

merge m:1 patient using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/demographics.dta"
drop _merge

renvars age1 - weight1, postdrop(1)
foreach v of varlist age-weight {
	replace `v'2 = . if `v' == `v'2
	replace `v'3 = . if `v' == `v'3
	replace `v'4 = . if `v' == `v'4
}

// address mismatched age/height/weight (e.g. 2 options for 5 hospitalizations)
	// assign first and last hospitalizations to first/last available options
	// then match "easy" patients where # hospitalizations = # options
	// fill in remaining missing variables by time intervals between visits & midpoints
	// remove extra age/height/weight vars

* age
gen num_ages = 1

	// howold should be the same when only 1 enc or count == 1
	gen howold = age if mi(age2) | count == 1

	// next make changes when # encounts = # ages 
	gen easy_age_fix = 1 if num_ages == num_admits

	forvalues i = 2(1)4 {
		replace num_ages = `i' if age`i' !=.
		replace howold = age`i' if mi(howold) & easy_age_fix == 1 & count==`i'
	}
	drop easy_age_fix
	
	// next replace howold with max age at last encounter
	forvalues i = 2(1)4 {
		replace howold = age`i' if mi(howold) & count == num_admits & num_ages == `i'
	}

	// use a # of days gap to adjust the next ages
	quietly sum num_admits, det
	return list
	local max_admits=r(max)
	forvalues i = 1(1)`max_admits' {
		gen day_gap`i' = ((admit_datetime[_n]-admit_datetime[_n-`i']) / 86400000) if patient[_n] == patient[_n-`i']
	}
	
	bysort patient (admit_datetime): gen index = 1 if _n==1
	bysort patient (admit_datetime): gen distance_from_index = _n-1
	gen bump_age =.
	
	quietly sum num_admits, det
	return list
	local max_admits=r(max)
	forvalues i = 1(1)`max_admits' {
		replace bump_age = 1 if distance_from_index == `i'& day_gap`i' > 365 
	}
	
	bysort patient (admit_datetime): gen bump_sum = sum(bump_age)
	
	// if no bump_sum for a patient, use the midpoint to increase age
	bysort patient: egen max_bump = max(bump_sum)
	bysort patient (admit_datetime): gen mid = num_admits/2
		replace mid=round(mid, 1)
		
		replace howold = age4 if count >= mid & mi(howold)
		replace howold = age3 if count >= mid & mi(howold)
		replace howold = age2 if count >= mid & mi(howold)

		replace howold = age2 if day_gap1 >= 365 & mi(howold)
		replace howold = age if day_gap1 < 365 & mi(howold)

	drop day* age* bump* max_bump index distance mid
	ren howold age

* height (should not change significantly from visit to visit)
forvalues i = 2(1)4 {
	replace height = height`i' if mi(height)
	drop height`i'
}

* treat weight like age
gen num_weights = 1

	// howold should be the same when only 1 enc or count == 1
	gen howheavy = weight if mi(weight2) | count == 1

	// next make changes when # encounts = # weights 
	gen easy_weight_fix = 1 if num_weights == num_admits

	forvalues i = 2(1)4 {
		replace num_weights = `i' if weight`i' !=.
		replace howheavy = weight`i' if mi(howheavy) & easy_weight_fix == 1 & count==`i'
	}
	drop easy_weight_fix
	
	// next replace howheavy with max weight at last encounter
	forvalues i = 2(1)4 {
		replace howheavy = weight`i' if mi(howheavy) & count == num_admits & num_weights == `i'
	}

	// use a # of days gap to adjust the next weights
	quietly sum num_weights, det
	return list
	local max_admits=r(max)
	forvalues i = 1(1)`max_admits' {		
		gen day_gap`i' = ((admit_datetime[_n]-admit_datetime[_n-`i']) / 86400000) if patient[_n] == patient[_n-`i']
	}
	
	bysort patient (admit_datetime): gen index = 1 if _n==1
	bysort patient (admit_datetime): gen distance_from_index = _n-1
	gen bump_weight =.
	
	quietly sum num_weights, det
	return list
	local max_admits=r(max)
	forvalues i = 1(1)`max_admits' {	
		replace bump_weight = 1 if distance_from_index == `i'& day_gap`i' > 365 
	}
	
	bysort patient (admit_datetime): gen bump_sum = sum(bump_weight)
	
	// if no bump_sum for a patient, use the midpoint to increase weight
	bysort patient: egen max_bump = max(bump_sum)
	bysort patient (admit_datetime): gen mid = num_admits/2
		replace mid=round(mid, 1)
		
		replace howheavy = weight4 if count >= mid & mi(howheavy)
		replace howheavy = weight3 if count >= mid & mi(howheavy)
		replace howheavy = weight2 if count >= mid & mi(howheavy)

		replace howheavy = weight2 if day_gap1 >= 365 & mi(howheavy)
		replace howheavy = weight if day_gap1 < 365 & mi(howheavy)

	drop day* weight* bump* max_bump index distance mid count num*
	ren howheavy weight

// check for duplicates
duplicates tag encounter, gen(dups)
tab dups, mi
drop dups
	* no duplicates!
	
replace dead01 = 0 if mi(dead01)	
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/visit_demographics.dta", replace
