cap pr drop ms_parse_varlist
program ms_parse_varlist, sclass
	sreturn clear
	syntax anything(id="varlist" name=0 equalok)

	* SYNTAX: depvar indepvars [(endogvars = instruments)]
		 * depvar		: 	dependent variable
		 * indepvars	: 	included exogenous regressors
		 * endogvars	: 	included endogenous regressors
		 * instruments	: 	excluded exogenous regressors

	* NOTE: 
		* This must be run AFTER _fvunab

	ParseDepvar `0'
		* STORE: s(depvar) s(fe_format)
		* ALSO: s(rest)
	
	ParseIndepvars `s(rest)'
		* STORE: s(indepvars)
		* CLEAR: s(rest)
		* ALSO: s(parens)

	ParseEndogAndInstruments `s(parens)'
		* STORE: s(endogvars) s(instruments)
		* CLEAR: s(parens)

	sreturn loc varlist "`s(depvar)' `s(indepvars)' `s(endogvars)' `s(instruments)'"
end

cap pr drop ParseDepvar
pr ParseDepvar, sclass
	gettoken depvar 0 : 0, bind
	fvexpand `depvar'
	loc depvar `r(varlist)'
	loc n : word count `depvar'
	_assert (`n'==1), msg("more than one depvar specified: `depvar'")
	_assert (!strpos("`depvar'", "o.")), msg("the values of depvar are omitted: `depvar'")
	sreturn loc depvar `depvar'
	sreturn loc rest `0'

* Extract format of depvar so we can format FEs like this
	fvrevar `depvar', list
	loc fe_format : format `r(varlist)' // The format of the FEs that will be saved
	sreturn loc fe_format `fe_format'
end

cap pr drop ParseIndepvars
pr ParseIndepvars, sclass
	while ("`0'" != "") {
		gettoken _ 0 : 0, bind match(parens)
		if ("`parens'" == "") {
			loc indepvars `indepvars' `_'
		}
		else {
			continue, break
		}
	}
	sreturn loc indepvars `indepvars'
	if ("`parens'" != "") sreturn loc parens "`_'"
	_assert "`0'" == "", msg("couldn't parse the end of the varlist: <`0'>")
	sreturn loc rest // clear
end

cap pr drop ParseEndogAndInstruments
pr ParseEndogAndInstruments, sclass
	if ("`0'" == "") exit
	gettoken _ 0 : 0, bind parse("=")
	if ("`_'" != "=") {
		sreturn loc endogvars `_'
		gettoken equalsign 0 : 0, bind parse("=")
	}
	sreturn loc instruments `0'
	sreturn loc parens // clear
end
