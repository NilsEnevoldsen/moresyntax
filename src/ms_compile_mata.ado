* Check if we need to recompile the library for a certain package

* USAGE:

* (1) in <MYPACKAGE.mata>:
*		pt_get_version MYADO // stores local `package_version' from the first line of MYADO.ado
*		assert("`package_version'" != "")
*	    mata: string scalar MYPACKAGE_version() return("`package_version'")
*	    mata: string scalar MYPACKAGE_stata_version() return("`c(stata_version)'")

* (2) In the first line of <MYADO.ado>
*		*! version 1.2.3 31dec2017 abc

* (3) afterwards in <MYADO.ado>
*		pt_get_version MYADO
*		pt_compile_mata, package(MYPACKAGE) version(`package_version')

* Note: MYADO can be the same as MYPACKAGE
* Note: pt_compile_mata accepts more options: functions(...) verbose force
* Acknowledgment: his is based on code from David Roodman's -boottest-


cap pr drop pt_compile_mata
program pt_compile_mata
	syntax, PACKage(string) VERSion(string) [FUNctions(string)] [VERBOSE] [FORCE] [DEBUG]
	loc force = ("`force'" != "")

	if (!`force') {
		Check, package(`package') version(`version') `verbose'
		loc force = s(needs_compile)
	}

	if (`force') {
		Compile, package(`package') version(`version') functions(`functions') `verbose' `debug'
	}
end


cap pr drop Check
program Check, sclass
	syntax, PACKage(string) VERSion(string) [VERBOSE]
	loc verbose = ("`verbose'" != "")

	loc package_version = "`version'"
	loc stata_version = c(stata_version)
	
	loc mlib_package_version = "???"
	loc mlib_stata_version = "???"

	cap mata: mata drop `package'_stata_version()
	cap mata: mata drop `package'_version()

	cap mata: st_local("mlib_stata_version", `package'_stata_version())
	_assert inlist(`c(rc)', 0, 3499), msg("`package' check: unexpected error")
	
	cap mata: st_local("mlib_package_version", `package'_version())
	_assert inlist(`c(rc)', 0, 3499), msg("`package' check: unexpected error")

	if ("`mlib_stata_version'" != "`stata_version'") {
		if (`verbose') di as text "(existing l`package'.mlib compiled with Stata `mlib_stata_version'; need to recompile for Stata `stata_version')"
		sreturn local needs_compile = 1
		exit
	}

	if ("`mlib_package_version'" != "`package_version'") {
		if (`verbose') di as text `"(existing l`package'.mlib is version "`mlib_package_version'"; need to recompile for "`package_version'")"'
		sreturn local needs_compile = 1
		exit
	}
	
	sreturn local needs_compile = 0
end


cap pr drop Compile
program Compile
	syntax, PACKage(string) VERSion(string) [FUNctions(string)] [VERBOSE] [DEBUG]
	loc verbose = ("`verbose'" != "")
	loc debug = ("`debug'" != "")
	if ("`functions'"=="") loc functions "*()"

	loc stata_version = c(stata_version)

	mata: mata clear
	
	* Delete any preexisting .mlib
	loc mlib "l`package'.mlib"
	cap findfile "`mlib'"
	while !_rc {
	        erase "`r(fn)'"
	        cap findfile "`mlib'"
	}

	* Run .mata
	if (`verbose') di as text "(compiling l`package'.mlib for Stata `stata_version')"
	qui findfile "`package'.mata"
	loc fn "`r(fn)'"
	run "`fn'"

	// Remove this ?
	if (`debug') di as error "Functions available for indexing:"
	if (`debug') mata: mata desc


	* Find out where can I save the .mlib
	loc path = c(sysdir_plus)
	loc random_file = "`=int(runiform()*1e8)'"
	cap conf new file "`path'`random_file'"
	if (c(rc)) {
		di as error `"cannot save compiled Mata file in sysdir_plus (`path'); saving in ".""'
		loc path "."
	}
	else {
		loc path = "`path'l"
		cap conf new file "`path'`random_file'"
		if (c(rc)) {
			mkdir "`path'"
		}
	}

	* Create .mlib
	qui mata: mata mlib create l`package'  , dir("`path'") replace
	qui mata: mata mlib add l`package' `functions', dir("`path'") complete
	//qui mata: mata mlib add l`package' HDFE() , dir("`path'") complete
	
	* Verify file exists and works correctly
	qui findfile l`package'.mlib
	loc fn `r(fn)'
	if (`verbose') di as text `"(library saved in `fn')"'
	qui mata: mata mlib index

	// Remove this?
	if (`debug') di as error "Functions indexed:"
	if (`debug') mata: mata describe using l`package'
end
