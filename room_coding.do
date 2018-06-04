* ==============================================================================
*
* this do-file cleans and combines patient location data
*
* datasets used: - II-440 Lyons North campus EWS project Room Times.txt
*
* output dataset: - room.dta (primary output)
*
* ==============================================================================

clear
set more off

// room
import delimited "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project Room Times.txt"

// rename common variables
ren report_vis encounter

// drop unneeded variables
drop facility*

// destring dates/times
gen double room_start_time = Clock(room_start_date, "YMDhms#")
format room_start_time %tC

gen double room_end_time = Clock(room_end_date, "YMDhms#")
format room_end_time %tC

drop room_start_date room_end_date

// room should be a room number if ward == 1 or icu ==1

// create categorical location variable
gen loc_cat = 1 if ward == "ER" | ward == "EDOB" |room_no == "ER"
	replace loc_cat = 2 if regexm(ward, "00") | regexm(ward, "89ON") | regexm(ward, "SHUK")
	replace loc_cat = 3 if regexm(ward, "CU")
	replace loc_cat = 4 if regexm(ward, "OR")
	replace loc_cat = 5 if regexm(ward, "CAM")
	replace loc_cat = 6 if mi(loc_cat)

label define loc_cat 1 "ED" 2 "ward" 3 " ICU" 4 "OR" 5 "clinic" 6 "other"
label values loc_cat loc_cat

// destring ward
generate ward_2 = real(ward) if loc_cat == 2 | loc_cat == 3
	replace ward_2 = 14300 if ward == "SHUK"
	replace ward_2 = 8900 if ward == "89ON"
	
gen ward_3 = regexs(0) if(regexm(ward, "[0-9]*"))
	replace ward_2 = real(ward_3) if mi(ward_2)

drop ward ward_3
rename ward_2 ward

// destring room number
gen room = real(room_no) if loc_cat == 2 | loc_cat == 3

gen room_2 = regexs(2) if(regexm(room_no, "([0-9])*[*]([0-9][0-9][0-9][0-9])"))
	replace room_2 = regexs(0) if(regexm(room_no, "^[0-9][0-9][0-9]")) & mi(room_2)
	replace room_2 = regexs(0) if(regexm(room_no, "^[0-9][0-9][0-9]")) & mi(room_2)
	replace room_2 = regexs(1) + "00" if(regexm(room_no, "([0-9][0-9][0-9])([A-Z][A-Z])")) & mi(room_2)
	replace room_2 = "143" + regexs(2) if(regexm(room_no, "([A-Z][A-Z][0-9])([0-9][0-9])")) & mi(room_2)
	replace room = real(room_2) if mi(room)
	replace room = 5600 if room==56
	replace room = 8400 if room==84
	replace room = 10400 if room==104
drop room_2 room_no

// clean up loc_cat, ward, and room
tostring ward, gen(ward_string)
	replace loc_cat = 2 if loc_cat==6 & regexm(ward_string, "00")
	replace loc_cat= 2 if ward==8900 
	replace loc_cat = 3 if room==8911 | room==8912 | room==8913 | room==8914 | room==8915
	replace loc_cat = 3 if room==8916 | room==8917 | room==8918 | room==8919 | room==8920
	replace ward=8300 if ward==83
	replace ward=6200 if ward==62
	replace loc_cat = 3 if ward==8300
drop ward_string

// make loc_cat2 which counts OR/other locations as prior ward, if avail (to ID ICU TFs)
gen loc_cat2=loc_cat
bysort enc (room_start_time): replace loc_cat2=loc_cat2[_n-1] if loc_cat2==4 & enc[_n-1]==enc[_n] & loc_cat2[_n-1] !=6
bysort enc (room_start_time): replace loc_cat2=loc_cat2[_n-1] if loc_cat2==6 & enc[_n-1]==enc[_n]
label values loc_cat2 loc_cat
* lots of ward visits are preceded by "other" - looks like eithe pre-admit data or before admit order placed
gsort encounter -room_start_time
	replace loc_cat2=loc_cat2[_n-1] if loc_cat2==6 & enc[_n-1]==enc[_n]

// carry forward ward & room locations
gen ward2=ward 
gen room2=room

bysort encounter (room_start_time): carryforward ward2 room2 if room_start_time[_n+1] <= room_end_time[_n] & encounter[_n+1] == encounter[_n], replace
bysort enc (room_start_time): replace ward2=ward2[_n-1] if mi(ward2) & loc_cat==4 & enc[_n-1]==enc[_n]
bysort enc (room_start_time): replace room2=room2[_n-1] if mi(room2) & loc_cat==4 & enc[_n-1]==enc[_n]
gsort encounter -room_start_time
	replace ward2=ward2[_n-1] if mi(ward2) & loc_cat==6 & enc[_n-1]==enc[_n]
	replace room2=room2[_n-1] if mi(room2) & loc_cat==6 & enc[_n-1]==enc[_n]
bysort enc (room_start_time): replace ward2=ward2[_n-1] if mi(ward2) & loc_cat==6 & enc[_n-1]==enc[_n]
bysort enc (room_start_time): replace room2=room2[_n-1] if mi(room2) & loc_cat==6 & enc[_n-1]==enc[_n]

tostring room2, gen(room_string)
replace ward2 = 6900 if regexm(room_string, "^69")
replace ward2 = 4900 if regexm(room_string, "^49")
replace ward2 = 4400 if regexm(room_string, "^44")
replace ward2 = 6200 if regexm(room_string, "^62")
replace ward2 = 7900 if regexm(room_string, "^79")
replace ward2 = 6500 if regexm(room_string, "^65")
replace ward2 = 16400 if regexm(room_string, "^16")
replace loc_cat2 = 2 if ward2==6200
drop room_string

// remove extra variables
drop loc_cat room ward
rename loc_cat2 loc_cat
rename ward2 ward
rename room2 room

// add time variable for merging
generate double time = room_start_time
format time %tC

save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/room.dta", replace

********************************************************
