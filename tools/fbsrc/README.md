# tools/fbsrc — BASIC-source tooling

Three tools for working out what a GEF BASIC line computes. Run them from the repository
root:

| Tool | Purpose |
|---|---|
| `python3 -m tools.fbsrc.emit_c` | Translate the BASIC source to C with the pinned fbc |
| `python3 -m tools.fbsrc.fbline` | Show BASIC line(s) next to the C generated from them |
| `python3 -m tools.fbsrc.fbdef` | Find where a symbol is defined, and optionally every reference |

Requirements: fbc 1.10.1 (found through `GEF_FBC` or the default path, see
`tools/toolchain/fbc.py`), Universal Ctags, `git`, and GNU `patch` for `--patch-dir`.
The submodule `Reference/GEF_code/` is only read, never written.

## emit_c

```
python3 -m tools.fbsrc.emit_c [--patch-dir DIR] [--force]
```

1. Copies `Reference/GEF_code/source/` to `build/fbsrc/<key>/src/`.
2. Applies the patch directory, if given, to the copy.
3. Runs `fbc -gen gcc -R -g -c GEF.bas` in the copy. `-R` keeps the generated `GEF.c`
   next to `GEF.bas`; `-c` also compiles it to `GEF.o`, which stays as a by-product.
4. Writes `build/fbsrc/<key>/manifest.json` last. If the manifest is present, the
   emission is complete.

An emission is reused if its manifest is valid, it matches the request (key, submodule
commit, patch hash, fbc version), and `GEF.c` still has the recorded SHA-256. `--force`
re-emits anyway. A failed emission removes its directory. Concurrent runs are serialised
by `build/fbsrc/.emit.lock`.

**Key.** `<key>` is the short submodule revision (`git -C Reference/GEF_code rev-parse
--short HEAD`, e.g. `ba9f0aa`). A patched emission adds `-p<first 12 hex of the patch
hash>`, so patched and unpatched emissions never share a directory. If
`Reference/GEF_code/source/` has local changes, emission is refused, because the key would
not describe the source. Put such changes in a patch directory instead.

**Determinism.** GEF embeds a compile time stamp (`__DATE_ISO__`/`__TIME__` in
`Compilationstamp`). fbc honours `SOURCE_DATE_EPOCH`, so emit_c sets it to the submodule
commit time (recorded as `source_date_epoch`). With that, re-emitting into the same
directory gives a byte-identical `GEF.c`. fbc writes the `#line` paths of *included*
files as absolute paths inside the emission directory (`GEF.bas` itself stays relative),
so the raw hash also depends on that directory. `gef_c_sha256_normalised` hashes the file
with the `"<src dir>/` prefix removed. Use it to compare emissions made in different
directories, e.g. patched against unpatched.

**Manifest fields:** `schema`, `key`, `submodule_revision`, `submodule_commit`,
`patch_dir`, `patch_dir_sha256`, `patches`, `source_date_epoch`, `fbc_path`,
`fbc_version`, `command` (full argv), `cwd`, `gef_c` (relative to the key directory),
`gef_c_sha256`, `gef_c_sha256_normalised`, `fbc_wall_time_s`, `total_wall_time_s`,
`fbc_diagnostics` (fbc stdout/stderr without the known harmless `libtinfo`/`ospeed`
loader warnings), `created_utc`.

### Patch-directory format

The patch directory holds unified diffs named `*.patch` or `*.diff`. Any other entry is an
error, so a misnamed patch cannot be silently skipped. The diffs are applied in
lexicographic file-name order with
`patch -p1 --batch --forward --no-backup-if-mismatch` inside the copied `src/`. Paths
therefore carry one leading component, relative to the source directory:

```
--- a/GEF.bas
+++ b/GEF.bas
@@ -8389,7 +8389,7 @@
```

Ways to produce such a diff: `diff -u a/GEF.bas b/GEF.bas` on two copies, `git diff
--no-index`, or Python's `difflib.unified_diff(..., "a/GEF.bas", "b/GEF.bas")`. A diff
can also create new files, such as an extra include. A hunk that does not apply fails
the emission. The patch hash covers file names and contents in application order.

Unified diffs were chosen over whole-file overlays for two reasons. Harness patches (M1)
are small, local changes to large files (GEF.bas is about 18 000 lines), and they are
committed and reviewed. A stale patch also fails loudly instead of silently reverting
upstream changes.

## fbline

```
python3 -m tools.fbsrc.fbline <file>:<line>[-<line>] [--context N] [--raw] [--symbols] [--patch-dir DIR]
```

If the C is missing, fbline emits it first through `emit_c`. It then prints the BASIC
line(s) and the C statements whose `#line` directive points at them. This works for the
main file and for included files (`Spectra.bas:1505`, `ENDF.bas:1170`). The file name is
matched case-insensitively. BASIC text comes from the submodule, or from the patched copy
when `--patch-dir` is given (the C then comes from that patched emission).

```
$ python3 -m tools.fbsrc.fbline GEF.bas:9417 --symbols
BASIC GEF.bas:9417  (Reference/GEF_code/source/GEF.bas)
> 9417  Egamma(Nspectrum) = Egamma(Nspectrum) + 1         ' 1 keV units
C build/fbsrc/ba9f0aa/src/GEF.c
  69070  [9417]  double vr1 = EGAMMA( NSPECTRUM$20 );
  69072  [9417]  EGAMMA( (int64)-((double)NSPECTRUM$20 == (vr1 + 0x1.p+0)) );
Symbols
  EGAMMA        Egamma     function Spectra.bas:1505 (+1 more)
  NSPECTRUM$20  Nspectrum  variable GEF.bas:9247
```

Output conventions:

- BASIC lines are dedented together; `>` marks the requested lines and `--context N`
  adds N unmarked lines on each side. Context adds BASIC lines only, not C.
- Each C line shows its 1-based line number in `GEF.c` and, in brackets, the BASIC line
  its `#line` directive points at. When the same BASIC line generates C in more than one
  place (loop heads and tails, procedure prologues), the separate regions are separated
  by `...`.
- A `#line` directive covers the C lines after it, up to the next directive. Coverage
  also stops at a blank line or at a top-level `struct`/`union`/`typedef`/`enum`.
- Default mode drops indentation, lone `{`/`}` and fbc's `//` echo of the BASIC text.
  It renames fbc temporaries in order of first appearance: `vr$19562` becomes `vr1`, and
  `TMP$57454$22` or `tmp$66811` becomes `tmp1`. Temporaries are never inlined: a
  temporary often holds a call result (an RNG draw, `EGAMMA(...)`), and inlining it
  would hide the evaluation order. Labels (`label$N`) keep their names, so `goto`s can
  still be followed.
- `--raw` prints the C lines exactly as generated, with tabs, `#line` directives and the
  `//` echo comment of the requested line.
- `--symbols` appends a legend. It maps each fbc-mangled BASIC name in the shown C to its
  BASIC spelling (taken from the shown BASIC lines, otherwise from the fbdef index) and
  to its first definition site. fbc mangling: `NAME$` is a `Dim Shared` / module-level
  global, `NAME$<n>` is a procedure- or block-local variable (scope number `n`), and a
  bare upper-case `NAME` is a procedure. Arrays keep a leading underscore (`_EGAMMA$`).

Exit status: 0 if C was found; 1 if the lines generated no C (a comment, a declaration
without code, an inactive `#If` branch, or a file not included in the compilation, such
as `NucPropJEFF311.bas`; the message says which); 2 on errors.

### Python interface (used by the QUIRKS verifier)

```python
from tools.fbsrc.fbline import lookup, parse_location, render

file, first, last = parse_location("GEF.bas:8392")
result = lookup(file, first, last, context=0, patch_dir=None)  # emits C if missing
result.basic          # ((line, text), ...) incl. context
result.statements()   # [CStatement(c_line, basic_line, text)] — text verbatim from GEF.c
result.regions        # CRegion(statements, raw) per contiguous run
result.file_compiled  # False if the file never appears in a #line directive
render(result, raw=False, symbols=False)  # the CLI text
```

`lookup` raises `tools.fbsrc.common.FbsrcError` for an unknown file, a line out of range,
or a failed emission.

## fbdef

```
python3 -m tools.fbsrc.fbdef <name> [--refs]
```

Looks up `<name>` case-insensitively in a symbol index of all 38 `.bas`/`.bi`/`.mac`
files in `Reference/GEF_code/source/`. Each match is printed as `file:line  kind  name
source-line`. Definitions come first, then `(ReDim)` entries, then `(declaration)`
entries (`Declare` statements). `--refs` adds every case-insensitive whole-word
occurrence (`file:line: text`), so `E_MIN` and `E_min` give the same list. Exit status: 0
if anything was found, 1 if nothing was, 2 on errors.

```
$ python3 -m tools.fbsrc.fbdef pgauss
GEF.bas:17956  function               PGauss               Public Function PGauss(Mean As Single,Sigma As Single) As Single
GEF.bas:676  function (declaration) PGauss               Declare Function PGauss(Mean As Single,Sigma As Single) As Single
```

Kinds: `function`, `label`, `variable`, `type`, `constant`, `macro` (and ctags' `enum`,
`namespace`, which GEF does not use).

**Index.** Universal Ctags runs with `--map-Basic=+.bi --map-Basic=+.mac`. The result is
cached in `build/fbsrc/ctags/index.json` and rebuilt when any source file's content, the
file set, the ctags version or the index schema changes. The ctags Basic parser misses
or misreads several GEF constructs, so the index is corrected by a scan of the code with
comments removed:

- ctags tags found inside comments are dropped (ctags reads `/' Note: '/` as a label).
  So are tags named after keywords (ctags tags `Const As Single pi` as a constant `As`).
- `Static` and `Const` declarators and `#Define`/`#Macro` names are added. ctags misses
  them, e.g. `E_MIN` (`Static`, GEF.bas:16662) and `Compilationstamp`.
- `ReDim` declarators of arrays with no other definition are added with role `redim`,
  e.g. `_EGamma` (Spectra.bas:1496). For these arrays `ReDim` is the definition.

**References** skip comments: `'` to end of line, `Rem` at the start of a statement, and
nested multi-line `/' ... '/` blocks. The comment scanner follows FreeBASIC's string
rules (`""` inside `"..."`, backslash escapes inside `!"..."`).

## build/ layout

```
build/fbsrc/
  .emit.lock                  serialises emissions
  <rev>/                      unpatched emission, e.g. ba9f0aa/
    manifest.json
    src/                      copy of Reference/GEF_code/source/ + GEF.c + GEF.o
  <rev>-p<hash12>/            one directory per distinct patch directory
  ctags/index.json            fbdef symbol index
```

Everything under `build/` is generated and gitignored. Old emissions are not pruned;
delete `build/fbsrc/` to start over.

## Known limitations

- `#line` granularity is one BASIC line. A line with several `:`-separated statements
  maps to all of their C together. A statement continued with `_` maps to the line fbc
  attributes it to, normally the first line of the statement.
- fbline shows only what fbc compiled. Code in an inactive `#If` branch produces no C, and
  so do files not included from `GEF.bas`.
- fbdef `--refs` is textual. It still finds names inside string literals, in inactive
  `#If` branches and as member names after `.`. It does not resolve scopes: every
  `I_MAT` in every procedure is the same name.
- fbdef's correction scan recognises declarations at the start of a statement only, not
  after `Then` on a single-line `If`.
- Emission needs a clean submodule checkout and Linux (`fcntl` lock, GNU `patch`).

## Tests

`pytest tools/fbsrc` checks the planning facts:

- `GEF.bas:8392` divides in `double` and narrows with `(float)`.
- `GEF.bas:9417` discards an `EGAMMA(...)` call with a comparison argument.
- `PGauss` → GEF.bas:17956, `calcstart` → label GEF.bas:4811, `E_tunn` → GEF.bas:791.
- Included files produce C.
- Re-emitting gives the same SHA-256.
- Patched emissions work.

Tests that need fbc are marked `fbc`; the re-emitting tests are also marked `slow`. A
session fixture shares one emission across the tests.
