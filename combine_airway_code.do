* ==============================================================================
*
* this do-file combines airway calls and code calls and finishes cleaning
*
* datasets used: - codes_north_2014_2017.xlsx
*				 - anesth_airway_north_2014_2017.xlsx
*
* output dataset: - codes_airways_north_2014_2017.dta
*
* ==============================================================================


// open data and merge
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/codes_north_2014_2017.dta", clear
merge 1:1 time_minutes reg_number room using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/anesth_airway_north_2014_2017.dta"
drop _merge dups

// create dummy outcome variables
gen cart01 = 1 if code_number !=.
gen airway01 = 1 if airway_number !=.

// clean up extra vars
drop airway_number code_number
order time_minutes ward room cart01 airway01 code_result airway_result code_death01 airway_death code_dispo airway_dispo airway_during_code

// create time_hours variable (to group airways/codes happening near-simultaneously)
	* want the first time an emergency happens... everything after that should bundle together
gen double time_hours = 60*60000 * floor(time / (60 * 60 * 1000))
format %tC time_hours

sort time
gen time_catch = time_hours[_n] - time_hours[_n-1] if room[_n] == room[_n-1]
	replace time_hours = time_hours[_n-1] if time_catch == 3600000
drop time_catch
egen id=group(time_hours room)
order id time time_minutes time_hours room ward cart01 airway01 

// fill code/airway "events" with missing data when available
sort time
foreach v of varlist cart01-reg_number {
	bysort id: carryforward `v', replace
	bysort id: egen `v'_2 = min(`v')
	drop `v'
}
renvars *_2, postdrop(2)
ren airway_death airway_death01

// *_ result, *_death, and *_dispo should be the same for each id
	replace code_result = airway_result if mi(code_result)
	replace airway_result = code_result if mi(airway_result)
	replace code_death = airway_death if mi(code_death)
	replace airway_death = code_death if mi(airway_death)
	replace code_dispo = airway_dispo if mi(code_dispo)
	replace airway_dispo = code_dispo if mi(airway_dispo)
	* preserve
	* keep if airway_* = code_*
	* restore
	* id = 88 has different *_result (05jul2014 12:31:00)
		* checked on _code and _airway sheets... patient went to 8900, then died
	replace code_result = 2 if id == 88
	replace code_death01 = . if id==88
	replace airway_death01 = . if id==88
	
// consolidate events	
gen event_death01 = 1 if code_death01 ==1 | airway_death01 == 1
gen event_result = code_result 
	replace event_result = airway_result if mi(event_result)
gen event_dispo = code_dispo
	replace event_dispo = airway_dispo if mi(event_dispo)

// clean up variables and labels
drop code_death airway_death code_result airway_result code_dispo airway_dispo airway_during_code
label define event_result 1 "no change" 2 "ICU transfer" 3 "death" 4 "cath/OR"
label values event_result event_result

// drop duplicates by taking the first time for each id
bysort id (time): egen double first_time = min(time)
gen min_marker = 1 if time == first_time
keep if min_marker == 1
drop first_time min_marker

duplicates tag time_minutes reg_number room, gen(dups)
tab dups, mi
sample 1 if dups > 0, count by(time_minutes reg_number room)
drop dups

// save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/codes_airways_north_2014_2017.dta", replace

// merge with RRTs
merge 1:1 time_minutes reg_number room using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_north_2014_2017.dta"
drop _merge

// clean up vars
drop id unique_rrt_id

// re-do time_hours with RRTs
replace time_hours = 60*60000 * floor(time / (60 * 60 * 1000))
format %tC time_hours

sort time
gen time_catch = time_hours[_n] - time_hours[_n-1] if room[_n] == room[_n-1]
	replace time_hours = time_hours[_n-1] if time_catch == 3600000
drop time_catch
egen id=group(time_hours room)
order id time time_minutes time_hours room ward rrt01 cart01 airway01 

// fill "events" with missing data when available by the hourlong "ID"
sort time
foreach v of varlist reg_number age {
	bysort id: carryforward `v', replace
	bysort id: egen `v'_2 = min(`v')
	drop `v'
}
renvars *_2, postdrop(2)

	replace event_death = died if mi(event_death)
	replace event_result = rrt_result if mi(event_result)
	replace event_dispo = rrt_dispo if mi(event_dispo)
	replace event_dispo = event_dispo * 100 if event_dispo <=104
drop if event_dispo == 800
drop if mi(time)
drop died rrt_result rrt_dispo rrt_into_code

// only group RRTs with code/airways within 30 minutes (all count as first moment)
drop time_hours time_minutes id

gen double time_30 = 30*60000 * floor(time / (30 * 60 * 1000))
format %tC time_30

sort time
gen time_catch = time_30[_n] - time_30[_n-1] if room[_n] == room[_n-1]
gen time_interval = time[_n] - time[_n-1] if time_catch !=0
	replace time_30 = time_30[_n-1] if time_interval <= 1800000
egen outcome_id=group(time_30 room)
order outcome_id time room ward rrt01 cart01 airway01 
drop time_catch time_interval time_30

// re-fill 30 minute events
sort time
order age, before(divisionarea)
foreach v of varlist rrt01-airway01 birth_date-age {
	bysort outcome_id: carryforward `v', replace
	bysort outcome_id: egen `v'_2 = min(`v')
	drop `v'
}
renvars *_2, postdrop(2)

drop event_death *_date alive

// delete duplicate observations by keeping first occurance only
bysort outcome_id (time): egen double first_time = min(time)
gen min_marker = 1 if time == first_time
keep if min_marker == 1
drop first_time min_marker
duplicates tag outcome_id reg_number room, gen(dups)
tab dups, mi
sample 1 if dups > 0, count by(outcome_id reg_number room)
drop dups
drop divisionarea

gen double time_minutes=1000*floor(time/1000)
format time_minutes %tC


// save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/rrt_codes_airways_north_2014_2017.dta", replace

// merge with master file on time and room, then sort by time and room
