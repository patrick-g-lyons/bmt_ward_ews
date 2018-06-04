* ==============================================================================
*
* this do-file cleans and combines laboratory data
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
set more off



// labs
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/labs.dta", clear


// destring dates/times
gen double time = Clock(collect_tmstp, "YMDhms#")
format time %tC
drop collect_tmstp

// drop unncessary variables
drop proc_res_desc test_res_desc abnormal_flag reference_range

// hematologic labs: hemoglobin, WBC, ANC, platelets, INR, PTT

* hemoglobin
generate test_ = "hemoglobin" if regexm(test_desc, "HGB")
replace test_ = "" if regexm(test_desc,"URINE") | regexm(test_desc,"ELECTROPHORESIS") | regexm(test_desc,"VARIANT")

* platelet
replace test_ = "platelet" if regexm(test_desc, "PLATELET_COUNT_P3")

* WBC
replace test_ = "wbc" if regexm(test_desc, "WBC]_COUNT_P")

* ANC
replace test_ = "pct_neutrophil" if regexm(test_desc, "NEUTROPHIL_BAND_COUNT_P3") | regexm(test_desc, "NEUTROPHIL_COUNT_P3-30540") | regexm(test_desc,"NEUTROPHIL_COUNT_AUTO")
replace test_ = "anc" if regexm(test_desc, "P3-30541Y")


// metabolic panel

* sodium
replace test_ = "sodium" if regexm(test_desc, "SODIUM_MEASUREMENT_BLOOD_P3") | regexm(test_desc, "SODIUM_MEASUREMENT_P3")

* potassium
replace test_ = "potassium" if regexm(test_desc, "POTASSIUM")
replace test_ = "" if regexm(test_desc,"URINE") | regexm(test_desc,"FECAL")

* chloride
replace test_ = "chloride" if regexm(test_desc, "CHLORIDE")
replace test_ = "" if regexm(test_desc,"URINE") | regexm(test_desc,"FECAL")

* bicarb
replace test_ = "bicarbonate" if regexm(test_desc, "CO2]_MEASUREMENT_TOT")

* bun
replace test_ = "bun" if regexm(test_desc, "BUN]_MEASUREMENT")

* creatinine
replace test_ = "creatinine" if regexm(test_desc, "CREATININE_MEASUREMENT")
replace test_ = "" if regexm(test_desc,"URINE") | regexm(test_desc,"FLUID")

* albumin
replace test_ = "albumin" if regexm(test_desc, "ALBUMIN_MEASUREMENT_P3-71260")
 
* total_protein
replace test_ = "total_protein" if regexm(test_desc, "PROTEIN_MEASUREMENT_PLASMA_P3-7392AY")

* sgot
replace test_ = "sgot" if regexm(test_desc, "SGOT")

* sgpt
replace test_ = "sgpt" if regexm(test_desc, "SGPT")

* bili_total
replace test_ = "bili_total" if regexm(test_desc, "BILIRUBIN_MEASUREMENT_TOTAL_P3")
 
* alk_phos
replace test_ = "alk_phos" if regexm(test_desc, "ALKALINE_PHOSPHATASE_MEASUREMENT")

* magnesium
replace test_ = "magnesium" if regexm(test_desc, "MAGNESIUM_MEASUREMENT_SERUM")

* calcium
replace test_ = "calcium" if regexm(test_desc, "CALCIUM_MEASUREMENT_NOS")

* phosphate
replace test_ = "phosphate" if regexm(test_desc, "PHOSPHORUS_MEASUREMENT_PLASMA")

* glucose
replace test_ = "glucose" if regexm(test_desc, "GLUCOSE_MEAS")
replace test_ = "" if regexm(test_desc,"URINE") | regexm(test_desc,"FLUID")

// blood gas data

* arterial_o2
replace test_ = "arterial_o2" if regexm(test_desc, "OXYGEN")
replace test_ = "" if (regexm(test_desc, "OXYGEN") & regexm(test_desc,"VENOUS")) | regexm(test_desc,"LITERS")

* arterial_co2
replace test_ = "arterial_co2" if regexm(test_desc, "CO2") & regexm(test_desc, "ARTER")

* venous_co2
replace test_ = "venous_co2" if regexm(test_desc, "CO2") & regexm(test_desc, "VENOUS")

* arterial_ph
replace test_ = "arterial_ph" if regexm(test_desc, "PH_MEASUREMENT_ARTERIAL")

* venous_ph
replace test_ = "venous_ph" if regexm(test_desc, "PH_MEASUREMENT_VENOUS_BLOOD")


// coagulation data

* prothrombin_time
replace test_ = "prothrombin_time" if regexm(test_desc, "PT]_P3-10570")

* inr
replace test_ = "inr" if regexm(test_desc, "P3-11161Y")

* ptt
replace test_ = "ptt" if regexm(test_desc, "PTT]_ACT")


// lactate
replace test_ = "lactate" if regexm(test_desc, "LACTIC_ACID_MEASUREMENT")
replace test_ = "" if regexm(test_desc,"CEREBROSPINAL") | regexm(test_desc,"FLUID")


// ck
replace test_ = "creatine_kinase" if regexm(test_desc,"CK]_MEASUREMENT")


// troponin
replace test_ = "troponin" if regexm(test_desc,"TROPON")


// ldh
replace test_ = "ldh" if regexm(test_desc,"P3-G864BY")


// uric acid
replace test_ = "urate" if regexm(test_desc,"URIC_ACID_MEASUREMENT_P3-74200")


// remove unneeded labs
drop if test_ ==""


// destring result values
generate value = real(result_value)


// drop values reporting text (e.g. "not done")
generate keep = .
	replace keep = 1 if regexm(result_value, ">") | regexm(result_value, "<")
	drop if mi(value) & mi(keep)


// extract values after < or > 
gen extract = regexs(2) if mi(value) & (regexm(result_value, "(>)([0-9]*[.]*[0-9]*)"))
	replace extract = regexs(2) if extract=="" & mi(value) & (regexm(result_value, "(<)([0-9]*[.]*[0-9]*)"))
	replace value = real(extract) if mi(value)
	replace value = 150 if mi(value)


// remove duplicates to permit reshaping
duplicates tag encounter time test_, generate(dups)
tab dups, missing
* 3% duplicate values, most due to ambiguous selection of results and potassium/wbk

replace test_ = "pct_bands" if regexm(test_desc, "BAND")
drop if regexm(test_, "arterial_") & regexm(unit_of_measure, "%")
drop if regexm(test_, "venous_") & regexm(unit_of_measure, "%") 
drop if regexm(test_, "arterial_") & regexm(unit_of_measure, "MMOL")
drop if regexm(test_, "venous_") & regexm(unit_of_measure, "MMOL") 
drop if regexm(test_desc, "OXYGEN_GRADIENT")
drop if dups > 0 & regexm(test_, "potassium") & regexm(test_desc, "PLASMA")
sample 1 if dups > 0, count by(encounter time test_)

// clean up vars
drop keep extract result_value unit_of_measure test_desc dups


// reshape wide
reshape wide value, i(encounter time) j(test_) string


// rename variables
renpfix value


// adjust anc and wbc (pct_neutrophil * wbc)
replace anc = ((pct_bands + pct_neutrophil)*wbc/100) if mi(anc)
drop pct_bands pct_neutrophil

//save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/labs_wide_ews.dta", replace
********************************************************
