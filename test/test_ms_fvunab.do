cls
clear all
set more off

sysuse auto
pt_fvunab F2.pri   tu##c.L.trun#ibn.foreign (pri	= tu##for#c.pri) weigh
sreturn list
	
pt_fvunab FE=turn#tru, target
sreturn list

pt_fvunab pri tru#turn#fo A=ibn.pri, noi target
sreturn list

pt_fvunab make            turn, noi stringok
sreturn list

exit
