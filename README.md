examboard
=========

Award MSc degree marks according to LSE rules outlined in http://www.lse.ac.uk/resources/calendar/academicRegulations/TaughtMastersDegreesFourUnits.htm.

Program file
------------
This is the file [MSc_exam_board.do](https://github.com/kbenoit/examboard/blob/master/MSc_exam_board.do) which is written in Stata 11.  
You will need to modify this file to make it work for your own exam board.
Modifications are clearly indicated in the code comments and especially where it states "LOCAL RULES".


Input data
----------
Marks need to be prepared into one table, and can be either in long or wide format.  See 
[MSc_marks_example_wide.dta]((https://github.com/kbenoit/examboard/blob/master/MSc_marks_example_wide.dta) and 
[MSc_marks_example_long.dta]((https://github.com/kbenoit/examboard/blob/master/MSc_marks_example_wide.dta).

for example data.

output data
-----------
Set by the global *output_excel_filename*, this produces an Excel spreadsheet with the mark results, auxiliary information, 
and indications of who was top (or tied for top) in both the distiction marks categories (*bestovrl*) and best dissertation prize
(*bestdiss*).


contributors
------------
Kenneth Benoit (kbenoit@lse.ac.uk) with revisions by Jouni Kuha (J.Kuha@lse.ac.uk).


