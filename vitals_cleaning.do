* ==============================================================================
*
* this do-file cleans and combines vital sign data
*
* datasets used: - II-440 Lyons North campus EWS project Vitals.txt
*
* output dataset: - vitals_wide.dta (primary output)
*				  - visit.dta (intermediate)
*				  - demographics.dta (intermediate)
*
* ==============================================================================

clear
set more off

// vitals
import delimited "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project Vitals.txt"

// rename common variables
ren report_vis encounter

// destring dates/times
gen double vs_time = Clock(vital_system_date, "YMDhms#")
format vs_time %tC
drop vital_system_date

// create measurement id for reshaping
generate meas_id = "dbp" if regexm(item_measured, "diastolic")
	replace meas_id = "sbp" if regexm(item_measured, "systolic")
	replace meas_id = "glucose_fingerstick" if regexm(item_measured, "Glucose")
	replace meas_id = "o2_flow" if regexm(item_measured, "flow")
	replace meas_id = "o2_mode" if regexm(item_measured, "mode")
	replace meas_id = "hr" if regexm(item_measured, "Pulse")
	replace meas_id = "rr" if regexm(item_measured, "Respir")
	replace meas_id = "temp" if regexm(item_measured, "Temp")
	replace meas_id = "weight" if regexm(item_measured, "Weight")
	replace meas_id = "height" if regexm(item_measured, "Height")
	replace meas_id = "sp_o2" if regexm(item_measured, "Saturation")
	replace meas_id = "bmi" if regexm(item_measured, "Mass")
	drop if mi(meas_id)

// remove duplicates to permit reshaping
duplicates tag encounter item_measured vs_time meas_id, generate(dups)
tab dups, missing
drop dups
* 110 duplicates, all from one encounter / all look physiologic / take "least optimal" from all categories
drop if encounter == 17879 & mi(measurement)
drop if encounter == 17879 & meas_id == "dbp" & measurement !=72
drop if encounter == 17879 & meas_id == "sbp" & measurement !=103
drop if encounter == 17879 & meas_id == "hr" & measurement !=135
drop if encounter == 17879 & meas_id == "rr" & measurement !=28
drop if encounter == 17879 & meas_id == "temp" & measurement !=36.4
drop if encounter == 17879 & meas_id == "sp_o2" & measurement !=91
duplicates tag encounter vs_time meas_id, generate(dups)
tab dups, missing
sample 1 if dups > 0, count by(encounter meas_id vs_time)
drop dups
encode meas_id, gen(meas_id_2)
drop meas_id
rename meas_id_2 meas_id

// reshape wide
reshape wide item_measured measurement, i(encounter vs_time) j(meas_id)

// rename variables
drop item_measured1 item_measured3 item_measured4 item_measured6 item_measured7 
drop measurement7 item_measured8 item_measured10 item_measured12 
rename measurement1 bmi
rename measurement2 dbp
rename item_measured2 dbp_type
rename measurement3 gluclose_fingerstick
rename measurement4 height_cm
rename measurement5 hr
rename item_measured5 hr_type
rename measurement6 o2_flow
rename measurement8 rr
rename item_measured9 sbp_type
rename measurement9 sbp
rename measurement10 sp_02
rename item_measured11 temp_type
rename measurement11 temp
rename measurement12 weight_kg
rename vs_time time

// clean up odd values
replace hr = . if regexm(hr_type, "fetal")
drop *_type

// save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/vitals_wide.dta", replace

********************************************************
