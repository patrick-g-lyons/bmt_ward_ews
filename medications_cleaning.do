* ==============================================================================
*
* this do-file compiles & cleans medication orders and administrations
*
* datasets used: - Drug Administration 20180411 x.txt (x = 1-3)
*				 - Drug Orders.txt
*
* output dataset: - meds_shrunk_only_admins.dta.dta
* 				  - meds_shrunk.dta
*				  - meds_complete.dta
*				  - meds_icu_defining_final.dta (defines ICU stays + comfort pre 12/8/15)
*
* ==============================================================================

set more off
// import administration data set 1-33
clear
import delimited "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/II-440 Lyons North campus EWS project Drug Administration 20180411 1.txt"
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/med_admin_1.dta", replace
clear

import delimited "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/II-440 Lyons North campus EWS project Drug Administration 20180411 2.txt"
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/med_admin_2.dta", replace
clear

import delimited "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/II-440 Lyons North campus EWS project Drug Administration 20180411 3.txt"
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/med_admin_3.dta", replace

// combine administration data using APPEND
append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/med_admin_2.dta" "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/med_admin_1.dta"

// convert identification variables
ren report_vis encounter

// destring dates/times
gen double med_start_time = Clock(admin_start_tmstp, "YMDhms#")
format med_start_time %tC

gen double med_end_time = Clock(admin_end_tmstp, "YMDhms#")
format med_end_time %tC

// drop extra vars 
drop drug_id filler_application_code completion_status_source_code 
drop component_representative_nationa admin_start_tmstp admin_end_tmstp

// drop trailing blank spaces in generic_name and med_name
	gen new_name=strtrim(generic_name)
	drop generic_name 
	ren new_name generic_name
	
	gen med_name=strltrim(medication_source_code_desc)
	drop medication_source_code_desc

	gen gen=lower(generic_name)
	drop generic_name
	rename gen generic_name
	
// change variable names for appending with med orders
	ren total_dose_given_units_source_co dose_unit
	ren route_type_source_code drug_route
	ren total_dose_given_value dose_amount
	
// identify administered (versus ordered) medications
gen admin_not_just_order = 1
gen order_status = "administered"

// add add'l vars needed for appending with med orders
gen frequency_code = ""
gen frequency_modifier = ""
gen dose_quantity = ""
gen dose_quantity_units = ""
	
// save all administrations
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/med_admin_all.dta", replace
clear

********************************************************************************

// clean medication orders
import delimited "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project Drug Orders.txt"

// clean up variables
ren report_vis encounter
ren drug_name med_name
gen generic_name = lower(med_name)

drop ndc_code drug_id

// destring dates/times
gen double med_start_time = Clock(order_start_date, "YMDhms#")
format med_start_time %tC

gen double med_end_time = Clock(order_stop_date, "YMDhms#")
format med_end_time %tC

drop order_start order_stop

// add variables for appending to med administrations
gen admin_not_just_order = 0
ren dose_units dose_unit
tostring dose_quantity, replace
tostring dose_quantity_units, replace

save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/med_orders_all.dta", replace

********************************************************************************

// merge med administrations and orders using APPEND
append using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/med_admin_all.dta"

// add time variable
clonevar time = med_start_time
format time %tC

// clean medication dosage
destring dose_amount, gen(med_dose)
	replace med_dose = dose_amount_min if mi(med_dose)
	replace med_dose = dose_amount_max if mi(med_dose)
drop dose_amount dose_amount_min

// drop unneeded variables
drop dose_quan*
	
// destring route of administration into categorical variable
generate med_route=.
	replace med_route=1 if regexm(drug_route, "IV") | regexm(drug_route, "INJ")
	replace med_route=2 if regexm(drug_route, "ORAL") | regexm(drug_route, "PO")
	replace med_route=2 if drug_route == "NG"| regexm(drug_route, "TUBE")
	replace med_route=3 if regexm(drug_route, "DERM") | drug_route == "IM" 
	replace med_route=3 if drug_route == "SC" | regexm(drug_route, "TOP")
	replace med_route=3 if regexm(drug_route, "SUBCUT") | regexm(drug_route, "TOP")
	replace med_route=4 if drug_route == "SL" | regexm(drug_route, "RECT")
	replace med_route=4 if regexm(drug_route, "MUCOUS") | regexm(drug_route, "LINGUAL")
	replace med_route=5 if regexm(drug_route, "CRRT")

label define route 1 "IV" 2 "enteral" 3 "transdermal" 4 "mucus membrane" 5 "CRRT"
	label values med_route route	
drop if mi(med_route)
drop drug_route

// create iv_med dummy variable
generate iv_med=.
replace iv_med=1 if med_route==1

// use a crrt variable to ID patients on continuous dialysis (to ID ICU-level care)
generate crrt_from_meds = 1 if med_route == 5
	replace crrt = 1 if regexm(med_name, "NX")
	
// create categories of medications
	
	// generate benzodiazepine variable
	generate bzd=0
		replace bzd=1 if regexm(med_name, "OLAM")
		replace bzd=1 if regexm(med_name, "EPAM")
		replace bzd=1 if regexm(med_name, "ZEPOX")
		replace bzd=1 if regexm(med_name, "PATE")

	generate flumazenil = 1 if regexm(generic_name, "flumazenil") | regexm(med_name, "FLUMAZ")
		
	// create opioid variable
	generate narc=0
		replace narc=1 if regexm(med_name, "CODEINE")
		replace narc=1 if regexm(med_name, "MORPH") | regexm(generic_name, "morphine")
		replace narc=1 if regexm(med_name, "FENTANYL")
		replace narc=1 if regexm(med_name, "HYDRO")
		replace narc=1 if regexm(med_name, "OXY")
		replace narc=1 if regexm(med_name, "MEPERIDINE")
		replace narc=1 if regexm(med_name, "NALBUP")
		replace narc=1 if regexm(med_name, "TRAMADOL")
		replace narc=1 if regexm(med_name, "OPIUM")
		replace narc=1 if regexm(med_name, "METHADONE")
		replace narc=1 if regexm(med_name, "OXICODONE")

	generate narcan = 1 if regexm(med_name, "NARCAN") | regexm(med_name, "NALTREX")
		
	// create dummy variable for Ambien
	generate ambien=1 if regexm(med_name, "ZOLPID")
		replace ambien = 1 if regexm(generic_name, "zaleplon")

	// create antipsychotic category
	generate antipsychotic = 1 if regexm(med_name, "HALOPERIDOL") | regexm(med_name, "APINE")
		replace antipsychotic = 1 if regexm(med_name, "RISPER") | regexm(med_name, "SEROQ")
		replace antipsychotic = 1 if regexm(med_name, "ARIPIPRAZOLE")  | regexm(generic_name, "ziprasid")
		replace antipsychotic = 1 if regexm(med_name, "ARIPIPRAZOLE")  | regexm(generic_name, "thioridazine")
		replace antipsychotic = 1 if regexm(med_name, "ARIPIPRAZOLE")  | regexm(generic_name, "perphenazine")
		replace antipsychotic = . if regexm(med_name, "NEVIRAPINE")  

	// a few add'l meds were caught in the regexm
	drop if regexm(med_name, "ACETAZOLAMIDE")
	drop if regexm(med_name, "SCOPOLAMINE")
	drop if regexm(med_name, "PHENTOLAMINE")
	drop if regexm(med_name, "METHAZOLAMIDE")
	drop if regexm(med_name, "METOCLOPRAMIDE")
	drop if regexm(med_name, "THIAZIDE")
	drop if regexm(med_name, "ATROPINE")
	drop if regexm(med_name, "ALUMINUM")
	drop if regexm(med_name, "DICYCLOMINE")
	drop if regexm(med_name, "DOXEPIN")
	drop if regexm(med_name, "ESTROGEN")
	drop if regexm(med_name, "CHLORIDE")
	drop if regexm(med_name, "OXYBUTYNIN")
	drop if regexm(med_name, "HYDROXYZ")
	drop if regexm(med_name, "MAGNESIUM")
	drop if regexm(med_name, "PROGESTERONE")
	drop if regexm(med_name, "THEOPH")
	drop if regexm(med_name, "PHENOXY")
	drop if regexm(med_name, "UREA")
	drop if regexm(med_name, "PEROXIDE")
	drop if regexm(med_name, "DOXY")
	drop if regexm(med_name, "HYDROXYCHLOROQUINE")
		replace narc = 0 if regexm(med_name, "HYDROCORT")
		replace narc = 1 if regexm(med_name, "METHADONE")

	// generate abx categories
	generate antiviral = 1 if regexm(med_name, "ACYCLOVIR") | regexm(med_name, "CIDOFOVIR")
		replace antiviral = 1 if regexm(med_name, "FOSCARNET") | regexm(med_name, "GANC")
		replace antiviral = 1 if regexm(med_name, "OSELTAM") | regexm(med_name, "TAMIFL")
		replace antiviral = 1 if regexm(generic_name, "ganci") | regexm(generic_name, "foscarnet")
	* make labels for each, ask Jeff how to categorize (esp rx vs ppx)

	generate antifungal = 1 if regexm(med_name, "AMPHO") | regexm(med_name, "FUNGIN")
		replace antifungal = 1 if regexm(med_name, "CONAZOLE") | regexm(med_name, "ISAVUCONAZ")
		replace antifungal = 1 if regexm(generic_name, "conazo") | regexm(generic_name, "amphotericin")
		replace antifungal = . if regexm(med_name, "CAMPHOR-MENTHOL")
		
	generate antibiotic = 1 if regexm(med_name, "ICILLIN") | regexm(med_name, "^CEF")
		replace antibiotic = 1 if regexm(med_name, "AUGMENT") | regexm(med_name, "AVALOX")
		replace antibiotic = 1 if regexm(med_name, "AZITRHO") | regexm(med_name, "^CEPH")
		replace antibiotic = 1 if regexm(med_name, "FLOXACIN") | regexm(med_name, "ROMYCIN")
		replace antibiotic = 1 if regexm(med_name, "CLINDA") | regexm(med_name, "COLISTI")
		replace antibiotic = 1 if regexm(med_name, "MYCIN") | regexm(med_name, "Cefepime")
		replace antibiotic = 1 if regexm(med_name, "PENEM") | regexm(med_name, "MICIN")
		replace antibiotic = 1 if regexm(med_name, "LINEZOLID") | regexm(med_name, "ZYVOX")
		replace antibiotic = 1 if regexm(med_name, "CYCLINE") | regexm(med_name, "ZOSYN")
		replace antibiotic = 1 if regexm(med_name, "MACROBID") | regexm(med_name, "NITROFURAN")
		replace antibiotic = 1 if regexm(med_name, "QUINUPR") | regexm(med_name, "TRIMETHOPRIM")
		replace antibiotic = 1 if regexm(generic_name, "sulfamethoxazole") | regexm(med_name, "TRIMETHOPRIM")
		replace antibiotic = 1 if regexm(generic_name, "aztreonam") | regexm(generic_name, "tigecyc")
		replace antibiotic = 1 if regexm(generic_name, "doxyc") | regexm(generic_name, "cillin")
		replace antibiotic = 1 if regexm(generic_name, "metronidazole") | regexm(generic_name, "penem")
		replace antibiotic = 1 if regexm(generic_name, "daptomycin") | regexm(generic_name, " colisti")
		replace antibiotic = 1 if regexm(generic_name, "clindamycin") | regexm(generic_name, " ciprofloxacin")
		replace antibiotic = 1 if regexm(generic_name, "^cef") | regexm(generic_name, " azithromycin")	
		replace antibiotic = . if regexm(med_name,"BLEOMYCIN") | med_name == "DACTINOMYCIN"
		replace antibiotic = . if regexm(med_name,"DEMECLOCYCLINE") | regexm(med_name,"DOXORUBICIN")
		replace antibiotic = . if regexm(med_name,"BETAMETHASONE") 	 
		replace med_route = 1 if antibiotic==1 & regexm(med_name, "INJ")
		replace med_route = 1 if antibiotic==1 & regexm(med_name, "CEFEPIME")	
	
	// generate other meds of interest
	generate tpn = 1 if regexm(generic_name, "parenteral nutrition") | regexm(generic_name, "fat emulsion")
		replace tpn = 1 if regexm(generic_name, "intralipid")
	
	generate ppi = 1 if regexm(med_name, "RAZOLE")
		replace ppi = . if regexm(med_name, "ARIPIPRAZOLE") 

	generate h2_blocker = 1 if regexm(med_name, "TIDINE")
		replace h2 = . if regexm(med_name, "AZACITIDINE") 

	generate aed = 1 if regexm(med_name, "VALPRO") | regexm(med_name, "PHENYTO")
		replace aed = 1 if regexm(med_name, "KEPPRA") | regexm(med_name, "LACOSAMIDE")
		replace aed = 1 if regexm(med_name, "PHENOBARB") | regexm(generic_name, "zonisamide")
		replace aed = 1 if regexm(generic_name, "valproic") | regexm(generic_name, "topira")
		replace aed = 1 if regexm(generic_name, "phenobarbital") | regexm(generic_name, "oxcarbazepine")
		replace aed = 1 if regexm(generic_name, "lamotrigine") | regexm(generic_name, "clobazam")
		replace aed = 1 if regexm(generic_name, "phenytoin") | regexm(generic_name, "levetiracetam")
	* find aed_med by Ashley for this one

	generate gabapentin = 1 if regexm(med_name, "GABA")

	generate vasoactive = 1 if regexm(med_name, "EPHRIN") | regexm(med_name, "VASOPRES")
		replace vasoactive = 1 if regexm(med_name, "DOBUT") | regexm(med_name, "DOPAMINE")
		replace vasoactive = 1 if regexm(med_name, "ISOPRO") | regexm(med_name, "MILRINO")
		replace vasoactive = 1 if regexm(generic_name, "vasopressin") | regexm(generic_name, "epinephrine")
		replace vasoactive = 1 if regexm(generic_name, "milrinone") | regexm(generic_name, "epinephrine")
		replace vasoactive = . if regexm(med_name, "MISOPROST") | regexm(med_name, "CARISOPRODOL")

	generate insulin_gtt = 1 if regexm(generic_name, "insulin") & regexm(dose_unit, "HOUR")
		
	generate icu_med = 1 if regexm(med_name, "ESMOLOL") | regexm(med_name, "NITROPRU")
		replace icu_med = 1 if regexm(med_name, "CLEVID") | regexm(med_name, "NICARD")
		replace icu_med = 1 if regexm(med_name, "ETOM") | regexm(med_name, "MANNIT") 
		replace icu_med = 1 if regexm(med_name, "CISATRA") | regexm(med_name, "PROPOF")
		replace icu_med = 1 if regexm(med_name, "MIDAZOLAM INFUSION")
		replace icu_med = 1 if regexm(generic_name, "zemuron") | regexm(med_name, "succinylcholine")
		replace icu_med = 1 if regexm(generic_name, "esmolol") | regexm(med_name, "dobutamine")
		replace icu_med = 1 if insulin_gtt == 1 | regexm(generic_name, "cisatracurium")

	generate rasburicase = 1 if regexm(med_name, "RASBUR") | regexm(generic_name, "rasburicase")
	
	generate anticoag = 1 if regexm(generic_name, "warfarin") | regexm(generic_name, "enox")
		replace anticoag = 1 if generic_name == "heparin" | regexm(generic_name, "dabigatran")
		replace anticoag = 1 if generic_name == "apixaban"
												 
// create icu_status indicator (based on pressors, ICU meds, or CRRT... can add vent to it later once merged)
generate icu_status =1 if vasoactive == 1 | icu_med == 1 | crrt == 1

// create narcotic category
generate narcotic_name=.
	replace narcotic_name=1 if regexm(med_name, "MORPHINE") | regexm(generic_name, "morphine")
	replace narcotic_name=2 if regexm(med_name, "HYDROMORPHONE")
	replace narcotic_name=3 if regexm(med_name, "OXYC") | regexm(med_name, "OXICOD")
	replace narcotic_name=4 if regexm(med_name, "FENTANYL")
	replace narcotic_name=5 if regexm(med_name, "CODEINE")
	replace narcotic_name=6 if regexm(med_name, "HYDROCODONE")
	replace narcotic_name=7 if regexm(med_name, "MEPERIDINE")
	replace narcotic_name=8 if regexm(med_name, "OPIUM")
	replace narcotic_name=9 if regexm(med_name, "TRAMADOL")
	replace narcotic_name=10 if regexm(med_name, "METHADONE")
	replace narcotic_name=11 if regexm(med_name, "OXYMO")
label define narcs 1 "morphine" 2 "hydromorphone" 3 "oxycodone" 4 "fentanyl" 5 "codeine" 6 "hydrocodone" 7 "meperidine" 8 "opium" 9 "tramadol" 10 "methadone" 11 "oxymorphone"
label values narcotic_name narcs

// create benzodiazepine category
generate bzd_name=.
	replace bzd_name=1 if regexm(med_name, "ALPRAZOLAM")
	replace bzd_name=2 if regexm(med_name, "CHLORDIAZEPOX")
	replace bzd_name=3 if regexm(med_name, "CLONAZEPAM")
	replace bzd_name=4 if regexm(med_name, "DIAZEPAM")
	replace bzd_name=5 if regexm(med_name, "ESTAZOLAM")
	replace bzd_name=6 if regexm(med_name, "FLURAZEPAM")
	replace bzd_name=7 if regexm(med_name, "LORAZEPAM")
	replace bzd_name=8 if regexm(med_name, "MIDAZOLAM")
	replace bzd_name=9 if regexm(med_name, "TEMAZEPAM")
	replace bzd_name=10 if regexm(med_name, "TRIAZOLAM")
label define bzd 1 "alprazolam" 2 "chlordiazepoxide" 3 "clonazepam" 4 "diazepam" 5 "estazolam" 6 "flurazepam" 7 "lorazepam" 8 "midazolam" 9 "temazepam" 10 "triazolam"
label values bzd_name bzd

// drop some medications we don't need, based on funny dose units
tab dose_unit, mi

tab generic_name if regexm(dose_unit, "APP"), mi
	drop if regexm(dose_unit, "APP")
	* topical creams

tab generic_name if regexm(dose_unit, "CAP"), mi
	drop if regexm(dose_unit, "CAP") & antipsychotic !=1 & bzd !=1
	drop if regexm(generic_name, "pancrelipase") 
	* keep 2 olanzapine and benzos, but the rest are pancreatic enzymes and vitamins
	
	drop if regexm(dose_unit, "INCH")
	* drops nitro paste
	
	drop if regexm(dose_unit, "LOZ")
	* drops menthol lozenges
	
	drop if (regexm(dose_unit, "MEQ") | regexm(dose_unit, "MMOL")) & crrt !=1
	drop if regexm(dose_unit, "PACK") | regexm(generic_name, "potassium phosphate")
	* drops potassium/bicarb supplements and fluid replacements
	
	drop if regexm(dose_unit, "PATCH") 
	* only lidocaine patches here, not fentanyl
	
	drop if regexm(dose_unit, "SUPP") 
	drop if regexm(generic_name, "senna") | regexm(generic_name, "docus")
	drop if regexm(generic_name, "vitamin") | regexm(generic_name, "calcium carbonate")
	* suppositories and vitamins
	
	drop if regexm(generic_name, "pseudoephedrine") | regexm(generic_name, "estradiol")
	* decongestants and OCPs
	
	drop if regexm(dose_unit, "SPRAY") | regexm(dose_unit, "PUFF")
	* drops advair and throat sprays
	
// adjust medications where dose = "1 tab" or "2 patches" rather than "mg"
gen tab = 1 if regexm(dose_unit, "TAB") | regexm(dose_unit, "CAP")
	drop if generic_name=="" & tab == 1
	* drops some vitamins and study drugs
	
gen tab_value=regexs(2) if regexm(med_name, "([A-Z]*[ ])([0-9]+[.]*[0-9]*)([/][0-9]+)") & tab==1 & (narc==1 | bzd ==1)
	replace tab_value = "30" if regexm(med_name, "CODEINE") & tab==1
destring tab_value, replace

generate med_dose_2=med_dose 
	replace med_dose_2=med_dose*tab_value if tab==1 & narc==1
drop med_dose

rename med_dose_2 med_dose
	replace dose_unit="MG" if tab==1
drop tab tab_value

// adjust medications with "mL" for units
gen ml = 1 if regexm(dose_unit, "ML")

	preserve
	keep if ml ==1 & (narc==1 | bzd ==1)
	tab generic_name, mi
	* APAP/codeine 300-30 / 12.5 mL --> convert at 2.4
	* codeine-guaifenesin --> convert at 2
	* opium 10% per 1 mL --> convert at 10
	restore

gen ml_value=2.4 if regexm(generic_name, "acetamin") & ml == 1 & (narc==1 | bzd ==1)
	replace ml_value=2 if regexm(generic_name, "guaifen") & ml == 1 & (narc==1 | bzd ==1)
	replace ml_value=10 if regexm(generic_name, "opium") & (narc==1 | bzd ==1)

generate med_dose2=med_dose
	replace med_dose2=med_dose*ml_value if ml_value !=. & ml == 1
drop med_dose
rename med_dose2 med_dose
replace dose_unit="MG" if ml==1
drop ml ml_value

// replace ppx lovenox/heparin with . for anticoag dummy
	replace anticoag = . if (regexm(generic_name, "enoxaparin") | regexm(generic_name, "lovenox")) & med_dose < 40

// identify comfort care by morphine orders	
gen comfort_care_by_meds = 1 if regexm(med_name, "END") & narc ==1 & iv==1
gen double comfort_care_time = time if comfort_care_by_meds ==1
	format comfort_care_time %tC
	// bysort enc (time): carryforward comfort_care_by_meds, replace

// address PCA orders: BASAL RATE: __ // INITIAL RATE: __ mg/hour
	* bolus administrations cannot be obtained, but continuous infusions may put patients at increased risk and can be estimated
generate pca = 1 if regexm(med_name, "PCA")

generate pca_dose = regexs(2) if regexm(med_name, "(RATE:[ ])([0-9]+[.]*[0-9]*)([ ]M)") & comfort_care_by_meds !=1
destring pca_dose, replace
replace generic_name = generic_name + " pca" if regexm(med_name, "PCA") & narc ==1
	// carryforward as med dose until next admin or end_time, whichever first?
		// first step is to carryforward end time from the pca start (or rate change) order
		// need to re-eval how to do this with the 6-hour time blocks

// add opioid conversions
ren med_dose dose_value

	** oral morphine equivalents
	generate oral_morph_equiv=.

	* morphine
		replace dose_value = 120 if regexm(dose_unit, "EACH") & narcotic_name == 1
		replace oral_morph_equiv = dose_value if narcotic_name==1 & iv_med !=1
		replace oral_morph_equiv = dose_value*3 if narcotic_name==1 & iv_med ==1
	tab dose_value dose_unit if narcotic_name ==1, mi
	replace dose_unit = "MG" if narcotic_name == 1

	* hydromorphone
		replace oral_morph_equiv = dose_value*4 if narcotic_name==2 & iv_med !=1
		replace oral_morph_equiv = dose_value*20 if narcotic_name==2 & iv_med ==1

	* oxycodone
		replace oral_morph_equiv = dose_value*1.5 if narcotic_name==3 & iv_med !=1

	* fentanyl - 300:1 conversion, but units are mcg
		replace oral_morph_equiv = dose_value*0.3 if narcotic_name==4 & iv_med==1
		replace oral_morph_equiv = dose_value*100 if narcotic_name==4 & iv_med !=1

	* codeine
		replace oral_morph_equiv = dose_value/6.5 if narcotic_name==5 & iv_med !=1

	* hydrocodone
		replace oral_morph_equiv = dose_value if narcotic_name==6

	* meperidine
		replace oral_morph_equiv = dose_value/10 if narcotic_name==7 & iv_med !=1
		replace oral_morph_equiv = dose_value/2.5 if narcotic_name==7 & iv_med ==1

	* opium
		replace oral_morph_equiv = dose_value*10 if narcotic_name==8 & iv_med !=1

	* tramadol
		replace oral_morph_equiv = dose_value*4 if narcotic_name==9 & iv_med !=1

	* methadone
		replace oral_morph_equiv = dose_value*7.5 if narcotic_name==10 & iv_med !=1
		replace oral_morph_equiv = dose_value*3 if narcotic_name==10 & iv_med ==1

	* oxymorphone
		replace oral_morph_equiv = dose_value*3 if narcotic_name ==11
		replace dose_value = . if regexm(med_name, "LEVOTHY")
		
	* oral morphine equivalents does not currently contain pca basal rates	

// add benzodiazepine conversions

	** benzodizepine equivalents
	generate oral_loraz_equiv=.

	* alprazolam
		replace oral_loraz_equiv = dose_value*2 if bzd_name==1

	* chlordiazepoxide
		replace oral_loraz_equiv = dose_value/25 if bzd_name==2

	* clonazepam
		replace oral_loraz_equiv = dose_value*2 if bzd_name==3

	* diazepam
		replace oral_loraz_equiv = dose_value/10 if bzd_name==4

	* estazolam
		replace oral_loraz_equiv = dose_value if bzd_name==5

	* flurazepam
		drop if bzd_name==6
	*** only 1 observation for this med - likely a mistake

	* lorazepam
		replace oral_loraz_equiv = dose_value if bzd_name==7

	* midazolam
		replace oral_loraz_equiv = dose_value/2 if bzd_name==8 & iv_med !=1
		replace oral_loraz_equiv = dose_value/4 if bzd_name==8 & iv_med ==1

	* temazepam
	replace oral_loraz_equiv = dose_value/20 if bzd_name==9
	
	* triazolam
	replace oral_loraz_equiv = dose_value*2 if bzd_name==10

	* oxazepam
	replace oral_loraz_equiv = 4 if med_name == "TYPED MEDICATION OXAZEPAM 30 MG" & mi(oral_loraz)
	replace bzd = 0 if regexm(med_name, "LINZESS")
	
// get Ashley's list of AEDs

// look at standing vs prn med orders - can we at least say "had standing orders for this day"?

// look at histograms and outliers for opioids and benzo doses

// address duplicates by time
duplicates tag encounter-oral_loraz_equiv, gen(dups)
	tab dups, mi
	* ~15k duplicates
sample 1 if dups > 0, count by (encounter-oral_loraz_equiv)
	drop dups

	
	

	
gen double time_minutes=1000*floor(time/1000)
format time_minutes %tC

foreach v in varlist a-b {
bysort encounter time_minutes (time), egen max_v = max

bysort encounter (time): egen maxtime_enc = max(time)
}



// save small datasets
preserve
egen keep = rowtotal(crrt_-icu_status)
drop if keep ==0
drop med_name dose_amount_max dose_unit frequency_code frequency_modifier order_status keep
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/meds_shrunk.dta", replace

keep encounter time generic_name dose_value med_start_time med_end_time admin_not_just_order crrt_from_meds vasoactive insulin_gtt icu_med icu_status comfort_care_by_meds comfort_care_time
egen keep = rowtotal(crrt-comfort_care_by_meds)
drop if keep == 0

drop time
gen id = _n
expand 2
by id, sort: generate double time = cond(_n == 1, med_start, med_end)
format time2 %tC
by id: generate startstop_med = cond(_n == 1, 1, -1)
drop keep id icu_med

gen med_name=strltrim(generic_name)
drop generic_name
ren med_name generic_name
order enc time startstop icu_status generic_name dose_value

save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/meds_icu_defining.dta", replace
restore

preserve
egen keep = rowtotal(crrt_-icu_status)
drop if keep ==0
drop med_name dose_amount_max dose_unit frequency_code frequency_modifier order_status keep
drop if admin_not_just_order == 0
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/meds_shrunk_only_admins.dta", replace
restore

// fix stacked meds for icu status
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/meds_icu_defining.dta", clear

	* drop single-dose epi 0.3 given for drug reactions --> does not define ICU stay
	gen drop_flag = 1 if generic_name == "epinephrine" & (dose_value > 0.2 & dose_value < 0.35)
	drop if drop_flag == 1
	drop drop_flag

		replace time = med_start_time if mi(time) & admin_ == 1 & startstop == 1
		replace time = med_end_time if mi(time) & admin_ == 1 & startstop == -1
		replace time = med_start_time if mi(time) & admin_ == 1

	* identify any gaps 24h or longer between the end of 1 icu-defining therapy and the start of the next
	bysort enc (time): generate time_gap = hours(time[_n] - time[_n-1]) if (startstop[_n] == 1 & startstop[_n-1] == -1) & (icu_status[_n] == 1 & icu_status[_n-1] == 1)
		order time_gap, after(time)

	gen new_icu_stay = 1 if time_gap >= 24 & time_gap !=.
	
	* count the number of icu stays per encounter based on these critera
	bysort enc (time): gen num_icu_stays = sum(new_icu_stay)

	* find the beginning and end of each individual icu stay	
	bysort enc num_icu_stays (time): egen double icu_start_time = min(time) if icu_status==1 & startstop ==1
	format icu_start_time %tC	
		order icu_start_time, after (time)
	
	bysort enc num_icu_stays (time): egen double icu_stop_time = max(time) if icu_status==1 & startstop == -1
	format icu_stop_time %tC	
		order icu_stop_time, after (icu_start_time)

	bysort enc (time icu_start_time icu_stop_time): generate icu_start_flag = 1 if icu_start_time == time
		replace icu_start_flag = . if icu_start_flag[_n-1] == 1 & time[_n] == time[_n-1] & encounter[_n]==encounter[_n-1]
	generate icu_end_flag = 1 if icu_stop_time == time
	
	* find icu stays with no defined end - will define "end" as a new room or end oc hospitalization	
	bysort enc (time icu_start_time): egen double maxtime = max(time)
	format maxtime %tC
	
	bysort enc (time icu_start_time): gen sum_icu_starts = sum(icu_start_flag)
	bysort enc (time icu_start_time): gen sum_icu_stops = sum(icu_end_flag)
		
	bysort enc (time icu_start_time): gen mismatch = 1 if time == maxtime & sum_icu_starts > sum_icu_stops
	replace mismatch = . if mismatch[_n] ==1 & encounter[_n]==encounter[_n+1]
	tab mismatch, mi
	* the mismatches are due to 3+ meds starting an icu stay based on simultaneous times --> will be addressed when dups deleted
	
	drop sum* mismatch generic_name dose_value time_gap
	
	duplicates tag encounter time startstop new_icu_stay comfort_care_time icu_start_flag icu_end_flag, gen(dups)
	sample 1 if dups > 0, count by(encounter time startstop icu_start_flag icu_end_flag)
	drop dups 			
	
	bysort enc (time): egen double comfort_start_time = min(time) if comfort_care_by_meds ==1
	generate comfort_start_flag = 1 if time== comfort_start_time
	
	keep if icu_start_flag == 1 | icu_end_flag == 1 | comfort_start_flag == 1
	
	duplicates tag encounter comfort_start_flag, gen(dups)
	sample 1 if comfort_start_flag == 1 & dups > 0, count by (encounter)
	drop dups
	
	keep enc time startstop icu_status new_icu_stay num_icu icu_start_flag icu_end_flag comfort_start_flag
	
	* keep only dates before the BMT ICU opened (Dec 7, 2015)
	generate date = dofC(time)
	keep if date < 20430
	drop date
	
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project 20180412/meds_icu_defining_final.dta", replace
