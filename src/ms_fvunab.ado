/* MS_FVUNAB

Description:
	Variant of -fvunab- that does not expand "x##y" into "x y x#y"
	Also does not expand "x#y" into "i.x#i.y"

Example:
	sysuse auto
	ms_fvunab F2.pri   tu##c.L.trun#ibn.foreign (pri	= tu##for#c.pri) weigh
	di "`s(varlist)'"
*/

program ms_fvunab, sclass
	sreturn clear
	syntax anything(name=remainder equalok) [, NOIsily TARGET STRingok]

* Trim spaces around equal signs ("= ", " =", "  =   ", etc)
	while (regexm("`remainder'", "[ ][ ]+")) {
		loc remainder : subinstr loc remainder "  " " ", all
	}
	loc remainder : subinstr loc remainder " =" "=", all
	loc remainder : subinstr loc remainder "= " "=", all
	
* Expand variable names
	loc is_numlist 0 // Will match inside L(1 2 3) or L(-1/1)
	while ("`remainder'" != "") {
		* gettoken won't place spaces in 0;
		* but we can see if a space is coming with `next_char'
		gettoken 0 remainder: remainder, parse(" #.()=")

		// bug in Stata v12 and older
		// version 12
		// loc x = substr(" ", 1, 1)
		// assert "`x'"==" "

		// bugged code in v12:
		// loc next_char = substr("`remainder'", 1, 1)

		// workaround:
		loc next_char `"`=substr("`remainder'", 1, 1)'"'
		
		* Match common delimiters
		loc delim1 = inlist("`0'", "#", ".", "(", ")", "=")

		* Match "i" and "L" in "i.turn L(1 2)"
		loc delim2 = inlist("`next_char'", ".", "(")
		
		* deal with newvar
		if ("`target'" != "") & ("`next_char'" == "=") {
			syntax newvarname
			loc 0 `varlist'
		}
		* If we know its a variable, parse it
		else if !(`delim1' | `delim2' | `is_numlist') {
			
			if ("`stringok'" != "") {
				cap syntax varlist(numeric fv ts)	
				if (c(rc)==109) {
					syntax varlist
				}
				else {
					syntax varlist(numeric fv ts) // will raise error
				}
				loc stringvars `stringvars' `varlist'
			}
			else {
				syntax varlist(numeric fv ts)
			}

			loc 0 `varlist'
			loc unique `unique' `varlist'
		}
		if ("`0'" == ")") loc is_numlist 0
		if ("`0'" != "." & "`next_char'" == "(") loc is_numlist 1
		
		if ("`next_char'" != " ") loc next_char // add back spaces
		loc answer "`answer'`0'`next_char'"
		if ("`noisily'" != "") di as result "{bf:`answer'}"
	}
	local unique : list uniq unique
	local stringvars : list uniq stringvars
	sreturn local basevars `unique' // similar to fvrevar,list
	sreturn local stringvars `stringvars'
	sreturn local varlist `answer'
end
