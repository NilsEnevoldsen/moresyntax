cap pr drop ms_parse_absvars
program ms_parse_absvars, sclass
	syntax anything(id="absvars" name=absvars equalok everything), ///
		[NOIsily] /// passed to -ms_fvunab-
		[SAVEfe Generate] // Synonyms

	loc save_all_fe = ("`savefe'" != "") | ("`generate'" != "")

* Unabbreviate variables and trim spaces
	ms_fvunab `absvars', `noisily' target stringok
	loc absvars `s(varlist)'
	loc base_absvars `s(basevars)'

* Count the number of absvars
	loc G 0
	loc absvars_copy `absvars'
	while ("`absvars_copy'" != "") {
		loc ++G
		gettoken absvar absvars_copy : absvars_copy, bind
	}

* For each absvar, get the ivars and cvars (slope variables),
* and whether the absvar has an intercept or is slopes-only

	loc g 0
	loc any_has_intercept 0
	loc equation_d_is_valid 1
	loc save_any_fe 0

	while ("`absvars'" != "") {
		loc ++g
		gettoken absvar absvars : absvars, bind

		* Extract or create the target variable for the FE (optional)
		ParseTarget `absvar' // updates `target' and `absvar'
		if (`save_all_fe' & "`target'" == "") loc target __hdfe`g'__

		* Extract intercept and slope elements of the absvar
		cap conf str var `absvar'
		if (c(rc)) {
			ParseAbsvar `absvar' // updates `ivars' `cvars' `has_intercept'
		}
		else {
			ParseStringAbsvar `absvar'
		}
		if (`has_intercept') loc any_has_intercept 1
		loc num_slopes : word count `cvars'

		* Create a nice canonical label for the absvar
		loc baselabel : subinstr loc ivars " " "#", all
		loc sep = cond(`has_intercept', "##", "#")
		if (`num_slopes' == 1) {
			loc label `baselabel'`sep'c.`cvars'
		}
		else if (`num_slopes' > 1) {
			loc label `baselabel'`sep'c.(`cvars')
		}
		else {
			loc label `baselabel'
		}

		* Construct expanded labels (used by the output tables)
		* EXAMPLE: i.x##c.(y z) --> i.x i.x#c.y i.x#c.z
		if (`has_intercept') loc extended `extended' `baselabel'
		foreach cvar of local cvars {
			loc extended `extended' `baselabel'#c.`cvar'
		}

		* Update locals
		loc all_num_slopes "`all_num_slopes' `num_slopes'"
		loc all_has_intercept "`all_has_intercept' `has_intercept'"
		loc all_ivars `"`all_ivars' "`ivars'""'
		loc all_cvars `"`all_cvars' "`cvars'""'
		loc all_absvars `"`all_absvars' "`absvar'""'

		* Store target variables including slopes
		if ("`target'" != "") {
			loc save_any_fe 1

			loc targetleft
			loc targetright
			if (`has_intercept') loc targetleft `target'
			if (`num_slopes' > 0) {
				mata: st_local("targetright", invtokens(J(1, `num_slopes', "`target'_Slope") + strofreal(1..`num_slopes')))
			}
			loc all_targets `"`all_targets' "`targetleft' `targetright'""'

			* Build the absvar equation; assert that we can create the new vars
			if (`has_intercept') {
				loc equation_d `equation_d' + `target'
				conf new var `target'
			}
			forval h = 1/`num_slopes' {
				conf new var `target'_Slope`h'
				loc cvar : word `h' of `cvars'
				loc equation_d `equation_d' + `target'_Slope`h' * `cvar'
			}
		}
		else {
			loc equation_d_is_valid 0
			loc all_targets `"`all_targets' """'
		}

	}

	* Remove the trailing + in equation_d (Stata rejects "gen x = + y")
	gettoken _ equation_d : equation_d // trim leading +
	loc equation_d `equation_d' // trim leading whitespace
	if (!`equation_d_is_valid') loc equation_d // clear it

	sreturn clear
	sreturn loc equation_d "`equation_d'"
	sreturn loc extended_absvars "`extended'"
	sreturn loc num_slopes = "`all_num_slopes'"
	sreturn loc intercepts = "`all_has_intercept'"
	sreturn loc targets = `"`all_targets'"'
	sreturn loc cvars = `"`all_cvars'"'
	sreturn loc ivars = `"`all_ivars'"'
	sreturn loc absvars = `"`all_absvars'"'
	sreturn loc save_all_fe = `save_all_fe'
	sreturn loc save_any_fe = `save_any_fe'
	sreturn loc has_intercept = `any_has_intercept'
	sreturn loc G = `G'
end


cap pr drop ParseTarget
pr ParseTarget
	if strpos("`0'", "=") {
		gettoken target 0 : 0, parse("=")
		_assert ("`target'" != "")
		conf new var `target'
		gettoken eqsign 0 : 0, parse("=")
	}
	c_local absvar `0'
	c_local target `target'
end

cap pr drop ParseStringAbsvar
pr ParseStringAbsvar
	syntax varname(str)
	c_local ivars `varlist'
	c_local cvars
	c_local has_intercept 1
end

cap pr drop ParseAbsvar
pr ParseAbsvar
	* Add i. prefix in case there is none
	loc hasdot = strpos("`0'", ".")
	loc haspound = strpos("`0'", "#")
	if (!`hasdot' & !`haspound') loc 0 i.`0'

	* Expand absvar:
	* x#c.z			--->							i.x#c.z
	* x##c.z		--->	i.x			z			i.x#c.z
	* x##c.(z w) 	--->	i.x			z		w 	i.x#c.z		i.x#c.w
	* x#y##c.z		--->	i.x#i.y 	z			i.x#i.y#c.z
	* x#y##c.(z w)	--->	i.x#i.y 	z		w	i.x#i.y#c.z	i.x#i.y#c.w
	syntax varlist(numeric fv)

	* Iterate over every factor of the extended absvar
	loc has_intercept 0 // 1 if there is a "factor" w/out a "c." part
	foreach factor of loc varlist {
		if (!strpos("`factor'", ".")) continue // ignore the "z", "w" cases
		ParseFactor `factor' // updates `factor_ivars' `factor_cvars'
		loc ivars `ivars' `factor_ivars'
		loc cvars `cvars' `factor_cvars'
		if ("`factor_cvars'" == "") loc has_intercept 1
	}

	loc ivars : list uniq ivars
	loc unique_cvars : list uniq cvars
	_assert ("`ivars'" != ""), ///
		msg("no indicator variables in absvar <`0'> (extended to `varlist')")
	_assert (`: list unique_cvars == cvars'), ///
		msg("duplicated c. variable in absvar <`0'> (extended to `varlist')")

	c_local ivars `ivars'
	c_local cvars `cvars'
	c_local has_intercept `has_intercept'
end


cap pr drop ParseFactor
pr ParseFactor
	loc 0 : subinstr loc 0 "#" " ", all
	foreach part of loc 0 {
		_assert strpos("`part'", ".")
		loc first_char = substr("`part'", 1, 1)
		_assert inlist("`first_char'", "c", "i")
		gettoken prefix part : part, parse(".")
		gettoken dot part : part, parse(".")
		_assert ("`dot'" == ".")
		if ("`first_char'" == "c") {
			loc cvars `cvars' `part'
		}
		else {
			loc ivars `ivars' `part'
		}
	}
	c_local factor_ivars `ivars'
	c_local factor_cvars `cvars'
end
