`moresyntax` is a Stata package with several parsing commands, on top of what `syntax`, `gettoken`, etc. provide.

It is used internally by `ftools`, `reghdfe` and `abcreg`.

Before using `moresyntax`, check that what you want is not already in Stata,
either undocumented (`help undocumented`) or within the `base/_/` folder (e.g. `_parse_initial.ado`, `_prefix_note.ado`).


# Commands

- `ms_get_version`: returns the version indicated in the starbang line of an ado
- `ms_compile_mata`: compile the `mlib` file of a Mata package, if required.
- `ms_fvunab`: Variant of `fvunab` that does not expand "x##y" into "x y x#y". Also does not expand "x#y" into "i.x#i.y"
- `ms_fvstrip`: (by Mark E. Schaffer) See https://github.com/markeschaffer/stata-utilities/blob/master/fvstrip.md
- `ms_parse_absvars`: Parse the contents of `absorb(...)`
- `ms_parse_varlist`: Parse a regression varlist `y x1 x2 (x3 = z1 z2)`
- `ms_parse_vce`: Parsae the contents of `vce(...)`


# Installation

## Stable Version

```
cap ado uninstall moresyntax
ssc install moresyntax
```

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
