// //////////////////////////////////////////////////////////////////////
// MSc grade computation for Exam Board
//
// Sources:
//   General Rules: http://www.lse.ac.uk/resources/calendar/academicRegulations/TaughtMastersDegreesFourUnits.htm
//   Local Rules: http://www.lse.ac.uk/resources/calendar/LocalRules/MScSocialResearchMethods.htm
//
// Developed for the Methodology MSc in Social Research Methods
// Kenneth Benoit <kbenoit@lse.ac.uk>, Jouni Kuha <J.Kuha@lse.ac.uk>
// last updated 17 Sept 2013
//
// To adapt this code to your system, modify the local rules thresholds
// Rename the course specifics where indicated "LOCAL RULES"
// //////////////////////////////////////////////////////////////////////

version 12

// /////////// PARAMETERS SPECIFIC TO EACH PROGRAMME /////////////
// ///////////        LOCAL RULES                    /////////////
global upperbadfail 29
global aggregate_DMborderline 270
global aggregate_MPborderline 240
global output_excel_filename "MSc_marks_results.xls"


// LOAD THE MARKS DATA

// --Can be in wide format - which requires reshaping
// --"Structural" missings should be .z indicating course not taken
// --Marks not yet recorded should be ordinary missing .
//
//use "~/Dropbox/To Do/MSc Exam Board/MSc_marks_2013_rectangular.dta", clear
use MSc_marks_example_wide.dta, clear
reshape long mark, i(candidate) j(course) string
replace course = upper(course)
drop if mark==.z

// --- alternative format --- comment out either wide or long code ---- /////

// --Can be in long format - no reshaping required
// --only courses taken have a row, so no "structural" missings
// --Marks not yet recorded should be ordinary missing .
//
// use "~/Dropbox/To Do/MSc Exam Board/MSc_marks_2013_rectangular.dta", clear
// data in "long" format
//use "~/Desktop/MSc Exam Board/MSC_Marks_2013_Test.dta", clear
use MSc_marks_example_long.dta, clear
rename award award2013
rename rule rule2013 // a validation mark if this exists - otherwise comment out

// some transformations

gen award = .
gen rule = ""
gen compensatedfail = 0
sort candidate course

global lowerfail = $upperbadfail+1
recode mark (0/$upperbadfail = 1 "Bad Fail") ///
            ($lowerfail/49 = 2 Fail) ///
            (50/59 = 3 Pass) ///
            (60/69 = 4 Merit) ///
            (70/100 = 5 Distinction), generate(grade)

// label define mark 1 "Bad Fail" 2 Fail 3 Pass 4 Merit 5 Distinction
label values award grade
// amke equivalent the MY452 different verions
// LOCAL RULES
replace course = "MY452" if (course=="MY452M" | course=="MY452L")

// all half-unit...
generate unit = 0.50
// ...except the two full unit courses
// LOCAL RULES: Indicate here what courses are 1.0 units rather than 0.5
replace unit = 1.00 if (course=="MY499" | course=="SA451" | course=="ST425" | course=="SO463")

// make dummy variables from grades
tab grade, gen(dgrade)
tab unit, gen(dunit)


// ALLOCATE AWARD CATEGORIES

// Rule 5.1: Required pass courses MY452 and MY421

// LOCAL RULES: MODIFY THESE TO MATCH LOCAL REQUIRED PASS COURSES
// (OR COMMENT OUT IF NONE)
replace award = grade if (course=="MY452" | course=="MY421") & grade<3 & award==.
replace rule = "5.1" if (course=="MY452" | course=="MY421") & grade<3 & rule==""
sort candidate award
by candidate: replace award = award[1] if award==.
by candidate: replace rule = rule[1]

// Rule 5.2: Fail mark in any course

//   5.2.1 Bad Fail = Bad Fail award
egen _temp_badfails = sum(dgrade1), by(candidate)
replace award = 1 if _temp_badfails>0 & award==.
replace rule = "5.2.1" if _temp_badfails>0 & rule==""
drop _temp_badfails

//   5.2.2 (n/a)

//   5.2.3 compensated fails
// JK:
//gen atleast60 = (mark >= 60)
//egen howmanyatleast60 = sum(atleast60), by(candidate)
//gen unitsatleast60 = howmanyatleast60 * unit
//egen compensationaggregate = sum(mark), by(candidate)
// // remove the failed grades from compensation aggregate
//replace compensationaggregate = compensationaggregate - mark if (grade<=2)

egen fails = sum(dgrade2*unit), by(candidate)
gen atleast60 = (mark >= 60)*unit
egen unitsatleast60 = sum(atleast60), by(candidate)
egen compensationaggregate = sum(unit*mark*(mark>=50)), by(candidate)

// JK
// replace award = 2 if (grade==2) & !(unitsatleast60>=1) & compensationaggregate<365 & award==. 
// replace rule = "5.2.3" if (grade==2) & !(unitsatleast60>=1) & compensationaggregate<365 & rule==""
// replace compensatedfail = 1 if (grade==2) & ((unitsatleast60>=1) | (compensationaggregate>=365))
replace award = 2 if (fails>0.5) & (grade==2) & !(unitsatleast60>=1) & compensationaggregate<165 & award==. 
replace rule = "5.2.3" if (fails>0.5) & (grade==2) & !(unitsatleast60>=1) & compensationaggregate<165 & rule==""
replace compensatedfail = 1 if (fails>0.5) & (grade==2) & ((unitsatleast60>=1) | (compensationaggregate>=165))

gsort candidate -compensatedfail
by candidate: replace compensatedfail = compensatedfail[1]
// JK
// drop atleast60 howmanyatleast60 unitsatleast60 
drop atleast60 unitsatleast60 
gsort candidate award
by candidate: replace award = award[1]
by candidate: replace rule = rule[1]


// Rule 5.3

gen distinctionunits = dgrade5 * unit
gen meritunits = dgrade4 * unit
gen passunits = dgrade3 * unit
egen totaldistinctionunits = sum(distinctionunits), by(candidate)
egen totalmeritunits = sum(meritunits), by(candidate)
egen totalpassunits = sum(passunits), by(candidate)
// JK:
// egen aggregate = sum(mark), by(candidate)
egen aggregate = sum(unit*mark), by(candidate)
// JK 
// egen failedunits = sum(dgrade2), by(candidate)
egen totalbadfailunits = sum(dgrade1*unit), by(candidate)
egen totalfailedunits = sum(dgrade2*unit), by(candidate)
gen totalmeritorhigherunits = totaldistinctionunits + totalmeritunits
gen totalpassorhigherunits = totalmeritorhigherunits + totalpassunits

// 5.3.1 For Distinction

//   5.3.1a Distinction in 3.0 or more
replace award = 5 if (totaldistinctionunits >= 3.0) & award==.
replace rule = "5.3.1a" if (totaldistinctionunits >= 3.0) & rule==""

//   5.3.1b Distinction in 2.5 and merit in 1.0 or more
replace award = 5 if (totaldistinctionunits >= 2.5 & totalmeritunits>=1.0) & award==.
replace rule = "5.3.1b" if (totaldistinctionunits >= 2.5 & totalmeritunits>=1.0) & rule==""

// 5.3.2 For Distinction or Merit according to local rules
// note: subtracting the compensatedgrade==1 sd reduce distinction to merit
// local rules:
//   Classification for students with mark profiles falling into this range will be determined 
//   according to an aggregate formula: Distinction if aggregate is 270 or higher.

//   5.3.2.c
// JK
// replace award = 5 if (totaldistinctionunits >= 2.5 & totalmeritunits>=0.5) & award==.
// replace rule = "5.3.2c" if (totaldistinctionunits >= 2.5 & totalmeritunits>=0.5) & rule==""
replace award = 5 if (totaldistinctionunits >= 2.5 & totalmeritunits>=0.5 & aggregate >= $aggregate_DMborderline) & award==.
replace rule = "5.3.2c" if (totaldistinctionunits >= 2.5 & totalmeritunits>=0.5 & aggregate >= $aggregate_DMborderline) & rule==""
replace award = 4 if (totaldistinctionunits >= 2.5 & totalmeritunits>=0.5 & aggregate < $aggregate_DMborderline) & award==.
replace rule = "5.3.2c" if (totaldistinctionunits >= 2.5 & totalmeritunits>=0.5 & aggregate < $aggregate_DMborderline) & rule==""

//   5.3.2.d
replace award = 5 if (totaldistinctionunits >= 2.0 & totalmeritunits>=1.0 & aggregate >=$aggregate_DMborderline) & award==.
replace rule = "5.3.2d" if (totaldistinctionunits >= 2.0 & totalmeritunits>=1.0 & aggregate >=$aggregate_DMborderline) & rule==""
// JK
replace award = 4 if (totaldistinctionunits >= 2.0 & totalmeritunits>=1.0) & award==.
replace rule = "5.3.2d" if (totaldistinctionunits >= 2.0 & totalmeritunits>=1.0) & rule==""

// 5.3.3 For Merit
// note: subtracting the compensatedgrade==1 sd reduce distinction to merit

//   5.3.3.e
replace award = 4 if (totaldistinctionunits >= 2.0) & award==.
replace rule = "5.3.2e" if (totaldistinctionunits >= 2.0) & rule==""

//   5.3.3.f
replace award = 4 if (totalmeritorhigherunits >= 3.0) & award==.
replace rule = "5.3.3f" if (totalmeritorhigherunits >= 3.0) & rule==""

//   5.3.3.g
// JK
// replace award = 4 if (totaldistinctionunits >= 0.5 & totalmeritunits >= 2.0) & award==.
// replace rule = "5.3.3g" if (totaldistinctionunits >= 0.5 & totalmeritunits >= 2.0) & rule==""
// -- Change below suggested by Sam Colegate from Geography
replace award = 4 if (totaldistinctionunits >= 0.5 & totalmeritorhigherunits >= 2.5) & award==.
replace rule = "5.3.3g" if (totaldistinctionunits >= 0.5 & totalmeritorhigherunits >= 2.5) & rule==""
//
// JK: This is the one where I mentioned the rule itself is poorly worded. 
//     The question is: What happens to a student who gets 1D + 1.5M or 1.5D + 1M? 
//     With the first bit of code these are covered by 5.3.3g, as they clearly should (since they are strictly 
//     better than 0.5D + 2M, which is the only case that a literal reading of 5.3.3g seems to cover). 
//     Otherwise they are not.


// 5.3.4 Merit or Pass according to local rules
// note: subtracting the compensatedgrade==1 sd reduce distinction to merit
// local rules:
//   Classification for students with mark profiles falling into this range will be 
//   determined according to an aggregate formula: Merit if aggregate is 240 or higher.

//   5.3.4.h
// JK
//replace award = 4 if (totalmeritunits >= 2.5) & award==.
//replace rule = "5.3.4.h" if (totalmeritunits >= 2.5) & rule==""
replace award = 4 if (totalmeritunits >= 2.5 & aggregate >= $aggregate_MPborderline) & award==.
replace rule = "5.3.4.h" if (totalmeritunits >= 2.5 & aggregate >= $aggregate_MPborderline) & rule==""
replace award = 3 if (totalmeritunits >= 2.5) & award==.
replace rule = "5.3.4.h" if (totalmeritunits >= 2.5) & rule==""

//   5.3.4.i
// JK
//replace award = 4 if (totaldistinctionunits >= 0.5 & totalmeritunits>=1.0 & aggregate >=$aggregate_MPborderline) & award==.
//replace rule = "5.3.4.i" if (totaldistinctionunits >= 0.5 & totalmeritunits>=1.0 & aggregate >=$aggregate_MPborderline) & rule==""
replace award = 4 if (totaldistinctionunits >= 1 & totalmeritorhigherunits>=2 & aggregate >=$aggregate_MPborderline) & award==.
replace rule = "5.3.4.i" if (totaldistinctionunits >= 1 & totalmeritorhigherunits>=2 & aggregate >=$aggregate_MPborderline) & rule==""
replace award = 3 if (totaldistinctionunits >= 1 & totalmeritorhigherunits>=2) & award==.
replace rule = "5.3.4.i" if (totaldistinctionunits >= 1 & totalmeritorhigherunits>=2) & rule==""

// 5.3.5 For Pass

//   5.3.5.j
replace award = 3 if (totalpassorhigherunits >= 3.5) & award==.
// JK
// replace rule = "5.3.4.j" if (totalpassorhigherunits >= 3.5) & rule==""
replace rule = "5.3.5.j" if (totalpassorhigherunits >= 3.5) & rule==""

//   5.3.5.k
replace award = 3 if (totalpassorhigherunits >= 3.0 & compensatedfail==1) & award==.
// JK
// replace rule = "5.3.4.k" if (totalpassorhigherunits >= 3.0 & compensatedfail==1) & rule==""
replace rule = "5.3.5.k" if (totalpassorhigherunits >= 3.0 & compensatedfail==1) & rule==""

// Lower mark one grade as per 5.2.3 if a fail was compensated
// JK
//replace award = award - compensatedfail if rule != "5.3.4.k" & award>3
//replace rule = rule + ", 5.2.3comp" if compensatedfail==1 & rule != "5.3.4.k" & award>3
replace rule = rule + ", 5.2.3penalty" if compensatedfail==1 & award>3
replace award = award - compensatedfail if award>3

// JK
// Overall award is Fail, not Bad fail
replace award = 2 if award==1

// Check to see if total marks are (at least) 4.0
replace unit = . if mark==.
egen totalcredit = sum(unit), by(candidate)

// reshape dataset to "wide" format
// JK: some changes to formatting
keep course candidate mark award* rule* compensatedfail totalcredit totaldistinctionunits totalmeritunits /// 
	totalpassunits totalfailedunits totalbadfailunits aggregate 
rename mark m
* reshape wide m, i(candidate award* rule* totalcredit totaldistinctionunits totalmeritunits /// 
*	totalpassunits totalfailedunits totalbadfailunits compensatedfail) j(course) string
reshape wide m, i(candidate award* rule* comp aggregate) j(course) string
rename totalmeritunits Merit
rename totalpassunits Pass
rename totalfailedunits Fail
rename totalbadfailunits BadFail
rename compensatedfail CompFail
gen bestdiss = ""
gen bestovrl = ""
gsort -mMY499
replace bestdiss="*" if mMY499==mMY499[1]
gsort -totaldistinctionunits
replace bestovrl="*" if totaldistinctionunits==totaldistinctionunits[1]
sort candidate
rename totaldistinctionunits Dist
order candidate totalcredit aggregate award rule best* mMY499 Dist Merit Pass Fail BadFail CompFail m*
format %3.1f aggregate

export excel using $output_excel_filename, firstrow(variables) replace
browse candidate totalcredit aggregate award rule best* mMY499 Dist Merit Pass Fail BadFail CompFail
