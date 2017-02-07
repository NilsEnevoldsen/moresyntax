`moresyntax` is a Stata package that provides extra parsing tools, on top of what `syntax`, `gettoken`, etc. provide.

It is used internally by `reghdfe` and `abcreg`.

Before using a program from here, check that what you want is not already in Stata,
either undocumented (`help undocumented`) or within the `base/_/` folder (e.g. `_parse_initial.ado`, `_prefix_note.ado`).


# Components

- `ms_get_version`: returns the version indicated in the starbang line of a given ado
- `ms_compile_mata`: compile the `mlib` file of a package, if required.
- `ms_fvunab`: Variant of `fvunab` that does not expand "x##y" into "x y x#y". Also does not expand "x#y" into "i.x#i.y"
- `ms_fvstrip`: (by Mark E. Schaffer) See https://github.com/markeschaffer/stata-utilities/blob/master/fvstrip.md
- `ms_parse_absvars`: USAGE: `ms_parse_absvars FE1=var1#var2 i.var3 i.var4#(c.var5 c.var6) , savefe`
- `ms_parse_varlist`: USAGE:
- `ms_parse_vce`: USAGE:


# Installation

## Stable Version

TBD

## Dev Version

```
cap ado uninstall moresyntax
net install moresyntax, from(https://github.com/sergiocorreia/moresyntax/raw/master/src/)
```


## Installing local versions

To install from a git fork, type something like:

```
cap ado uninstall moresyntax
net install moresyntax, from("C:/git/moresyntax/src")
```
