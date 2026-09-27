# tflspec 0.0.5

* **`library(tflspec)` is enough**: rtfreporter moved from `Imports` to
  `Depends`, so attaching tflspec attaches rtfreporter too.  tflspec
  extends rtfreporter (a plan is one of its table sources), which is the
  case `Depends` is for.  Code written for the rtfreporter branch needs
  `library(tflspec)` and nothing else, unless it calls the moved functions
  as `rtfreporter::` (now `tflspec::`).
* R CMD check (`--as-cran`) runs on GitHub Actions: ubuntu devel / release
  / oldrel-1, macOS, Windows.

# tflspec 0.0.4

* **The ARD spec engine moved here from tflplanner**: an Excel definition of
  the study's analyses (`study`, `datasets`, `populations`, `analyses`) ->
  cards / cardx code -> the study ARD.  `ard_spec()`, `read_ard_spec()`,
  `write_ard_spec()`, `ard_spec_code()`, `build_ard()`, `ard_for()`, and the
  catalogs `ard_methods()` / `ard_statistics()`.  New: `ard_spec_template()`,
  `ard_spec_hash()` (was internal), and `ard_spec_code(part = "setup" /
  "body")` for a program layout of one's own.
* The catalogs have built-in defaults here; a company's own are passed as
  `statistics =` / `methods =` to the functions that use them (tflplanner
  passes its company standards), or set with
  `options(tflspec.ard_statistics =, tflspec.ard_methods =)`.
* **Listing code** moved from tflplanner too: `listing_spec_code()` writes a
  listing's program from its definition rows, and `read_data_code()` the
  lines that read a dataset of the data catalog.  The layout itself stays
  rtfreporter's (`listing_spec()`, `as_rtftables(listing = )`).
* Verified: tflplanner's generated ARD programs, report programs, listing
  code and ARD status for two studies are identical before and after the
  move (104 / 104).

# tflspec 0.0.3

* **plotplanner is now tflspec.** The repository and package were renamed
  when the table half joined, so one package holds the Excel specifications
  for tables, listings and figures.  Options `plotplanner.*` are now
  `tflspec.*`.
* **The ARD / plan / spec family moved here from rtfreporter**
  (ichirio/rtfreporter#474, branch `feat/474-ard-experimental` at 2d608cc):
  `ard_*()`, `rtf_plan()` and the `plan_*()` verbs, `apply_plan()`,
  `table_spec()` / `read_table_spec()` / `write_table_spec()` /
  `as_table_spec()`, and `read_report_spec()` / `rtf_report()` /
  `report_path()`, together with their tests, the example workbooks
  (`inst/extdata/ard-spec/`) and their builders (`data-raw/`).  The code is
  unchanged apart from names: generated scripts now say `tflspec::`, and the
  pipe option is `tflspec.ard_pipe`.  Rounding still follows rtfreporter's
  `round_num()` and `rtfreporter.rounding`.
* A plan is a table source for rtfreporter: tflspec registers
  `as_rtftables.rtf_plan()` on rtfreporter's `as_rtftables()` generic
  (rtfreporter >= 0.8.0.9085), so `rtf_tables(doc, plan)` works as it did on
  the branch.
* Verified against the branch: the same 735 tests pass, and the five example
  reports (DM, AE, ORR, LB, PK) give byte-identical RTF, from both the plan
  code and the Excel spec.
