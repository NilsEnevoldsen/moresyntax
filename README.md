# Components

`pt_get_version`
: returns the version indicated in the starbang line of a given ado
`pt_compile_mata`
: compile the `mlib` file of a package, if required.
`pt_fvunab`
: Variant of `fvunab` that does not expand "x##y" into "x y x#y". Also does not expand "x#y" into "i.x#i.y"
`pt_parse_absvars`
: USAGE: `pt_parse_absvars FE1=var1#var2 i.var3 i.var4#(c.var5 c.var6) , savefe`
`pt_parse_varlist`
: USAGE:
`pt_parse_vce`
: USAGE:
`pt_fvstrip`
: See https://github.com/markeschaffer/stata-utilities



# Installation

## Stable Version

TBD

## Dev Version

```
cap ado uninstall parsetools
net install parsetools, from(https://github.com/sergiocorreia/parsetools/raw/master/src/)
```


## Installing local versions

To install from a git fork, type something like:

```
cap ado uninstall parsetools
net install parsetools, from("C:/git/parsetools/src")
```

