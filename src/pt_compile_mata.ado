* Check if we need to recompile the library for a certain package

* USAGE:

* (1) in <mypack.mata>:
*    	mata: string scalar mypack_version() return("1.2.3 31dec2017")
*    	mata: string scalar mypack_stata_version() return("`c(stata_version)'")

* (2) in <mypack.ado>
*		pt_compile_mata, package(mypack) version(1.2.3 31dec2017)

* This is based on code from David Roodman's -boottest-


cap pr drop pt_compile_mata
program pt_compile_mata
	syntax, PACKage(string) VERSion(string) VERBOSE FORCE
	loc force = ("`force'" != "")

	if (!`force') {
		Check, package(`package') version(`version') `verbose'
		loc force = s(needs_compile)
	}

	if (`force') {
		Compile, package(`package') version(`version') `verbose'
	}
end


cap pr drop Check
progrma Check, sclass
	syntax, PACKage(string) VERSion(string) VERBOSE
	loc verbose = ("`verbose'" != "")

	loc package_version = "`version'"
	loc stata_version = c(stata_version)
	
	loc mlib_package_version = "???"
	loc mlib_stata_version = "???"

	cap mata: mata drop `package'_stata_version()
	cap mata: mata drop `package'_version()

	cap mata: st_local("mlib_stata_version", `package'_stata_version())
	_assert inlist(`c(rc)', 0, 3499), msg("`package' check: unexpected error")
	
	cap mata: st_local("mlib_package_version", package_version())
	_assert inlist(`c(rc)', 0, 3499), msg("`package' check: unexpected error")
	
	if ("`mlib_stata_version'" != "`stata_version'") {
		if (`verbose') di as text "(existing l`package'.mlib compiled with Stata `mlib_stata_version'; need to recompile for Stata `stata_version')"
		sreturn local needs_compile = 1
		exit
	}

	if ("`mlib_package_version'" != "`package_version'")) {
		if (`verbose') di as text "(existing l`package'.mlib is version `mlib_abcreg_version'; need to recompile for `abcreg_version')"
		sreturn local needs_compile = 1
		exit
	}
end


cap pr drop Compile
program Compile
	syntax, PACKage(string) VERSion(string) VERBOSE
	loc verbose = ("`verbose'" != "")

	clear mata
	
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

	mata: mata desc // remove
	//mata: mata drop HDFE() // WHY DO I NEED TO DO THIS? IS IT A BUG IN MATA?
	//mata: mata drop hdfe() // WHY DO I NEED TO DO THIS? IS IT A BUG IN MATA?

	* Find out where can I save the .mlib
	loc path = c(sysdir_plus)
	loc random_file = "`=int(runiform()*1e8)'"
	cap conf new file "`path'" + "`random_file'"
	if (c(rc)) {
		di as error `"cannot save compiled Mata file in sysdir_plus (`path'); saving in ".""'
		loc path "."
	}
	else {
		loc path = "`path'l"
		cap conf new file "`path'" + "`random_file'"
		if (c(rc)) {
			mkdir "`path'"
		}
	}

	* Create .mlib
	qui mata: mata mlib create l`package'  , dir("`path'") replace
	qui mata: mata mlib add l`package' *() , dir("`path'") complete
	//qui mata: mata mlib add l`package' HDFE() , dir("`path'") complete
	
	* Verify file exists and works correctly
	qui findfile l`package'.mlib
	loc fn `r(fn)'
	if (`verbose') di as text `"(library saved in `fn')"'
	qui mata: mata mlib index
	if (`verbose') mata: mata describe using `package'
end
