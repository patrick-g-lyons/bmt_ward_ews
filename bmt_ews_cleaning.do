* ==============================================================================
*
* this do-file cleans all merged north-campus data and establishes a time series
*
* datasets used: - north_merge.dta
*
* output dataset: - north_merge_ts.dta (primary output)
*
* ==============================================================================

// carry forward location data
replace room = . if loc_cat==5
bysort encounter (time): carryforward loc_cat-room, replace

// clean up demoraphic variables

	// height, weight, bmi
	
	* height: missing about 146k instances --> 129k (1,034 encounters)
	* weight: missing about 842k instances --> 34,844 (264 encounters)
	* bmi: missing 130,103 (1,066 encounters after adjustments below)
	order bmi, after(weight)
	count if mi(height)
	count if mi(weight)
		replace height = height_ if mi(height)
		replace weight = weight_ if mi(weight)
	foreach vbmi in height weight {
		bysort encounter (time): carryforward `vbmi', replace
		}
			replace height = 100*sqrt(weight/bmi) if mi(height) & !mi(bmi)
			replace weight = bmi*((height/100)^2) if mi(weight)
	foreach vbmi in height-bmi {
		bysort patient: egen `vbmi'_2 = min(`vbmi')
			replace `vbmi' = `vbmi'_2 if mi(`vbmi')
		drop `vbmi'_2
		}
		replace bmi = weight/((height/100)^2) if mi(bmi)
	drop height_ weight_

	* generate bmi categorical variable
	generate bmi_cat=.
		replace bmi_cat=1 if bmi < 18.5
		replace bmi_cat=0 if (bmi > 18.5 & bmi < 25) | bmi == 18.5
		replace bmi_cat=2 if (bmi > 25 & bmi < 30) | bmi == 25
		replace bmi_cat=3 if (bmi > 30 & bmi < 40) | bmi == 30
		replace bmi_cat=4 if bmi > 40 | bmi == 40
	 
	sum height, det
	tab height if height<120 | height>220
	* 11,000 values are not physiologic
		replace height=. if height<120 | height>220
	bysort patient: egen height_2 = min(height)
		replace height = height_2 if mi(height)
	drop height_2

	sum weight, det
	tab weight if weight<30 | weight>225
	* 3,572 values are not physiologic
		replace weight=. if weight<30 | weight>225
	bysort patient: egen weight_2 = min(weight)
		replace weight = weight_2 if mi(weight)
	drop weight_2

	sum bmi, det
	tab bmi if bmi<10 | bmi>120
	* 11,000 values are not physiologic
		replace bmi=. if bmi<10 | bmi>120
	bysort patient: egen bmi_2 = min(bmi)
		replace bmi = bmi_2 if mi(bmi)
	drop bmi_2

	// age, race, and gender
	
	* age: no missing data, no outliers
	count if mi(age)
	sum age, det
	label variable age "Age, years"

	* create age^2
	generate age2 = age^2

	* female: 2 mi values (not recoverable, checked at patient level), 2.1 mil (45%)
	tab female, mi
	label variable female "Female sex"

	* race: no missing (80% of total observations are white... SAC paper is about 70%)
	tab race, mi
	label variable race "Race"

	// patient and encounter details
	* patient = 13,707
	unique patient

	* encounter = 21,502
	unique encounter

	* admit_datetime: no missing
	gen admit_check = 1 if mi(admit_datetime)
	tab admit_check, mi
	drop admit_check

	* discharge datetime: missing 52
	gen discharge_check = 1 if mi(discharge_datetime)
	tab discharge_check, mi	
	bysort encounter (time): egen maxtime_enc = max(time) if time !=.
	format maxtime_enc %tC
		replace discharge_datetime = maxtime_enc if mi(discharge_datetime)	
	drop discharge_check maxtime_enc	
		
// create ward definitions	

	// make ward dummy variable
	generate wards01 = 0
		replace wards01 = 1 if loc_cat == 2
		order wards01, after(loc_cat)

	// identify pre-ward location 
	generate loc_pre_ward=.
	bysort encounter (time): replace loc_pre_ward = loc_cat[_n-1] if wards01[_n]==1
		replace loc_pre_ward =. if loc_pre_ward ==2
	label values loc_pre_ward loc_cat	

	// generate ward time = first time on each ward unit
	generate double ward_time = room_start_time if wards01 ==1
	format ward_time %tC

	// generate ward_time_first = first time on any ward for each encounter (starts ward segment #1)
	bysort encounter: egen double ward_time_first = min(ward_time) if wards01==1
	format ward_time_first %tC

	// identify unique ward segments
	bysort encounter (time): generate ward_segment_indicator = 1 if wards01==1 & loc_cat[_n-1]!=2 
	bysort encounter (time): generate ward_seg_number = sum(ward_segment_indicator)
		replace ward_seg_number=. if wards01 !=1

	// generate source of ward admission (= loc_pre_ward for first ward stay)
	generate admit_source = loc_pre_ward if ward_seg_number ==1
	bysort enc (time): carryforward admit_source, replace
	label values admit_source loc_cat	

	
// icu transfers

	// identify icu transfers before 12-7-2015 by meds/vent 
	replace loc_cat=3 if icu_status == 1
	
// go back to meds and bring over ONLY time (start and stop), opioids, benzos, iv meds, icu_meds, icu_status, comfort care
	
		
// generate icu transfer variable and running number of icu transfers
bysort encounter (time): generate ward_icu_tf =1 if loc_cat==2 & loc_cat[_n+1]==3
bysort encounter (time): gen icu_transfer_number=sum(ward_icu_tf)
generate double w_icu_tx_time = room_start_time[_n+1] if ward_icu_tf==1
	format w_icu_tx_time %tC
	
// generate death = moment of last vs when dead01 == 1
order sbp hr rr sp_02 temp, after(dbp)
egen vitals_check = rowtotal(dbp-temp)

bysort encounter (time): egen double death_time = max(time) if dead01==1 & vitals_check !=0
bysort encounter (time): generate death = 1 if time==death_time & time!=.
	
gen ward_death = 1 if death==1 & loc_cat==2	
drop vitals_check

* location categories: 9,907 instances missing (many of which have zero information)
tab loc_cat wards, mi

egen vitals_sum = rowtotal(dbp-temp)
egen labs_sum = rowtotal(albumin-wbc)
gen tag = 1 if mi(room_start_time) & mi(loc_cat) & vitals_sum==0 & labs_sum==0
* check to confirm no outcomes or other info here - there is not on close review
preserve
keep if tag==1
sort pat enc tim
tab ward_icu_tf death, mi
restore

drop if tag==1
drop vitals_sum labs_sum tag
* now 7,227 observations remain, with NO outcomes or room/ward data, inlcuding start_time
* BUT these observations contain labs or vitals, so we'll keep them (leave missing for now)
preserve
keep if mi(loc_cat)
tab ward_icu_tf, mi
sum room, det
sum ward, det
sum room_start_time, det
restore

* wards01: all match loc_cat==2 (3.8 million observations)
tab wards01 loc_cat

* icu transfers = 2184 (1952 encounters)
tab loc_cat ward_icu_tf, mi
unique encounter if ward_icu_tf ==1


save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/north_merge.dta", replace

// vital signs: replace non-physio values==.
ren sp_02 sp_o2

	replace rr=. if rr>70 | rr<1
	replace hr=. if hr>300 | hr<1
	replace sbp=. if sbp>300 | sbp<30
	replace dbp=. if dbp<1 | dbp>250
	replace temp = 33.9 if temp==93
	replace temp = 35.6 if temp==96
	replace temp = 36.1 if temp==97
	replace temp=. if temp<32 | temp>44
	replace sp_o2=. if sp_o2<11 | sp_o2>100
		* note how many replacements occur: 

// lab variables: replace non-physio values==.

	* anc
	sum anc, det
		replace anc =. if anc > 30 & wbc < 10
		
	* hemoglobin
	sum hemoglobin, det
		replace hemoglobin =. if hemoglobin < 2
		
	* glucose
		replace glucose = glucose_fingerstick if mi(glucose)
		drop glucose_fingerstick
	sum glucose, det
		replace glucose = 1000 if glucose > 1000
		
* cancer diagnoses
foreach dx in varlist leukemia-osa {
	replace `dx' = 0 if mi(`dx')
}
	* lymphoma: 400k observations with elix_lymphoma but no ICD, 17k with ICD but no elix_
	* 3,228 hospitalizations with lymphoma
	* solid: 41k with elix_metastatic_cancer but no ICD for solid tumor, 82k for elix_solid but no ICD
	tab lymphoma elix_lymphoma, mi
	tab solid_tumor elix_metastatic_cancer, mi
	tab solid_tumor elix_solid_tumor_without_metasta, mi
	* 28922 encounters with leukemia
	unique enc if leukemia==1
	* 1395 encounters with BMT - per PW this looks right
	unique enc if bmt==1
	* 910 encounters with myeloma
	unique enc if myeloma==1
	* 0 encounters for bmt without corresponding cancer dx
	unique enc if bmt==1 & mi(leukemia) & mi(myeloma) & mi(lymphoma)

* other diagnoses
	* 22k with HIV by ICD but not elix, 1.3m with HIV by elix and not ICD
	tab elix_aids_h1v hiv_icd, mi

	* no TLS occurs in patients without cancer dx - good.
	tab tumor_lysis no_cancer_dx, mi
	
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/north_merge.dta", replace

// generate ventilator/dialysis/line/foley dummy variables
clonevar ventilator = vent_out
	replace ventilator = 1 if vent_in ==1

clonevar dialysis = dialysis_out
	replace dialysis = 1 if dialysis_in ==1

clonevar central_line = central_line_out
	replace central_line = 1 if central_line_in ==1

clonevar foley = foley_out
	replace foley = 1 if foley_in ==1

foreach var in ventilator-foley {

	bysort enc (time): carryforward `var', replace
	replace `var' = . if `var' == -1
}

drop *_in *_out

// encode missing dummy variables as 0
foreach vmi of varlist no_cancer ward_icu_tf dead01 death ward_death ventilator-foley {
	replace `vmi' = 0 if mi(`vmi')
}

save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/north_big.dta", replace


// create time since ward admission, resetting after each event
	* a patient can have multiple ward stays 2/2 ICU TF

* use index to ID final vital signs on each ward stay (last useable data point on wards)
	* don't use labs becuase they are drawn before they result
bysort enc (time): gen index=_n 
bysort enc: egen index_max=max(index) if rr!=. | hr!=. | sbp!=. | dbp!=. | temp!=.| sp_o2!=.

* create max_index and event_time for the last ward vital sign during each ward admission (allowing multple per patient)
	* event can be icu transfer, death, or discharge
bysort enc loc_cat icu_transfer_number (time): egen double max_ward_index=max(index) if rr!=. | hr!=. | sbp!=. | dbp!=. | temp!=.| sp_o2!=. 
bysort enc (time): gen double event_time=time if max_ward_index==index & rr!=. | hr!=. | sbp!=. | dbp!=. | temp!=.| sp_o2!=. & loc_cat==2
bysort enc (time): replace event_time=. if max_ward_index!=index
format event_time %tC

* create outcome variable (0=none, 1=ICU, 2=CA, 3=DNR death; outcomes w/in 24 hrs of CA counted only as arrest to make mutually exclusive)
gen outcome0123=0 if loc_cat==2
bysort enc (time): gen icutx = 1 if loc_cat[_n]==2 & loc_cat[_n+1]==3
replace outcome0123=1 if icutx==1 & loc_cat==2
* change ICU transfers and deaths within 24 hours of CA to 0, and then recoding them as arrests
*replace outcome0123=0 if ca_icu_timediff_hrs<24 & loc_cat==2
*replace outcome0123=2 if ca01==1 & loc_cat==2
replace outcome0123=2 if ward_death==1 & loc_cat==2

* ensure event_time is time of an event, based on the outcome definition above, which includes discharge time (e.g. currently, event time could be last ICU time)
bysort enc (time): replace event_time=. if outcome0123!=0
*bysort enc (time): replace event_time=. if ca_datetime_ms1!=.
bysort enc (time): replace event_time=time if outcome0123!=0 & outcome0123!=.
*bysort enc (time): replace event_time=time if dischg_disp==0 & index==index_max & loc_cat==2

* create variable for first time on ward for each ward stay
bysort enc icu_transfer_number: egen double min_time=min(time) if loc_cat==2
format min_time %tC

* for each ward stay, ID max time during ward stay
bysort enc min_time: egen double event_time_max=max(event_time)
format event_time_max %tC

* subtract last time on ward from current time to create time variable--> observations after arrest but before ICU transfer will be negative
gen double event_time_diff=event_time_max-time

* make time var, using t = 0 as first ward obs
gen time_ward=min_time-time if event_time_diff>=0 & event_time_diff!=. & loc_cat==2
gen time_ward_hours=hours(time_ward)*(-1) if event_time_diff>=0
sort enc time

* create variable to identify each type of event segment
bysort enc (time): gen event_segment_start=1 if time_ward_hours==0
bysort enc: replace event_segment_start=0 if event_segment_start==.
bysort enc (time): gen event_seg_number=sum(event_segment_start) if time_ward_hours!=.
bysort enc event_seg_number (time): egen event_seg_type=max(outcome0123) if time_ward_hours!=.

// create hospital los variable
bysort encounter (time): egen double first_ward_moment = min(time) if wards==1
bysort encounter (time): egen double maxtime_encounter = max(time)
gen los_hospital = maxtime_encounter-first_ward_moment
	drop first_ward_moment maxtime_encounter
 
// create icu los variable ((icu_transfer_number already exists))
 * need to id num_icu_stays per enc
 * make icu_los for each, then sum
 
 * bysort encounter icu_stay_number (time): egen double first_icu_momennt = min(time) if loc_cat==3
 * bysort encounter icu_stay_number (time): egen double last_icu_momennt = max(time) if loc_cat==3
 
 * forvalues i = 1(1)x {
 * 		gen icu_los_`i' = hours(last_icu_moment - first_icu_moment) if icu_stay_number == `i'
 * }
 *	
 * foreach v in varlist icu_los_1-icu_los_x {
 *  	bysort enc (time): egen `v'_2 = min(`v')
 *		drop `v'
 * 		renvars `v'*, postdrop(2)
 * }
 *
 * gen los_icu = rowtotal(icu_los_1-icu_los_x)
 * drop icu_los_* *_icu_moment
 
// create Elixhauser sum
egen elix_sum = rowtotal(elix_congestive_heart-elix_depressi)

// create age_squared variable for nonlinear age effects
gen age2 = age*age

// make central line duration running variable
bysort enc (time): gen cent_line_start = 1 if central_line==1 & central_line[_n-1] !=1
bysort enc (time): gen cent_line_start = sum(cent_line_start)
bysort encounter cent_line_count: egen double cent_line_start_time=min(time) if cent_line_count > 0 & central_line==1
bysort encounter cent_line_count (time): gen cvc_duration_hours = hours(time-cent_line_start_time) if cent_line_count > 0 & central_line==1
	replace cvc_duration_hours = 0 if mi(cvc_duration_hours)
drop cent_line_start cent_line_start cent_line_start_time
	
// make transpired LOS a predictor variable
bysort encounter (time): egen double first_non_ed_moment = min(time) if loc_cat !=1
bysort enc (time): gen transpired_los = days(time-first_non_ed_moment)
drop first_non_ed_moment

// make total transpired ICU days a predictor variable (icu_transfer_number already exists)
bysort enc (time): gen icu_stay_number = icu_transfer_number if loc_cat==3
	replace icu_stay_number = icu_stay_number + 1 if admit_source == 3
	replace icu_stay_number = 0 if mi(icu_stay_number)
bysort encounter icu_stay_number (time): egen double first_icu_moment = min(time) if loc_cat==3
bysort encounter icu_stay_number (time): egen double last_icu_moment = max(time) if loc_cat==3
bysort encounter icu_stay_number (time): gen icu_hours = hours(time-first_icu_moment) if loc_cat==3

gen prior_icu_hours = 0
quietly sum icu_stay_number, det
	return list
	local max_icu=r(max)
forvalues i = 1(1)`max_icu' {
	gen icu_los_`i' = hours(last_icu_moment - first_icu_moment) if icu_stay_number == `i'
	bysort enc (time): egen max_icu_los_`i' = min(icu_los_`i')
		replace icu_los_`i' = max_icu_los_`i' if mi(icu_los_`i')
		replace prior_icu_hours = (prior_icu_hours + icu_los_`i') if `i' <= icu_transfer_number & loc_cat !=3
		replace prior_icu_hours = (prior_icu_hours + icu_los_`i') if `i' < icu_transfer_number & loc_cat ==3
}
drop max_icu_los_*

gen running_icu_hours = prior_icu_hours
	replace running_icu_hours = running_icu_hours + icu_hours if loc_cat==3
	replace running_icu_hours = 0 if mi(running_icu_hours)

// make ICU LOS an outcome
bysort encounter: egen iculos_hours = max(running_icu_hours)

// make academic season (tertiles) a predictor variable (1 = 1st 3rd of academic year, 2 = 2nd...)
gen admit_month = month(dofC(admit_datetime))
	format admit_month %8.0f

gen season = 1 if admit_month >= 7 & admit_month <=10
	replace season = 2 if admit_month >= 11 | admit_month <=2
	replace season = 3 if admit_month >= 3 & admit_month <=6
	label variable season "Tertile of Acadmic Year"
	label define season 1 "July-October" 2 "November-February" 3 "March-June"
	label values season season	
	drop admit_month
	
// make time of day a predictor variable (0100-0700, 0700-1200, else; See Kipnis and Escobar)
gen time_of_day = 1 if hhC(time) >=1 & hhC(time) <7
	replace time_of_day = 2 if hhC(time) >=7 & hhC(time) <12
	replace time_of_day = 3 if mi(time_of_day)
	label variable time_of_day "Time of Day"
	label define time 1 "0100-0700" 2 "0700-1200" 3 "all other times"
	label values time_of_day time

// create icu readmission variable (might have duplicate variables from above - needs to be cleaned)
 
 * icu to ward transfer (@ time of last icu vital sign)
	bysort encounter (time): gen icu_ward=1 if loc_cat==3 & loc_cat[_n+1]==2
	bysort encounter (time): gen num_wardtfs=sum(icu_ward)
	bysort encounter num_wardtfs (time): gen double wardtf_time=time if icu_ward==1

	gen num_wardtfs2=num_wardtfs
		replace num_wardtfs2=num_wardtfs-1 if icu_ward==1
	drop num_wardtfs
	rename num_wardtfs2 num_wardtfs
	
 * make 72h bounceback outcome
	generate double ward_xfer_72=.
	format ward_xfer_72 %tC
		replace ward_xfer_72 = time + 259200000 if icu_ward==1
	bysort encounter_id (time): carryforward ward_xfer_72 if loc_cat==2, replace
	bysort encounter_id (time): gen bb_72=1 if wardICU==1 & icutf_time <= ward_xfer_72 & ward_xfer_72 !=.

 * extrapolate bb_48 and bb_72 by the segment (i.e. this is an ICU discharge for which there will be a bounceback)

	*** event segment number
	bysort encounter_id (time): gen index=_n 
	bysort encounter_id: egen index_max=max(index)
	bysort encounter_id loc_cat num_icutfs: egen double start_time=min(time)
	bysort encounter_id (time): gen segment_start=1 if start_time==time
	bysort encounter_id: gen event_seg_number=sum(segment_start)
	
	bysort encounter_id event_seg_number: egen bb72=min(bb_72)
	sort encounter_id time
		replace bb72=1 if icu_ward==1 & bb72[_n+1]==1
	
 * make composite outcome of ward death or ICU bounceback within 48h
	bysort encounter_id (time): gen composite_72=1 if bb_72==1 | (dead01==1 & icutf_time <= ward_xfer_72 & ward_xfer_72 !=.)

// make days since ICU discharge a predictor variable
bysort enc num_wardtfs (time): egen double segment_icuward_tf_time = min(wardtf_time)
bysort enc num_wardtfs (time): gen days_since_icu_discharge = days(time-segment_icuward_tf_time) if wards==1
	replace days_since_icu_discharge = transpired_los if mi(days_since_icu_discharge) & wards==1

// save as full coded non-imputed dataset
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/north_big.dta", replace

// carry forward missing vital sign variables
foreach v of varlist dbp-temp  {
bysort encounter (time): replace `v'=`v'[_n-1] if `v'==.
}

// carry forward missing lab variables
foreach v of varlist albumin-wbc  {
bysort encounter (time): replace `v'=`v'[_n-1] if `v'==.
}

// create additional vital sign/lab variables
bysort encounter (time): gen pulse_press=sbp-dbp
bysort encounter (time): gen pp_index=(sbp-dbp)/sbp
bysort encounter (time): gen shock_index=hr/sbp
bysort encounter (time): gen map=(2/3)*dbp + (1/3)*sbp
foreach v of varlist pp_index-map {
	replace `v'=round(`v', .0001)
}	
bysort encounter (time): gen anion_gap=(sodium-chloride-bicarbonate)
bysort encounter (time): gen bun_cr_ratio=bun/creatinine
replace bun_cr_ratio = round(bun_cr_ratio, .0001)
order pulse_press pp_index shock_index map, after(sp_o2)
order sbp, before(dbp)
order anion_gap bun_cr_ratio, after(wbc)

// tag duplicates across ALL variables here -- drop any dups
drop index
duplicates tag, gen(dups)
tab dups, mi
sample 1 if dups > 0
drop dups

// impute missing variables (using WARD MEDIAN VALUES, see Churpek 2014)
	* replace non-physiologic values==.for derived variables
	replace pp_index=. if pp_index<=0
	replace pulse_press=. if pulse_press<=0
	replace anion_gap=. if anion_gap <=0

		// check how many vitals are missing
		set more off
		log using "/Users/plyons/Dropbox/Research/BMT EWS/data cleaning/vitals_missing_`c(current_date)'.log", replace
		foreach v of varlist sbp-map {
		tab `v' if loc_cat==2, mi
		}	
		
		log close
			* vital signs: sbp 2.1%, dbp 2.2%, hr 2.4%, rr 1.8%, temp 2.3%, 1.9%
			* derived vitals: pulse pressure 2.1%, ppi 2.2%, shock index 2.4%, map 2.3%
			
		// check how many labs are missing
		log using "/Users/plyons/Dropbox/Research/BMT EWS/data cleaning/labs_missing_`c(current_date)'.log", replace
		foreach v of varlist albumin-bun_cr_ratio {
		tab `v' if loc_cat==2, mi
		}	
		
		log close
			* basic labs: cbc 6%, bmp 6%, lfts 15%, coags 17%
			* derived labs: bun_cr_ratio 6%, anion_gap 6%
			* advanced labs: anc 80%, pH 80%, ck 83%, lactate 68%, ldh 31%, trop 71%, urate 34%

		// make histograms to review distributions
		foreach var of varlist sbp-map {
			histogram `var'
			 more
			graph save histogram_`var', replace
			graph export histogram_`var'.png, replace
		}
		
	// imputation
	foreach v of varlist sbp-alk_phos arterial_co2-bun_cr_ratio {
	egen `v'_median=median(`v') if loc_cat==2
		replace `v'=`v'_median if `v'==. & loc_cat==2
	}

	drop *_median

	// imputing non-median values for some labs
	
	* anc --> 95th %ile
	quietly sum anc, det
	return list
	replace anc = r(p95) if mi(anc)

// generate composite outcome dummy variable
	replace outcome0123 = 0 if outcome0123==.
gen outcome01 = 1 if outcome0123 > 0 & outcome0123 !=.
	replace outcome01 = 0 if mi(outcome0123)
	replace outcome01=0 if outcome0123 ==0
	
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/north_big_imputed_medians.dta", replace

// create MEWS variables
gen temp_c=(temp-32)*5/9
gen mews_r_rr=cond(rr>29, 3, cond(rr>20, 2, cond(rr>14, 1, 0)))
gen mews_r_hr=cond(hr>129, 3, cond(hr>110, 2, cond(hr>100, 1, 0)))
gen mews_r_sbp=cond(sbp>=200, 2, 0)
gen mews_r_temp=cond(temp_c>=38.5, 2, 0)

gen mews_l_rr=cond(rr<=8,2,0)
gen mews_l_hr=cond(hr<40,2,cond(hr<=50,1,0))
gen mews_l_sbp=cond(sbp<70, 3, cond(sbp<=80, 2, cond(sbp<=100, 1, 0)))
gen mews_l_temp=cond(temp_c<35,2,0)
* order avpu, before(mews_r_rr) [if AVPU becomes avail]
 
egen mews_impute=rowtotal(mews_r_rr-mews_l_temp) 
	/// need to add back AVPU if available

bysort encounter event_seg_number: egen max_mews=max(mews_impute)
sort enc time

// neutropenia and duration of neutropenia (needs to be after values carried forward) // duration of neutropenia ~ D-index for predicting infection
generate neutropenia01 = 1 if anc <= 1.5
generate neutropenia_severity = 1 if anc <= 1.5 & anc >=1
	replace neutropenia_severity = 2 if anc < 1 & anc >= 0.5
	replace neutropenia_severity = 3 if anc < 0.5
	tab neutropenia01 neutropenia_severity

bysort enc (time): generate neutropenia_start = 1 if neutropenia01[_n]==1 & neutropenia01[_n-1] !=1
bysort enc (time): generate neutropenia_episode = sum(neutropenia_start)
 
generate double neutropenia_time = time if neutropenia01 == 1

bysort enc neutropenia_episode (time): egen double neutropenia_start_time = min(neutropenia_time)
 
gen neutropenia_duration_hours = hours(time-neutropenia_start_time)

foreach n in neutropenia01 neutropenia_severity neutropenia_duration {
	replace `n'* = 0 if mi(`n')
	}
drop neutropenia_time neutropenia_start_time


// neighborhood effect: anyone on the same ward has an event within 6h prior (do this before analysis time series is set)
	* recent_neighborhood_events is the covariate to use

	* make time var, using t = 0 as first obs on each unit for the whole cohort
	bysort ward (time enc): egen double min_unit_time = min(time)
	bysort ward (time): gen hours_since_neighborhood_opened = hours(time-min_unit_time)
	
	* identify maximum time on a ward
	bysort ward (time enc): egen double max_unit_time = max(hours_since_neighborhood_opened) 
	gen max_unit_6h = floor(max_unit_time/6)*6

	* create 6-hour time blocks per ward
	quietly sum max_unit_6h, det
		local max_unit=r(max)

	* make window6hr the time units of the neighborhood time series
	gen neighbor_6h=0 
	forvalues i=6(6)`max_unit' {
		bysort ward (time enc): replace neighbor_6h=`i' if hours_since_neighborhood_opened >`i'-6 & hours_since_neighborhood_opened <=`i' & `i'<=max_unit_6h 
		}
		
	bysort ward neighbor_6h (time): gen window6hr=neighbor_6h+6 if _n==_N 

	* create unique identifier for each time segment for each subject (= neighborhood_id)
	egen neighborhood_id=group(ward neighbor_6h)
		replace neighbor_6h=. if hours_since_neighborhood_opened>max_unit_6h
		replace window6hr =. if window6hr ==6
		replace window6hr = 6 if mi(window6hr) & neighbor_6h==0 & hours_since_neighborhood_opened==0
		
	* set as time series
	sort ward time 
	tsset ward window6hr, delta(6)
	
	* count the number of events in each neighborhood time window
	bysort neighborhood_id (time): gen number_neighborhood_events = sum(outcome01)
	bysort neighborhood_id (time): egen neighborhood_events = max(number_neighborhood_events)
	
	* identify number of events in the neighborhood's previous 6-hour window
	bysort neighborhood_id (time): egen double new_neighborhood_time = min(time)
	gen neighborhood_id_start = 1 if time==new_neighborhood_time
	generate recent_neighborhood_events = .
		bysort ward (time): replace recent_neighborhood_events = neighborhood_events[_n-1] if neighborhood_id_start ==1
	bysort ward (time): carryforward recent_neighborhood_events, replace
		
	* end this time series and re-sort data	
	tsset, clear
	sort encounter time

// apply tsset --> time series

	*** coding for 6-hour block s***
	bysort enc event_seg_number (time): egen maxtime_h=max(time_ward_hours)
	gen maxtime_6h=floor(maxtime_h/6)*6

	*** run the part below in the command line or an error might occur \\\ run all up to "replace" at once
		quietly sum maxtime_6h, det
		local maxtime=r(max)

		//create 6-hour blocks
		gen time6hrs=0 
		forvalues i=6(6)`maxtime' {
			bysort encounter event_seg_number: replace time6hrs=`i' if time_ward_hours >`i'-6 & time_ward_hours <=`i' & `i'<=maxtime_6h 
		}

		bysort encounter time6hrs event_seg_number (time): gen block6hr=time6hrs+6 if _n==_N 
			//keeping only the last vs per block

		* create unique encounter identifier for each time segment for each subject
		egen unique_segment_id=group(encounter event_seg_number)
	
		replace time6hrs=. if time_ward_hours>maxtime_6h
		replace block6hr =. if block6hr ==6
		replace block6hr = 6 if mi(block6hr) & time6h==0 & time_ward_hours==0
		
		sort encounter time
		tsset unique_segment_id block6hr, delta(6)
		tsfill

		** use unique_segment_id to see which patient the filled in data belongs to

		* pull forward missing values into newly created blocks
		* tagging filled in 
		gen filled6=0
		replace filled6=1 if time==.
		bysort unique_segment_id (block6hr): carryforward room_start_time-foley, replace
	
// delta values: Hb, glucose, HCO3, troponin, pH

	// abolute change from prior day (HCO3, Hb) or prior 6-hour window (glucose) /// windows chosen based on typical frequency of lab checks
	sort unique_segment_id block6hr (time)
	foreach var in bicarbonate hemoglobin {
		gen `var'_24h_difference = `var'-l4.`var' if enc==l4.enc & block6hr !=.
			replace `var'_24h_difference = 0 if mi(`var'_24h_difference) & block6hr !=.
			bysort unique_segment_id (block6hr): carryforward `var'_24h_difference, replace
	}
	
	gen glucose_24h_difference = glucose-l1.glucose if enc==l1.enc & block6hr !=.
		replace glucose_24h_difference = 0 if mi(glucose_24h_difference) & block6hr !=.
		bysort unique_segment_id (block6hr): carryforward glucose_24h_difference, replace	
	
	// mean over previous 4 values (4 days for most labs) // tssmooth ma `var'_ma_410 = `var', window(4 1 0)
	foreach var in bicarbonate hemoglobin {
		tssmooth ma `var'_ma_4days = `var', window(16 1 0)
	}
	
	tssmooth ma glucose_ma_1day = glucose, window(4 1 0)
	
	bysort unique_segment_id (block6hr): carryforward *day, replace

	// minimum prior to current value
	local deltavars bicarbonate hemoglobin glucose
	tsset
	
	foreach var in `deltavars' {
		rangestat (min) `var', interval(block6hr . 0) by(unique_segment_id)
	}
	
	// maximum prior to current
	foreach var in `deltavars' troponin {
			rangestat (max) `var', interval(block6hr . 0) by(unique_segment_id)
		}
	
	// exponential smoothing (s0 = x0, st = αxt + (1 − α)st−1) // want to minimize sum of squared residuals
	foreach var in `deltavars' {
		tssmooth exponential `var'_exp_smooth = `var'
	}

	// standard deviation over last 4 days (as a measure of variability) // impute a median when missing, rather than use the current value
	tsset
	
	foreach var in bicarbonate hemoglobin {
		tsegen `var'_sd = rowsd(l(0/16).`var')
		sum `var'_sd, det
			replace `var'_sd = r(p50) if mi(`var'_sd)
	}
	
	tsegen glucose_sd = rowsd(l(0/4).glucose)
	sum glucose_sd, det
		replace glucose_sd = r(p50) if mi(glucose_sd)
	
	// slope of change : xtreg y x, fe // predict p if t <=tm(_N) [for prior n variables] // OR try a regression, then ereturn list to get a slope local? _b[var] or help _variables
	foreach var in bicarbonate hemoglobin {
		rolling _b _se, window (16) clear: xtreg `var' (encounter)
	}
	
		rolling _b _se, window (4) clear: xtreg glucose (encounter)
	
	
	
// vital sign trends (we should a priori choose variables shown in lit to be predictive: max rr, sd rr, min spo2)
// for vs, use current + extreme + 24h slope
local vitals sbp dbp hr rr sp_o2 temp

	// absolute change from prior (leave out: not very predictive per Churpek, Mao, Escobar)
	
	// mean over previous day
	foreach var in `vitals' {
		tssmooth ma `var'_ma_1day = `var', window(4 1 0)
	}
	
	bysort unique_segment_id (block6hr): carryforward *_ma_1day, replace
	
	// minimum
	tsset
	
	foreach var in `vitals' {
		rangestat (min) `var', interval(block6hr . 0) by(unique_segment_id)
	}
	
	// maximum
	tsset
	
	foreach var in `vitals' {
		rangestat (max) `var', interval(block6hr . 0) by(unique_segment_id)
	}
	
	// standard deviation
	tsset
	
	foreach var in `vitals' {
		tsegen `var'_sd = rowsd(l(0/6).`var')
		sum `var'_sd, det
			replace `var'_sd = r(p50) if mi(`var'_sd)
	}
	
	// 24h slope
	tsset
	
	foreach var in `vitals' {
		rolling _b _se, window (6) clear: xtreg `var' (encounter)
	}
	
// should I be calculating LAPS? (PMID 23579354)

replace outcome0123=0 if mi(outcome0123)


save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/north_big_imputed_medians.dta", replace


// table 1
bysort enc (time): egen ever_outcome01 = max(outcome01)
bysort enc (time): egen ever_ward_death = max(ward_death)
 
  	* label variables
	label variable ever_outcome01 "Experienced composite outcome"
	label define ever_outcome 0 "Did not experience composite outcome" 1 "Experienced composite outcome"
	label values ever_outcome ever_outcome

	label variable bmi "Body Mass Index, kg/m2"	
	
	label define race 1 "Caucasian" 2 "Black / African-American" 3 "Asian" 4 "Other" 5 "Unknown" 
	label values race race
	
	label variable elix_congestive "Congestive heart failure"
	label variable elix_cardiac_arr "Arrhythmia"
	label variable elix_valvular "Valvular disease"
	label variable elix_pulmonary_c "Pulmonary circulation disorder"
	label variable elix_peripheral "Peripheral vascular disease"
	label variable elix_hypertension_unc "Uncomplicated hypertension"
	label variable elix_hypertension_com "Complicated hypertension"
	label variable elix_paralys "Paralysis"
	label variable elix_other_neur "Other neurologic disorder"
	label variable elix_chronic_pul "Chronic lung disease"
	label variable elix_diabetes_u "Uncomplicated diabetes"
	label variable elix_diabetes_c "Complicated diabetes"
	label variable elix_hypothyroid "Hypothyroidism"
	label variable elix_renal_f "Chronic kidney disease"
	label variable elix_liver "Liver disease"
	label variable elix_peptic "Peptic ulcer disease"
	label variable elix_aids "Human Immunodeficiency Virus infection / Acquired Immune Deficiency Syndrome"
	label variable elix_lympho "Lymphoma"
	label variable elix_metastatic "Metastatic solid tumor"
	label variable elix_solid "Solid tumor without metastasis"
	label variable elix_rheumatoid "Rheumatoid arthritis"
	label variable elix_coag "Coagulopathy"
	label variable elix_obes "Obesity"
	label variable elix_weight "Weight loss"
	label variable elix_fluid "Fluid / electrolyte disorder"
	label variable elix_blood "Blood loss anemia"
	label variable elix_deficie "Iron deficiency anemia"
	label variable elix_alcoho "Alcohol use disorder"
	label variable elix_drug "Drug abuse disorder"
	label variable elix_psych "Psychosis"
	label variable elix_depres "Depression"
	
 
preserve

sample 1, count by(encounter)

table_one ever_outcome01, med_vars(age bmi) cat_vars(female-elix_depres leukemia-solid osa admit_source season) title(auto_table_one.docx)

log using "/Users/plyons/Dropbox/Research/BMT EWS/data cleaning/varlist`c(current_date)'.log", replace
	describe, fullnames		
log close


restore

// finalize outcome variable
	* drop if block6hr==.
	** change outcom0123 to be used for q6hr coding; event_seg_type or outcome_0123 can be used to get it back to original
	gen outcome6_0123=0 
	bysort encounter event_seg_number (time): gen index6=_n if block6h!=.
	bysort encounter event_seg_number (time): egen max_index6=max(index6) if block6h!=.
	bysort encounter event_seg_number (block6hr): replace outcome6_0123=1 if event_seg_type==1 & index6==max_index6 & block6hr!=. & index!=.
	bysort encounter event_seg_number (block6hr): replace outcome6_0123=2 if event_seg_type==2 & index6==max_index6 & block6hr!=. & index!=.
	bysort encounter event_seg_number (block6hr): replace outcome6_0123=3 if event_seg_type==3 & index6==max_index6 & block6hr!=. & index!=.


// generate types of event segments
gen death_event_seg01=.
replace death_event_seg01=0 if event_seg_type==0
replace death_event_seg01=1 if event_seg_type==2

gen icu_event_seg01=.
replace icu_event_seg01=0 if event_seg_type==0
replace icu_event_seg01=1 if event_seg_type==1

gen combined_event_seg01=.
replace combined_event_seg01=0 if event_seg_type==0
replace combined_event_seg01=1 if event_seg_type>0 & event_seg_type!=.

gen combined_outcome01=0
replace combined_outcome=1 if outcome0123>0

// create 60:40 data split based on date (prospective validation)
xtile admdate_quint=admit_datetime if block6h==6 & event_seg_num==1, nquantiles(5)
bysort enc: egen min_admdate_quint=min(admdate_quint)
gen training_set01=0
replace training_set01=1 if min_admdate_quint<4















**Running models ###IF USING WITHIN 24 HOURS THEN NEED TO DROP tsfill OBS###

**MEWS
bysort enc event_seg_number: egen max_mews=max(mews_impute)

roctab ca_event_seg01 max_mews if training_set01==0 & block6h==6 
roctab ca_event_seg01 max_mews if training_set01==1 & block6h==6

**CART
gen cart_r_rr=cond(rr>29, 22, cond(rr>25, 15, cond(rr>23, 12, cond(rr>20, 8, 0))))
gen cart_r_hr=cond(hr>139, 13, cond(hr>109, 4, 0))
gen cart_r_age=cond(age>69, 9, cond(age>54, 4, 0))

gen cart_l_dbp=cond(dbp<35, 13, cond(dbp<40,6, cond(dbp<50,4,.)))

egen cart_impute=rowtotal(cart_r_rr-cart_l_dbp)

bysort encounter event_seg_number: egen max_cart=max(cart_impute)




















***Generating graphs for illustration purposes
gen combined_outcome8_01=0
replace combined_outcome8_01=1 if outcome8_0123>0

bysort sodium: egen prop_na=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
sum sodium if training_set01==1 & block8h!=., det
twoway bar prop_na sodium if training_set01==1 & block8h!=. & sodium>127 & sodium<146

bysort chloride: egen prop_cl=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
sum chloride if training_set01==1 & block8h!=., det
twoway bar prop_cl chloride if training_set01==1 & block8h!=. & chloride>90 & chloride<116

gen k10=potassium*10
gen round_k10=round(k10, 1)

bysort round_k10: egen prop_k=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
sum round_k10 if training_set01==1 & block8h!=., det
twoway bar prop_k round_k10 if training_set01==1 & block8h!=. & round_k10>30 & round_k10<54

bysort co2: egen prop_co2=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
sum co2 if training_set01==1 & block8h!=., det
twoway bar prop_co2 co2 if training_set01==1 & block8h!=. & co2>16 & co2<36

bysort anion_gap: egen prop_ag=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
sum anion_gap if training_set01==1 & block8h!=., det
twoway bar prop_ag anion_gap if training_set01==1 & block8h!=. & anion_gap>2 & anion_gap<17

bysort bun: egen prop_bun=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
sum bun if training_set01==1 & block8h!=., det
twoway bar prop_bun bun if training_set01==1 & block8h!=. & bun>3 & bun<51
twoway bar prop_bun bun if training_set01==1 & block8h!=. & bun>30 & bun<100

gen cr10=creatinine*10
gen round_cr10=round(cr10, 1)

bysort round_cr10: egen prop_cr=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
sum round_cr10 if training_set01==1 & block8h!=., det
twoway bar prop_cr round_cr10 if training_set01==1 & block8h!=. & round_cr10>4 & round_cr10<31
twoway bar prop_cr round_cr10 if training_set01==1 & block8h!=. & round_cr10>0 & round_cr10<11

bysort gluc_ser: egen prop_glc=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
sum gluc_ser if training_set01==1 & block8h!=., det
twoway bar prop_glc gluc_ser if training_set01==1 & block8h!=. & gluc_ser>65 & gluc_ser<265

gen cal10=calcium*10
gen round_cal10=round(cal10, 1)
bysort round_cal10: egen prop_cal=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
sum round_cal10 if training_set01==1 & block8h!=., det
twoway bar prop_cal round_cal10 if training_set01==1 & block8h!=. & round_cal10>70 & round_cal10<110

gen round_buncr=round(bun_cr_ratio, 1)
bysort round_buncr: egen prop_bun_cr_ratio=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_bun_cr_ratio round_buncr if training_set01==1 & block8h!=. & round_buncr>3 & round_buncr<40

gen wbc10=wbc*10
gen round_wbc10=round(wbc10, 1)
bysort round_wbc10: egen prop_wbc=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_wbc round_wbc10 if training_set01==1 & block8h!=. & round_wbc10>5 & round_wbc10<210

gen hb10=hb*10
gen round_hb10=round(hb10, 1)
bysort round_hb10: egen prop_hb=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_hb round_hb10 if training_set01==1 & block8h!=. & round_hb10>70 & round_hb10<160

bysort platelet_count: egen prop_plt=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_plt platelet_count if training_set01==1 & block8h!=. & platelet_count>50 & platelet_count<460

gen tp10=total_protein*10
gen round_tp10=round(tp10, 1)
bysort round_tp10: egen prop_tp=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_tp round_tp10 if training_set01==1 & block8h!=. & round_tp10>40 & round_tp10<82

gen alb10=albumin*10
gen round_alb10=round(alb10, 1)
bysort round_alb10: egen prop_alb=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_alb round_alb10 if training_set01==1 & block8h!=. & round_alb10>15 & round_alb10<50
twoway bar prop_alb round_alb10 if training_set01==1 & block8h!=. & round_alb10>44 & round_alb10<65

gen tbili10=bili_total*10
gen round_tbili10=round(tbili10, 1)
bysort round_tbili10: egen prop_tbili=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_tbili round_tbili10 if training_set01==1 & block8h!=. & round_tbili10>2 & round_tbili10<50
twoway bar prop_tbili round_tbili10 if training_set01==1 & block8h!=. & round_tbili10>40 & round_tbili10<100

bysort sgot: egen prop_ast=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_ast sgot if training_set01==1 & block8h!=. & sgot>10 & sgot<150

bysort sgpt: egen prop_alt=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_alt sgpt if training_set01==1 & block8h!=. & sgpt>10 & sgpt<250

bysort alk_phos: egen prop_ap=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_ap alk_phos if training_set01==1 & block8h!=. & alk_phos>50 & alk_phos<200

gen age_round=round(age, 1)
bysort age_round: egen prop_age=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_age age_round if training_set01==1 & block8h!=. & age_round>20 & age_round<85

bysort num_icustays: egen prop_icu=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_icu num_icustays if training_set01==1 & block8h!=. & num_icustays<6

bysort avpu: egen prop_avpu=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_avpu avpu if training_set01==1 & block8h!=. 

gen iculos10=icu_los_day*10
gen round_iculos10=round(iculos10, 1)
bysort round_iculos10: egen prop_iculos=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_iculos round_iculos10 if training_set01==1 & block8h!=. & round_iculos10<100

gen shock100=shocki*100
gen round_shock=round(shock100, 1)
bysort round_shock: egen prop_shock=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_shock round_shock if training_set01==1 & block8h!=. & round_shock<110 & round_shock>35

gen ppi100=ppi*100
gen round_ppi=round(ppi100, 1)
bysort round_ppi: egen prop_ppi=mean(combined_outcome8_01) if training_set01==1 & block8h!=.
twoway bar prop_ppi round_ppi if training_set01==1 & block8h!=. & round_ppi<75 & round_ppi>20


***Coding predictor variables (linear splines); use marginal option so testing of change in slope is done
gen icu_prior01=0
bysort study_id event_seg_number (block4hr): replace icu_prior=1 if num_icustays>0

***### Knots for illustration purposes only!!!
mkspline rr1 16 rr2 20 rr3=rr, marginal
mkspline hr1 51 hr2 99 hr3=hr, marginal
mkspline temp1 97 temp2 99.8 temp3=temp, marginal
mkspline ppi1 0.33 ppi2 0.53 ppi3=ppi, marginal
mkspline shock1 0.4 shock2 0.8 shock3=shocki, marginal
mkspline sbp1 100 sbp2 190 sbp3=sbp, marginal
mkspline dbp1 60 dbp2 84 dbp3=dbp, marginal    
mkspline o2sat1 92 o2sat2=o2sat, marginal

mkspline sodium1 135 sodium2 141 sodium3=sodium, marginal
mkspline k1 3.4 k2 4.2 k3=potassium, marginal
mkspline cl1 101 cl2 108 cl3=chloride, marginal
mkspline ag1 13 ag2=anion_gap, marginal
mkspline gluc1 80 gluc2 110 gluc3=gluc_ser, marginal
mkspline co2_1 27 co2_2 31 co2_3=co2, marginal
mkspline bun1 40 bun2=bun, marginal
mkspline cr1 0.4 cr2 0.8 cr3=creatinine, marginal
mkspline buncr1 20 buncr2=bun_cr_ratio, marginal
mkspline cal1 8.3 cal2 9.8 cal3=calcium, marginal

mkspline wbc1 3.4 wbc2 11 wbc3=wbc, marginal
mkspline plt1 150 plt2 350 plt3=platelet_count, marginal
mkspline hb1 8.5 hb2 13 hb3=hb, marginal

mkspline tp1 5.3 tp2 7.2 tp3=total_protein, marginal
mkspline albumin1 3 albumin2 4.7 albumin3=albumin, marginal
mkspline bili1 1.9 bili2=bili_total, marginal
mkspline ast1 37 ast2=sgot, marginal
mkspline alt1 50 alt2=sgpt, marginal
mkspline alkp1 120 alkp2=alk_phos, marginal

mkspline iculos1 1 iculos2=icu_los_day, marginal

mkspline age1 40 age2=age, marginal

gen time_ward_hours2=block4h-4
bysort unique_segment_id (time): carryforward time_ward_hours2, replace

gen time2=(time_ward_hours2)^2




***Real splines based on pre-defined cut-points
mkspline rr1 13 rr2 20 rr3=rr, marginal
mkspline hr1 49 hr2 100 hr3=hr, marginal
mkspline temp1 35.99999 temp2 37.99999 temp3=temp_c, marginal
mkspline ppi1 0.2499999 ppi2 0.55 ppi3=ppi, marginal
mkspline sbp1 100 sbp2 160 sbp3=sbp, marginal
mkspline dbp1 49 dbp2 85 dbp3=dbp, marginal    
mkspline o2sat1 92 o2sat2=o2sat, marginal

mkspline sodium1 133 sodium2 149 sodium3=sodium, marginal
mkspline k1 3.4 k2 5 k3=potassium, marginal
mkspline ag1 12 ag2=anion_gap, marginal
mkspline gluc1 59 gluc2 199 gluc3=gluc_ser, marginal
mkspline co2_1 22 co2_2=co2, marginal
mkspline bun1 20 bun2=bun, marginal
mkspline cr1 1.4 cr2=creatinine, marginal

mkspline wbc1 3.4 wbc2 11 wbc3=wbc, marginal
mkspline plt1 149 plt2 450 plt3=platelet_count, marginal
mkspline hb1 13.4 hb2 16 hb3=hb, marginal

mkspline albumin1 2.4 albumin2 4.4 albumin3=albumin, marginal
mkspline bili1 1.9 bili2=bili_total, marginal
mkspline ast1 37 ast2=sgot, marginal
mkspline alkp1 120 alkp2=alk_phos, marginal

mkspline numicu1 1 numicu2=num_icustays
mkspline age1 54.9999999 age2=age, marginal


stepwise, pr(0.157): logit combined_outcome8_01 time_ward_hours2 time2 avpu rr1-numicu2 bun_cr_ratio total_protein if training_set01==1 &  block8h!=., nolog


























 
 // extra code
bysort encounter_id event_seg_number (time): gen new_icu=1 if loc_cat2[_n]==2 & loc_cat2[_n-1]!=2
	bysort encounter_id (time): gen icu_stay_number=sum(new_icu) if loc_cat2==2
	bysort encounter_id icu_stay_number (time): gen double elap_lastObs=minutes(time-time[_n-1]) if !mi(icu_stay_number)
	bysort encounter_id icu_stay_number (time): gen double icu_los_min=sum(elap_lastObs)
	gen icu_los_day=icu_los_min/(60*24)
	foreach v of varl icu_los_min icu_los_day {
	bysort encounter_id icu_stay_number (time): replace `v'=`v'[_n-1] if mi(`v')
	}

	generate swift_iculos=.
	replace swift_iculos=0 if loc_cat==2 & icu_los_day < 2
	replace swift_iculos=1 if loc_cat==2 & (icu_los_day == 2 | icu_los_day==10)
	replace swift_iculos=1 if loc_cat==2 & icu_los_day > 2 & icu_los_day < 10
	replace swift_iculos=14 if loc_cat==2 & icu_los_day > 10

	/ based on maxtime_encounter (LOS = maxtime_encounter-time when icu_ward==1)	
	bysort encounter_id (time): egen double maxtime_encounter=max(time) if event_seg_number !=. 
	gen double post_icu_los_min = minutes(maxtime_encounter-time) if icu_ward==1 & maxtime_encounter !=.
	gen post_icu_los_day = post_icu_los_min/(60*24)
	
gen outcome = 1 if outcome0123 !=. & outcome!=0
replace outcome = 0 if outcome !=1
roctab outcome mews_impute if block6hr !=. & filled6 ==0, graph summary

// things to fix
*patient	encounter
*9788	21502 --> missing room_end_time for 5940 after moving from 5929 03mar2014 19:40:00
*9109	308 --> missing room_end_time after start 7900 04mar2015 20:29:00 
* these encounters' room times are not right - from 7900 to 5900, but the 7900 times don't copy... check on base sheet
patient	encounter
*13602	192 --> they were only ever in 7933
* this person had dialysis for 46 hours while on 7900... is there a room error from a carry forward, or a different issue (or can 7900 do sled?)
patient	encounter
*9109	308 --> they never left 7900 after this
* this person also had 24h dialysis sessions while on 7900


