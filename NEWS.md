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
