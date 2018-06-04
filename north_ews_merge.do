* ==============================================================================
*
* this do-file merges and cleans patient-level, visit-level, and time-stamped data
*
* datasets used: - vitals_wide.dta
*				 - labs_wide_ews.dta
*				 - meds_shrunk.dta
*				 - line_tubes.dta
* 				 - visit_demographics.dta
*				 - room.dta
*				 - diagnosis_wide.dta
*
* output dataset: - north_merge.dta.dta (primary output)
* 				  - vitals_labs_meds_proc.dta (intermediate)
*
* ==============================================================================

set more off
clear

// merge data
	* need to avoid using m:m merge --> led to room assignment problems

// start by combining vitals and labs
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/vitals_wide.dta", clear
append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/labs_wide_ews.dta"

	// many simultaneous readings are separate obs due to milisecond differences
	gen double time2=1000*floor(time/1000)
	format time2 %tC

	foreach v of varlist bmi-wbc {
		bysort encounter time2: egen `v'_2 = max(`v')
		drop `v'
		}

	renvars bmi_2-wbc_2, postdrop(2)
	
	duplicates tag encounter time2-wbc, gen(dups)
	sample 1 if dups > 0, count by(encounter time2)
	drop dups time2	
	* drops 4.1mil observations, leaving 4.5mil

// add medications
append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/meds_icu_defining_final.dta"

// add lines and tubes
append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/lines_tubes.dta"
compress

// add cultures? right now this can be left out -- but it's APPEND, not m:m


// save this time-stamped data
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/vitals_labs_meds_proc.dta", replace
clear

// now start from patient-level data
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/visit_demographics.dta"
merge 1:m encounter using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/room.dta"
drop _merge

merge 1:m encounter time using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/vitals_labs_meds_proc.dta", 
drop _merge

// expand encounter-level data to all observations in the encounter
renvars elix_*, postdrop(2)
foreach m of varlist patient admit_datetime-weight {
	bysort encounter (time): egen `m'_2 = min(`m')
	drop `m'
	renvars `m'*, postdrop(2)
}
format *datetime %tC

// carry forward room start/end times separately
bysort encounter (time): carryforward room_start_time, replace
bysort encounter (time): carryforward room_end_time, replace
	replace room_end_time = discharge_datetime if mi(room_end_time)
* if there are still missing room_end_times after data update, next step: replace room_end_time == max(time), by(enc) 

// update loc_cat and icu status based on meds and vent
bysort enc (time): carryforward startstop, gen(start_2)
	replace icu_status=1 if start_2 == 1

		replace vent_in = -1 if vent_out == 1
bysort enc (time): carryforward vent_in, replace
	replace vent_in = . if vent_in == -1
	
	replace icu_status = 1 if vent_in == 1
	
	replace loc_cat = 3 if icu_status == 1
	
// carryforward variables except vs and labs so info is complete before merging outcomes
	* need complete room info, especially
foreach a of varlist loc_cat-room bmi height_ weight_ {
	bysort encounter (time): carryforward `a', replace
}

gsort enc -time
foreach b of varlist bmi height_ weight_ {
	bysort encounter: carryforward `b', replace
}
sort enc time

// room_end_time should always be <= discharge_datetime (but some ppl stay in room p d/c order)
generate problem = 1 if room_end_time > discharge_datetime
tab problem, mi
	* 1017 observations in abbreviated dataset
generate check = minutes(discharge_datetime-room_end_time) if problem==1
histogram check
	* most of these are by just a few min/hours
bysort encounter (time): egen needs_new_dc_time = min(problem)
bysort encounter (time): egen double maxtime_wholestay = max(time)
	replace discharge_datetime = maxtime_wholestay if needs_new_dc_time ==1

drop needs_new_dc_time maxtime_wholestay problem check

// add diagnosis data
merge m:1 encounter using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/diagnosis_wide.dta"
* 83 encounters have no diagnoses - who are they?
gen no_cancer_dx = 1 if _merge == 1
* use no_cancer_dx to go back to diagnosis_wide and see if they are BMT donors or something else
drop _merge
compress

///////////////////////////////

// interval save

// add outcomes (won't have encounter #) using append

append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/codes_north_2014_2017.dta"

encounter	room_start_time		room_end_time		loc_cat	ward	room	time
7040		04nov2014 01:51:00	14nov2014 17:29:00	ward	5900	5909	14nov2014 16:56:39
															5900	5909	20dec2014 22:24:00 --> this person has the code
2792		23dec2014 15:36:00	23dec2014 15:36:00	ward	5900	5909	23dec2014 15:36:00
2792		23dec2014 15:36:00	23dec2014 15:36:00	ward	5900	5909	23dec2014 16:45:38
* where are the patients in this room in between nov 14 and dec 23? hopefully part of the full data set

* need to figure out how to expand encounter details for these people (see attempt below)
sort room time
foreach `vcarry' of varlist encounter-room_end_time bmi height_ weight_ {
	carryforward `vcarry' if encounter[_n-1] == encounter[_n+1], replace
}

sort room time
foreach `vcarry' of varlist patient-osa {
	carryforward `vcarry' if encounter[_n-1] == encounter[_n+1], replace
}
* how to deal with people who have an event outside their room (e.g. CT scanner)?
	* can they be manually matched to an encounter by age/gender/datetime?
* would it be easier to put outcomes in the room sheet, fitting them into windows?

// save final full version
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/north_merge.dta", replace
