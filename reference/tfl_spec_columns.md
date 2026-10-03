# What each column of a spec workbook means

The help the spec workbooks carry as comments on their header cells, as
one table: every column of every sheet – ARD, table, report and listing
– with the form of its value, its unit and what a blank cell means, and
an example. A row with no `column` describes the sheet; rows whose
`sheet` is in parentheses are about the whole workbook (`output_id`,
`note`, the tokens).

## Usage

``` r
tfl_spec_columns(sheet = NULL)
```

## Arguments

- sheet:

  Sheet names to keep the rows of, or `NULL` for every row. A row naming
  several sheets (`"titles / footnotes"`) is kept for each.

## Value

A data frame: `sheet`, `column`, `description`, `example`.

## Examples

``` r
head(tfl_spec_columns("tables"))
#>    sheet column
#> 1 tables   <NA>
#> 2 tables   cols
#> 3 tables   rows
#> 4 tables  label
#> 5 tables  stats
#> 6 tables  value
#>                                                                                                                       description
#> 1           Table: one row a report. Its roles (table_plan()) and the table-wide options; a verb written in code afterwards wins.
#> 2                                       The key spread across the columns, outermost first, | between them (table_plan(cols = )).
#> 3      The keys down the rows (table_plan(rows = )); name = column renames, a quoted value is a constant heading; | between them.
#> 4 Where the row label comes from (table_plan(label = )); blank: .label; NA: used to tell rows apart, not printed; NULL: not used.
#> 5          cells (cells built from templates) or rows (one statistic a row, the raw values) (plan_cells(stats = )); blank: cells.
#> 6                   With stats = rows: stat (the number) or stat_fmt (cards' formatted text) (plan_cells(value = )); blank: stat.
#>                                                  example
#> 1                                                   <NA>
#> 2                                      TRT01A | SEROSTAT
#> 3 group1 = AEBODSYS | grp = "Worst Post-Baseline Values"
#> 4                                        label = AEDECOD
#> 5                                                   rows
#> 6                                                   stat
tfl_spec_columns("analyses")
#>       sheet        column
#> 1  analyses          <NA>
#> 2  analyses   analysis_id
#> 3  analyses         label
#> 4  analyses        method
#> 5  analyses       dataset
#> 6  analyses population_id
#> 7  analyses         where
#> 8  analyses            by
#> 9  analyses        strata
#> 10 analyses     variables
#> 11 analyses    statistics
#> 12 analyses   denominator
#> 13 analyses       formats
#> 14 analyses          args
#> 15 analyses          code
#> 16 analyses       purpose
#> 17 analyses        reason
#>                                                                                                                                                                                                                                                                  description
#> 1                                                                                                                          ARD: one analysis a row; each becomes one cards / cardx call in the ARD program, its result tagged with output_id, analysis_id and population_id.
#> 2                                                                                                                                                                                                                        The analysis's id within its report; an ARD column.
#> 3                                                                                                                                                                                                                  A name a person reads (for ARS and the GUI); blank: none.
#> 4                                                                      What is computed: a keyword of tfl_ard_methods() (continuous, categorical, hierarchical ...), any pkg::function (cards::, cardx::), or a function of the study's own that the study key source loads.
#> 5                                                                                                                                                                                                                    The data analysed; blank: the population's own dataset.
#> 6                                                                                                                                                                      The analysis set: the data is restricted to its subjects; blank: no restriction (population is NULL).
#> 7                                                                                                                                                                                                An R condition on the data, applied after the population; blank: every row.
#> 8                                                                                                                                                                                                               Grouping variables (cards' by), | between them; blank: none.
#> 9                                                                                                                                                  Variables the analysis is repeated within (cards' strata: a subgroup, a parameter by visit), | between them; blank: none.
#> 10                                                                                                                                                                                                                The variables analysed (cards' variables), | between them.
#> 11                                                           For continuous / categorical / missing: the statistics computed, in order (tfl_ard_statistics()); for other methods: the statistics kept of what the method gives; | between them; blank: the method's default.
#> 12                                     What percentages are of: population (the analysis set; hierarchical and max take it anyway), row / column / cell (cards), another population, or a dataset (its records of the analysis set's subjects); blank: the method's default.
#> 13 Display formats, statistic=format, | between them; VAR:statistic=format for one variable. xx.x = one decimal (the x's count only after the point), xx.x% = a proportion as a percent, a number = decimals, pvalue = <0.001 or 3 decimals; blank: the statistic's default.
#> 14                                                      More arguments of the call, as R (data and population are bound), in any order; refused if not R. An argument a column gives (by, variables, strata, denominator, statistic) may not be given here too; blank: none.
#> 15                                                                                                                                                                                      method = custom only: the R code that gives the ARD (data and population are bound).
#> 16                                                                                                                                                                 For CDISC ARS (tfl_ars()): PRIMARY / SECONDARY / EXPLORATORY OUTCOME MEASURE; blank: tfl_ars(purpose = ).
#> 17                                                                                                                                          For CDISC ARS: SPECIFIED IN PROTOCOL / SPECIFIED IN SAP / DATA DRIVEN / REQUESTED BY REGULATORY AGENCY; blank: SPECIFIED IN SAP.
#>                                       example
#> 1                                        <NA>
#> 2                                         AGE
#> 3                                 Age (years)
#> 4                                  continuous
#> 5                                        ADAE
#> 6                                         SAF
#> 7                              TRTEMFL == "Y"
#> 8                                      TRT01A
#> 9                            PARAMCD | AVISIT
#> 10                                AGE | BMIBL
#> 11                              N | mean | sd
#> 12                                        row
#> 13                        mean=xx.x | p=xx.x%
#> 14                      over_variables = TRUE
#> 15 cards::ard_tabulate(data, variables = SEX)
#> 16                    PRIMARY OUTCOME MEASURE
#> 17                           SPECIFIED IN SAP
```
