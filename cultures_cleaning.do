* ==============================================================================
*
* this do-file cleans and combines culture and susceptibility data
*
* datasets used: - II-440 Lyons North campus EWS project Visit Times.txt
*				 - II-440 Lyons North campus EWS project Demographics.txt
*
* output dataset: - visit_demographics.dta (primary output)
*				  - visit.dta (intermediate)
*				  - demographics.dta (intermediate)
*
* ==============================================================================




// cultures
use "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/cultures.dta"

// destring dates/times
gen double culture_time = Clock(collection_date, "YMDhms#")
format culture_time %tC
drop collection_date final_date

// culture site categories
generate cx_site = "blood" if regexm(site, "CENTRAL") | regexm(site, "BRACH") | regexm(site, "PORT")
replace cx_site = "blood" if regexm(site, "CEPHAL") | regexm(site, "FEMORAL") | regexm(site, "HICKM")
replace cx_site = "blood" if regexm(site, "DIALYSIS") | regexm(site, "BRACH") | regexm(site, "HOHN")
replace cx_site = "blood" if regexm(site, "SUBCLAV") | regexm(site, "TRIPLE") | regexm(specimen, "TIP")
replace cx_site = "blood" if regexm(site, "A LINE") | regexm(site, "ANTECU")
replace cx_site = "blood" if regexm(site, "ARTER") | regexm(site, "BASIL")
replace cx_site = "blood" if regexm(site, "FISTULA") | regexm(site, "GRAFT") 
replace cx_site = "blood" if regexm(site, "PERIPH") | regexm(site, "ARTER") | regexm(site, "RADIA")
replace cx_site = "blood" if regexm(site, "VEIN") | regexm(site, "VEN") | regexm(site, "RADIA")
replace cx_site = "blood" if site == "BLOOD" | specimen == "BLOOD" | regexm(specimen, "SERUM") | regexm(specimen, "PLASMA")

replace cx_site = "abdominal" if regexm(site, "ABDOM") | regexm(site, "ESOPH") | regexm(site, "G-TUBE")
replace cx_site = "abdominal" if regexm(site, "BIL") | regexm(site, "GALLBLADDER") | regexm(site, "GASTR")
replace cx_site = "abdominal" if regexm(site, "HEPATIC") | regexm(site, "ILEO") | regexm(site, "LIVER")
replace cx_site = "abdominal" if regexm(site, "PRATT") | regexm(site, "JEJUN") | regexm(site, "GASTR")
replace cx_site = "abdominal" if regexm(site, "RECT") | regexm(site, "ANAL") | regexm(site, "PERITONE")
replace cx_site = "abdominal" if regexm(site, "QUADRANT") | regexm(site, "SIGMOI") | regexm(site, "SPLEEN")
replace cx_site = "abdominal" if regexm(site, "STOMACH") | regexm(site, "SIGMOI") | regexm(site, "SPLEEN")
replace cx_site = "abdominal" if regexm(specimen, "ABDOM") | regexm(specimen, "ASCIT") | regexm(specimen, "BIL")
replace cx_site = "abdominal" if regexm(specimen, "PARACEN") | regexm(specimen, "PERITON") | regexm(specimen, "STOOL")
replace cx_site = "abdominal" if regexm(specimen, "RECT") | regexm(site, "COLON")

replace cx_site = "respiratory" if regexm(site, "BRONCH") | regexm(site, "TRACH") | regexm(site, "LOBE")
replace cx_site = "respiratory" if regexm(site, "LUNG") | regexm(site, "PLEUR") | regexm(site, "SPUTUM")
replace cx_site = "respiratory" if regexm(specimen, "BRONCH") | regexm(specimen, "NASOPHARY") | regexm(specimen, "PLEUR")
replace cx_site = "respiratory" if regexm(specimen, "SPUTUM") | regexm(specimen, "THORACEN") | regexm(specimen, "TRACH")

replace cx_site = "urinary" if regexm(site, "KIDN") | regexm(site, "FOLEY") | regexm(site, "PEN") 
replace cx_site = "urinary" if regexm(site, "NEPH") | regexm(site, "URET") | regexm(site, "VULV")
replace cx_site = "urinary" if regexm(site, "CERV") | regexm(site, "LABIA") | regexm(site, "PELV") 
replace cx_site = "urinary" if regexm(site, "PERINEUM") | regexm(site, "SCROTUM") | regexm(site, "VAGIN")
replace cx_site = "urinary" if site == "BLADDER" | site == "CATHETER"
replace cx_site = "urinary" if regexm(specimen, "CERV") | regexm(specimen, "DISCH") | regexm(specimen, "URIN")
replace cx_site = "urinary" if regexm(specimen, "URET") | regexm(specimen, "VAGIN")| regexm(specimen, "STONE")
replace cx_site = "urinary" if regexm(specimen, "PENI")

replace cx_site = "cns" if regexm(site, "CSF") | regexm(site, "CORNEA") | regexm(site, "EYE")
replace cx_site = "cns" if regexm(site, "BRAIN")| regexm(site, "VITR")
replace cx_site = "cns" if regexm(specimen, "SPINAL") | regexm(specimen, "CORNEA") | regexm(specimen, "OCUL")

replace cx_site = "skin_joint" if regexm(site, "ACETAB") | regexm(site, "ACHIL") | regexm(site, "ANKLE")
replace cx_site = "skin_joint" if regexm(site, "AXIL") | regexm(site, "BACK") | regexm(site, "BREAST")
replace cx_site = "skin_joint" if regexm(site, "BUTT") | regexm(site, "CALF") | regexm(site, "CHEST")
replace cx_site = "skin_joint" if regexm(site, "CHIN") | regexm(site, "CLAVIC") | regexm(site, "DEEP")
replace cx_site = "skin_joint" if regexm(site, "ELB") | regexm(site, "FACE") | regexm(site, "FACIA")
replace cx_site = "skin_joint" if regexm(site, "FASCI") | regexm(site, "FIBUL") | regexm(site, "FING")
replace cx_site = "skin_joint" if regexm(site, "FLANK") | regexm(site, "BONE") | regexm(site, "TENDON")
replace cx_site = "skin_joint" if regexm(site, "FOOT") | regexm(site, "FOREHEAD") | regexm(site, "FACIA")
replace cx_site = "skin_joint" if regexm(site, "GROIN") | regexm(site, "HEEL") | regexm(site, "HIP")
replace cx_site = "skin_joint" if regexm(site, "HUMER") | regexm(site, "ILIAC") | regexm(site, "INCISION")
replace cx_site = "skin_joint" if regexm(site, "INGUIN") | regexm(site, "KNEE") | regexm(site, "LEG")
replace cx_site = "skin_joint" if regexm(site, "NECK") | regexm(site, "SHIN") | regexm(site, "SACRAL")
replace cx_site = "skin_joint" if regexm(site, "SCALP") | regexm(site, "SHOULDER") | regexm(site, "SCAPULA")
replace cx_site = "skin_joint" if regexm(site, "SKIN") | regexm(site, "STERNUM") | regexm(site, "SUBCUT")
replace cx_site = "skin_joint" if regexm(site, "TEMPOR") | regexm(site, "THIGH") | regexm(site, "THUMB")
replace cx_site = "skin_joint" if regexm(site, "TIBIA") | regexm(site, "TOE") | regexm(site, "WRIST")
replace cx_site = "skin_joint" if regexm(specimen, "BONE") | regexm(specimen, "JOINT") | regexm(specimen, "LESION")
replace cx_site = "skin_joint" if regexm(specimen, "NODE") | regexm(specimen, "WOUND") | regexm(specimen, "HARD")
replace cx_site = "skin_joint" if regexm(site, "PALM") | regexm(specimen, "SYNOV") | regexm(specimen, "HARD")
replace cx_site = "skin_joint" if specimen != "BLOOD" & (regexm(site, "ARM") | regexm(site, "HAND") | regexm(site, "WRIST"))

replace cx_site = "ent_oral_dental" if regexm(site, "CHEEK") | regexm(site, "EAR") | regexm(site, "ETHMOI")
replace cx_site = "ent_oral_dental" if regexm(site, "FRONTAL") | regexm(site, "LIP") | regexm(site, "MANDIB")
replace cx_site = "ent_oral_dental" if regexm(site, "MOUTH") | regexm(site, "NARE") | regexm(site, "NOSTR")
replace cx_site = "ent_oral_dental" if regexm(site, "ORAL") | regexm(site, "PALATE") | regexm(site, "TONSIL")
replace cx_site = "ent_oral_dental" if regexm(site, "PHARYN") | regexm(site, "SINUS") | regexm(site, "SPHENOID")
replace cx_site = "ent_oral_dental" if regexm(site, "TONGUE") | regexm(site, "NASAL")| regexm(specimen, "NASAL")
replace cx_site = "ent_oral_dental" if regexm(specimen, "THROAT") | regexm(specimen, "NASAL")| regexm(specimen, "ORAL")

replace cx_site = "other" if mi(cx_site)
encode cx_site, gen(cx_site_2)
drop cx_site
rename cx_site_2 cx_site

// merge with culture results
merge 1:m encounter report_cul_id using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/culture_organism.dta"
drop _merge

merge 1:m encounter report_cul_id org_no using "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/culture_susceptibilities.dta"
drop _merge
order encounter report_cul_id org_no culture_time cx_site species_name antibiotic 
sort encounter report_cul_id org_no 

ren culture_time time
gen negative_result = 1 if regexm(result_is_negative, "Y")
drop result_is_negative specimen short_name site zone_size

*** need to review abx_strings for sensitivities and try to figure out what they are

generate species = "Aspergillus" if regexm(species_name, "Aspergillus")
replace species = "Achromobacter" if regexm(species_name, "Achromo")
replace species = "Acinetobacter" if regexm(species_name, "Acinetobacter")
replace species = "Actinomyces" if regexm(species_name, "Actinomyces")
replace species = "Bacillus" if regexm(species_name, "Bacillus")
replace species = "Bacteroides" if regexm(species_name, "Bacteroides")
replace species = "Blastomyces" if regexm(species_name, "Blastomyces")
replace species = "Burkholderia" if regexm(species_name, "Burkholderia")
replace species = "Candida" if regexm(species_name, "Candida")
replace species = "C diff" if regexm(species_name, "Clostridium difficile")
	generate c_diff_test = 1 if regexm(species_name, "Clostridium difficile")
replace species = "Clostridium" if regexm(species_name, "Clostridium") & c_diff_test !=1
replace species = "Coccidioides" if regexm(species_name, "Coccidioides")
replace species = "Coronavirus" if regexm(species_name, "Coronavirus")
replace species = "Cryptococcus" if regexm(species_name, "Cryptococcus")
replace species = "Ehrlichia" if regexm(species_name, "Ehrlichia")
replace species = "CMV" if regexm(species_name, "Cytomegalovirus")
replace species = "Enterobacter" if regexm(species_name, "Enterobacter")
replace species = "Enterococcus" if regexm(species_name, "Enterococcus")
replace species = "RV/EV" if regexm(species_name, "Enterovirus") | regexm(species_name, "Rhinovirus")
replace species = "EBV" if regexm(species_name, "Epstein-Barr virus")
replace species = "E coli" if regexm(species_name, "Escherichia")
replace species = "Haemophilus" if regexm(species_name, "Haemophilus")
replace species = "HSV" if regexm(species_name, "Herpes simplex")
replace species = "Histoplasma" if regexm(species_name, "Histoplasma")
replace species = "HMPV" if regexm(species_name, "Metapneumovirus")
replace species = "HTLV" if regexm(species_name, "T-lymphotropic virus")
replace species = "HIV" if regexm(species_name, "immunodeficiency")
replace species = "Influenza A" if regexm(species_name, "Influenza A")
replace species = "Influenza B" if regexm(species_name, "Influenza B")
replace species = "IGRA" if regexm(species_name, "Interferon Gamma")
replace species = "Klebsiella" if regexm(species_name, "Klebsiella")
replace species = "Legionella" if regexm(species_name, "Legionella")
replace species = "Staph aureus" if regexm(species_name, "Methicillin resistant Staphylococcu")
replace species = "Morganella" if regexm(species_name, "Morganella")
replace species = "Moraxella" if regexm(species_name, "Moraxella")
replace species = "Mycoplasma" if regexm(species_name, "Mycoplasma")
replace species = "Mucor/Rhizopus" if regexm(species_name, "Mucor") | regexm(species_name, "Rhizo")
replace species = "Nocardia" if regexm(species_name, "Nocardia")
replace species = "Pantoea" if regexm(species_name, "Pantoea")
replace species = "Peptostreptococcus" if regexm(species_name, "Peptostreptococcus")
replace species = "Pneumocystis" if regexm(species_name, "Pneumocystis")
replace species = "Proteus" if regexm(species_name, "Proteus")
replace species = "Providencia" if regexm(species_name, "Providencia")
replace species = "Citrobacter" if regexm(species_name, "Citrobacter")
replace species = "Adenovirus" if regexm(species_name, "Adeno")
replace species = "Pseudomonas" if regexm(species_name, "Pseudomonas")
replace species = "RSV" if regexm(species_name, "Respiratory syncytial virus")
replace species = "Salmonella" if regexm(species_name, "Salmonella")
replace species = "Serratia" if regexm(species_name, "Serratia")
replace species = "Providencia" if regexm(species_name, "Providencia")
replace species = "Staph aureus" if regexm(species_name, "Staphylococcus aureus")
	generate staph_aureus = 1 if regexm(species, "aureus")
replace species = "other Staph" if regexm(species_name, "Staphylococcus") & staph_aureus !=1
replace species = "Strep pneumo" if regexm(species_name, "Streptococcus pneumoniae")
	generate strep_pneumo = 1 if regexm(species, "pneumo")
replace species = "other Strep" if regexm(species_name, "Streptococcus") & strep_pneumo !=1
replace species = "other Strep" if regexm(species_name, "Abiotrophia")
replace species = "Stenotrophomonas" if regexm(species_name, "Stenotrophomonas")
replace species = "VZV" if regexm(species_name, "zoster")
replace species = "Parainfluenza" if regexm(species_name, "Parainfluenza")
replace species = "TB" if regexm(species_name, "tuberculosis")
replace species = "NTBM" if species=="" & regexm(species_name, "Mycobacterium")
replace species = "NTBM" if regexm(species_name, "Acid-fast")

replace species = "Other fungi" if regexm(species_name, "Acremonium") | regexm(species_name, "Alternaria")
replace species = "Other fungi" if regexm(species_name, "Arthr") | regexm(species_name, "Trich")
replace species = "Other fungi" if regexm(species_name, "Rhodotorula") | regexm(species_name, "Lichthemia")
replace species = "Other fungi" if regexm(species_name, "Mold") | regexm(species_name, "mold")
replace species = "Other fungi" if regexm(species_name, "Geotrichum") | regexm(species_name, "Fusar")
replace species = "Other fungi" if regexm(species_name, "Chaetomium") | regexm(species_name, "Cladosporium")

replace species = "other GPC" if regexm(species_name, "Aeroc") | regexm(species_name, "Anaerococcus")
replace species = "other GPC" if regexm(species_name, "Granulicatella") | regexm(species_name, "Gemella")
replace species = "other GPC" if regexm(species_name, "Microco") | regexm(species_name, "Gram-positive cocci")

replace species = "other GPR" if regexm(species_name, "Roth") | regexm(species_name, "Weissella")
replace species = "other GPR" if regexm(species_name, "Coryn") | regexm(species_name, "Weissella")

replace species = "other GNR" if regexm(species_name, "Alcaligenes") | regexm(species_name, "Capnocytophaga")
replace species = "other GNR" if regexm(species_name, "Bart") | regexm(species_name, "Aerom")
replace species = "other GNR" if regexm(species_name, "Camp") | regexm(species_name, "Ochro")
replace species = "other GNR" if regexm(species_name, "Sphing") | regexm(species_name, "Prevotella")
replace species = "other GNR" if regexm(species_name, "Plesiomonas") | regexm(species_name, "Leclercia")
replace species = "other GNR" if regexm(species_name, "Leptotrichia") | regexm(species_name, "Hafnia")
replace species = "other GNR" if regexm(species_name, "Fusobacterium") | regexm(species_name, "Eikenella")
replace species = "other GNR" if regexm(species_name, "Gram-negative bacil") | regexm(species_name, "Eikenella")
replace species = "other GNC" if regexm(species_name, "Veil") | regexm(species_name, "Gram-negative coc")
replace species = "HHV-6" if regexm(species_name, "Herpes virus 6") 

replace species = "Bordetella" if regexm(species_name, "Bordetella")
	
replace species = "Negative" if regexm(species_name, "Negative") | regexm(species_name, "No Growth") 
replace species = "Negative" if regexm(species_name, "Missing") | regexm(species_name, "insignificant") 
replace species = "Negative" if regexm(species_name, "Uninteresting") | mi(species_name)
replace species = "Negative" if regexm(species_name, "Acidovorax") | regexm(species_name, "Bifidobacterium")
replace species = "Negative" if regexm(species_name, "Normal") | regexm(species_name, "Penicillium") 
replace species = "Negative" if regexm(species_name, "Scopulariopsis") | regexm(species_name, "Sacch") 
replace species = "Negative" if regexm(species_name, "Rhodoc") | regexm(species_name, "Lact") 
replace species = "Negative" if regexm(species_name, "Leuconostoc") | regexm(species_name, "Propionibacterium") 
replace species = "Negative" if regexm(species_name, "Gard") | regexm(species_name, "Cunninghamella") 
replace species = "Negative" if regexm(species_name, "Curvularia") | regexm(species_name, "Dermabacter") 
replace species = "Negative" if regexm(species_name, "Epicoccum") | regexm(species_name, "Eubacterium") 
replace species = "Negative" if regexm(species_name, "Exophiala") | regexm(species_name, "Eubacterium") 
replace species = "Negative" if regexm(species_name, "Paste") | regexm(species_name, "Eubacterium") 
replace species = "Negative" if regexm(species_name, "Virus") 
replace species = "Negative" if negative_result ==1

replace species = "Contaminated" if regexm(species_name, "Contaminated")
replace species = "BK virus" if regexm(species_name, "BK")



// drop if test not useful
drop if regexm(species_name, "Hepatitis") | regexm(species_name, "Helicobacter")
drop if regexm(species_name, "Nile") | regexm(species_name, "Toxo")
drop if regexm(species_name, "Treponema") | regexm(species_name, "Rube")
drop if regexm(species_name, "Lyme") | regexm(species_name, "Rota") | regexm(species_name, "Noro")
drop if regexm(species_name, "Ricket") | regexm(species_name, "Giardia")
drop if regexm(species_name, "Polymorphonuclear") | regexm(species_name, "Giardia")
drop if regexm(species_name, "Brucella") | regexm(species_name, "Chlam")
drop if regexm(species_name, "Neisseria") | regexm(species_name, "Chlam")
drop if mi(species)

drop if regexm(culture_type, "VDRL") | regexm(culture_type,"VRE")
drop if regexm(culture_type, "TRICHOMONAS") | regexm(culture_type,"COCCIDIOIDES")
drop if regexm(culture_type, "DIPHTHERIA") | regexm(culture_type,"GONORRHOE")
drop if regexm(culture_type, "BLASTO") | regexm(culture_type,"TRACHOMATIS")
drop if regexm(culture_type, "PARASIT") | regexm(culture_type,"NOROVIRUS")
drop if regexm(culture_type, "HHV-6") | regexm(culture_type,"JC VIRUS")
drop if regexm(culture_type, "ENTEROVIRUS") | regexm(culture_type,"EPSTEIN BARR")
drop if regexm(culture_type, "OVA AND PARASIT")
drop if regexm(culture_type, "INTERFERON") | regexm(culture_type,"CHLAMYDIA")
drop if regexm(culture_type, "PERTUSSIS") | regexm(culture_type,"CMV MUTATION")

drop if regexm(culture_type, "BK VIRUS") | regexm(culture_type,"JC VIRUS")
drop if regexm(culture_type, "BARTONELLA") | regexm(culture_type,"BETA STREP")
drop if regexm(culture_type, "GENITAL") | regexm(culture_type,"AMOEBA")
drop if regexm(culture_type, " HAIR/SKIN/NAILS") | regexm(culture_type,"SERUM VAR")
drop if regexm(culture_type, "PERTUSSIS") | regexm(culture_type,"ACID")
drop if regexm(culture_type, "PERTUSSIS") | regexm(culture_type,"CMV MUTATION")
drop if regexm(culture_type, "PERTUSSIS") | regexm(culture_type,"CMV MUTATION")
drop if culture_type == "ACID-FAST BACILLI STAIN"
drop if culture_type == "VIRAL CULTURE"
drop if culture_type == "SERUM LEGIONELLA AB"


replace culture_type = "ADENOVIRUS PCR" if regexm(culture_type, "ADENO")
replace culture_type = "CULTURE" if regexm(culture_type, "AEROBIC") | regexm(culture_type, "MISCELLANEOUS CULT")
replace culture_type = "CULTURE" if regexm(culture_type, "URINE CULT") | regexm(culture_type, "ENTERIC")

replace culture_type = "FUNGAL CULTURE" if regexm(culture_type, "MYCOLOGY CULTURE")
replace culture_type = "MYCOBACTERIAL CULTURE" if regexm(culture_type, "MYCOBACTERIOLOGY")

replace culture_type = "MRSA SURVEILLANCE" if regexm(culture_type, "MRSA") | regexm(culture_type, "STAPH AUREUS SCREEN")

* what about "blood culture" orders where the site is not blood? make the site "unknown"
replace cx_site = 5 if regexm(culture_type, "BLOOD") & cx_site !=2
replace culture_type = "CULTURE" if regexm(culture_type, "CULTURE, BLOOD")

generate urine_legionalla_antigen = 0 if regexm(culture_type, "LEGIONELLA ANTIGEN")
replace urine_legionalla_antigen = 1 if urine_legionalla_antigen !=. & negative_result !=1

generate legionella = 0 if regexm(culture_type, "LEGIONELLA CULTURE") | urine_legionalla_antigen !=.
replace legionella = 1 if legionella !=. & negative_result !=1
drop drop urine_legionalla_antigen 
drop if regexm(culture_type, "LEGION")

// HIV status
generate hiv_by_testing = 1 if regexm(culture_type, "IMMUNO") & negative_result !=1
drop if regexm(culture_type, "IMMUNO")

// CMV presence
replace culture_type = "CMV PCR" if regexm(culture_type, "CYTOM")

// ehrlichia - all are negative, so drop them
drop if regexm(culture_type, "EHR")

// additional stains unnecessary
drop if regexm(culture_type, "STAIN")

// HSV
replace culture_type = "HSV PCR" if regexm(culture_type, "HSV")

// Influenza pcr
replace culture_type = "INFLUENZA PCR" if regexm(culture_type, "INFLUENZA")

// mycoplasma pcr - only 2 instances
drop if regexm(culture_type, "MYCOPL")

// additional identifiers
replace culture_type = "IDENTIFICATION" if regexm(culture_type, "IDENT")

// parvovirus - all 90 are negative
drop if regexm(culture_type, "PARVO")

// marrow donor testing
drop if regexm(culture_type, "DONOR")

// HTLV
replace culture_type = "HTLV" if regexm(culture_type, " T CELL LYMPHOTROPIC")

// VZV
replace culture_type = "VZV PCR" if regexm(culture_type, "VZV")

// TB PCR - all are negative, so drop
drop if regexm(culture_type, "TUBERC")

// generate abx sensitivity dummy variables (code "I" as 99)
foreach vname in Amikacin Ampicillin Aztreonam Cefazolin Cefepime Cefotetan Cefoxitin Ceftaroline Ceftazedime Ceftolazone Ceftriaxone Cipro Clinda Colistin Dapto Doxy Gent Levoflox Linezolid Meropenem Methicillin Minocycline Oxacillin Penicillin Pip Quinu Rifampin Ticarv Tigecycline Tobramycin Trimeth Vancomycin {

	gen `vname'_sens = 1 if regexm(antibiotic, "`vname'") & regexm(sensitivity, "S")
	replace `vname'_sens = 0 if regexm(antibiotic, "`vname'") & regexm(sensitivity, "R")
	replace `vname'_sens = 99 if regexm(antibiotic, "`vname'") & regexm(sensitivity, "I")
}

// expand sensitivity dummies across culture results
foreach var of varlist Amikacin_sens - Vancomycin_sens {
	bysort report_cul_id (org_no): egen `var'_2 = min(`var')
	drop `var'
}

// narrow duplicates
drop antibiotic sensitivity abx_code abx_string 

duplicates tag encounter report_cul_id time cx_site culture_type negative_result species, generate(dups)
sample 1 if dups > 0, count by(encounter report_cul_id time cx_site culture_type negative_result species)
drop dups

replace negative_result = 1 if regexm(species, "Negative")

duplicates tag encounter report_cul_id time negative_result, generate(dups)
sample 1 if dups > 0 & negative_result == 1, count by(report_cul_id time negative_result)
drop dups

duplicates tag encounter report_cul_id time, generate(dups)
drop if dups > 0 & negative_result == 1
drop dups

duplicates tag encounter time cx_site culture_type negative_result species, generate(dups)
sample 1 if dups > 0, count by(encounter time cx_site culture_type negative_result species)
drop dups

* now all duplicates are cultures with multiple positives - report_cul_id doesn't identify them uniquely

// new identifier
gen culture_id = _n
drop report_cul_id org_no


// remove _2 from all sensitivity names
renvars Amikacin_sens_2 - Vancomycin_sens_2, postdrop(2)

// encode culture_type from string to categorical
encode culture_type, gen(cx_type) 
drop culture_type 

// save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/cultures_merged.dta", replace



********************************************************
