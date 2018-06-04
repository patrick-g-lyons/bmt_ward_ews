
* ==============================================================================
*
* this do-file cleans and combines lines/tubes/procedures data
*
* datasets used: - II-440 Lyons North campus EWS project Insertions.txt
*
* output dataset: - lines_tubes.dta (primary output)
*
* ==============================================================================

clear
set more off

// lines and tubes
import delimited "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/II-440 Lyons North campus EWS project Insertions.txt"

// rename encounter
ren report_v encounter

// destring dates/times
gen double line_in_time = Clock(start_date, "YMDhms#")
format line_in_time %tC

gen double line_out_time = Clock(end_date, "YMDhms#")
format line_out_time %tC
drop start_date end_date

// clean up outpatient/visitor/employee rrt calls
gen Z=lower(intervention)
drop intervention
rename Z intervention

// adjust line names
gen line = "central_line" if regexm(intervention, "central")
	replace line = "dialysis" if regexm(intervention, "dialysis")
	replace line = "ventilator" if regexm(intervention, "vent")
	replace line = "foley" if regexm(intervention, "urin")
tab line, mi
drop intervention

// remove duplicates for reshaping
duplicates tag encounter line_in_time line_out line, gen(dups)
sample 1 if dups > 0, count by(encounter line_in_time line_out line)
drop dups

// generate identifier for subseqent lines
bysort encounter line (line_in_time): gen line_number =_n
tostring line_number, replace
generate line_2 = line + "_" + line_number
drop line line_number
rename line_2 line

// reshape long with start/stop --> time
ren (line_in_time line_out_time) (tt1 tt2)
gen n = _n
reshape long tt, i(n) j(t)
ren tt time

bysort enc line (time): gen central_line_in = 1 if regexm(line, "central") & line[_n] != line[_n-1]
bysort enc line (time): gen central_line_out = 1 if regexm(line, "central") & line[_n] != line[_n+1]

bysort enc line (time): gen dialysis_in = 1 if regexm(line, "dialysis") & line[_n] != line[_n-1]
bysort enc line (time): gen dialysis_out = 1 if regexm(line, "dialysis") & line[_n] != line[_n+1]

bysort enc line (time): gen vent_in = 1 if regexm(line, "vent") & line[_n] != line[_n-1]
bysort enc line (time): gen vent_out = 1 if regexm(line, "vent") & line[_n] != line[_n+1]

bysort enc line (time): gen foley_in = 1 if regexm(line, "foley") & line[_n] != line[_n-1]
bysort enc line (time): gen foley_out = 1 if regexm(line, "foley") & line[_n] != line[_n+1]

// check for errors
egen check = rowtotal(central_line_in-foley_out)
tab check, mi
	* all values == 1
drop n t check line

// save
save "/Users/plyons/Desktop/II-440 Lyons North campus EWS project/lines_tubes.dta", replace
********************************************************
