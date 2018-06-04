






use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/diagnosis.dta"

// cancer diagnoses
generate leukemia = 1 if regexm(description, "eukemia") | regexm(description, "LEUKEMIA")
	replace leukemia = 1 if regexm(description, "SPF LEUK") | regexm(description, "HAIRY-CELL LEUKEM")
	replace leukemia = 1 if regexm(description, "ERTH/ERYLK") | regexm(description, "ACT LEUK")
	replace leukemia = 1 if regexm(description, "LYM LEU") | regexm(description, "LYMP LEUK")
	replace leukemia = 1 if regexm(description, "MYEL LEUK") | regexm(description, "MYL LEUK")
	replace leukemia = 1 if regexm(description, "yelodysplastic") | regexm(description, "MYELOFIBROSIS")
	replace leukemia = 1 if regexm(description, "MYELODYSPL") | regexm(description, "APLASTIC ANEMIA")
	replace leukemia = 1 if regexm(description, "plastic anemia")
	replace leukemia = . if regexm(description, "Family") | regexm(description, "family")
			  
generate bmt = 1 if regexm(description, "Stem cell") | regexm(description, "stem cell")
	replace bmt = 1 if regexm(description, "TRNSPL STATUS-BNE MARROW") | regexm(description, "TRSPL STS-PERIP STM CELL")
	replace bmt = 1 if regexm(description, "MARROW TRANSPLANT") | regexm(description, "marrow transplant")
	replace bmt = . if regexm(description, "onor")

generate myeloma = 1 if regexm(description, "yeloma") | regexm(description, "lasmac")
	replace myeloma = 1 if regexm(description, "Waldenstrom") | regexm(description, "MULT MYEL") 
 
generate lymphoma = 1 if regexm(description, "ymphoma") | regexm(description, "Sezary")
	replace lymphoma = 1 if regexm(description, "PRIMARY CNS LYMPH") | regexm(description, "Mycosis fungoides")
	replace lymphoma = 1 if regexm(description, "BURKITT") | regexm(description, "BRKT TMR")
	replace lymphoma = 1 if regexm(description, "LYMPHOMA") | regexm(description, "MYCS FNG")
	replace lymphoma = 1 if regexm(description, "NDLR LYM") | regexm(description, "MYCOSIS FUNGOIDES")
	replace lymphoma = 1 if regexm(description, "OTH LYMP UNSP") | regexm(description, "HODG NODUL")
	replace lymphoma = 1 if regexm(description, "HODGKINS") | regexm(description, "MANTLE CELL")
	replace lymphoma = 1 if regexm(description, "ZONE LYM") | regexm(description, "MLG HIST")
	replace lymphoma = 1 if regexm(description, "HISTIOCYTOSIS") | regexm(description, "MLG MAST")
	replace lymphoma = 1 if regexm(description, "LYMPHOID MAL") | regexm(description, "Histiocytic and mast cell tumo")
	replace lymphoma = 1 if regexm(description, "PERIPH T CELL LYM XTRNDL") | regexm(icdx_diagnosis_code, "196")
	replace lymphoma = 1 if regexm(description, "ANAPLASTIC LYMPH") | regexm(icdx_diagnosis_code, "196")

generate solid_tumor = 1 if regexm(description, "alignant neoplasm") | regexm(description, "alig neo") | regexm(description, "neosplasm, u")
	replace solid_tumor = 1 if regexm(description, "arcinoid") | regexm(description, "elanoma") | regexm(description, "euroendocrine")
	replace solid_tumor = 1 if regexm(description, "MALIG NEO") | regexm(description, "MERKEL")
	replace solid_tumor = 1 if regexm(description, "NEUROEND") | regexm(description, "MAL NEO")
	replace solid_tumor = 1 if regexm(description, "SARCOMA") | regexm(description, "arcoma")
	replace solid_tumor = 1 if regexm(description, "Neoplasm of un") | regexm(description, "NEOPLASM OF UN")
	replace solid_tumor = 1 if regexm(description, "arcinoma") | regexm(description, "Malignant (primary) neoplasm")
	replace solid_tumor = 1 if regexm(description, "MALIGNANT NEO") | regexm(description, "MALIGNANCY")
	replace solid_tumor = 1 if regexm(description, "MALIG NE") | regexm(description, "MAL NEO")
	replace solid_tumor = 1 if regexm(description, "MELANOM") | regexm(description, "SRCOMA")
	replace solid_tumor = 1 if regexm(description, "CARCINOID") | regexm(description, "CRCND")
	replace solid_tumor = 1 if regexm(description, "CRCNOID") | regexm(description, "MALIGNAN")
	replace solid_tumor = 1 if regexm(description, "MALIGN NEC") | regexm(description, "malignant neoplas")
	replace solid_tumor = 1 if regexm(description, "strogen receptor") | regexm(description, "ESTROGEN RECEP")
	replace solid_tumor = 1 if regexm(description, "LYMPHSRC") | regexm(description, "arcoma")
	replace solid_tumor = . if regexm(description, "Family") | regexm(description, "family")
	replace solid_tumor = . if regexm(description, "susceptibi") | regexm(description, "SCREEN")
	replace solid_tumor = . if regexm(description, "FM HX") | regexm(description, "FAMILY") | regexm(description, "FAM HX")

// other diagnoses
generate hiv_icd = 1 if regexm(description, "Human immunodef") | regexm(description, "HUMAN IMMUNO")
	replace hiv_icd = 1 if regexm(description, "HIV")

generate malnutrition_icd = 1 if regexm(description, "alnutrit") | regexm(description, "MALNUTR")

generate mucositis = 1 if regexm(description, "ucositis") | regexm(description, "tomatitis")
	replace mucositis = 1 if regexm(description, "MUCOSITIS") | regexm(description, "STOMATITIS")

generate tumor_lysis = 1 if regexm(description, "umor lysis") | regexm(description, "TUMOR LYSIS")

generate tracheostomy = 1 if regexm(description, "racheostomy")

generate tma = 1 if regexm(description, "rombotic microang") | regexm(description, "THROMBOT MICROANGIOPATHY")

generate ptld_icd = 1 if regexm(description, "ost-transplant lymphopro") | regexm(description, "POST TP LYMPHPR")

generate hit_icd = 1 if regexm(description, "eparin induced thrombo") | regexm(description, "HEPARIN-IND")

generate gvhd_icd = 1 if regexm(description, "raft-versus") | regexm(description, "GRAFT-V")
	replace gvhd_icd = 1 if regexm(description, "GRFT-V") | regexm(description, "GVHD")

generate palliative_icd = 1 if regexm(description, "alliative")

generate dnr = 1 if regexm(description, "not resuscitate")

generate osa = 1 if regexm(description, "leep apnea") | regexm(description, "SLEEP APNEA")
	replace osa = 1 if regexm(description, "hypovent synd")

// expand diagnoses to the encounter level
foreach vd of varlist leukemia-osa {
	egen `vd'_2=min(`vd'), by(enc)
	drop `vd'
	}
renvars leukemia_2-osa_2, postdrop(2)

// one observation per encounter
duplicates tag enc, gen(dups)
sample 1 if dups > 0, count by(enc)

// remove extra variables
drop dups icdx_version_no icdx_diagnosis_code description

// save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/diagnosis_wide.dta", replace
********************************************************
