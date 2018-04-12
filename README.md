Screening for Disparities
=========================

This package is used to screen for disparities in accordance with the
recommendations by the QIC Ethics Subcommittee.

Setup
-----

To install the package, run the following:

``` r
devtools::install_github("maduc/demographics", host = "github.research.chop.edu/api/v3")
```

How does this package work?
---------------------------

### `screen_demos()`

The main function in this package is `screen_demos()`, which copies a
SQL query that will add demographic data to your cohort and generate
simple bar plots for an outcome metric stratified by each demographic
field.

The demographics included for stratification are:

-   Race (Non-Hispanic White, Non-Hispanic Black, Hispanic or Latino,
    Other)
-   Primary Language (English, Non-English)
-   Payer Type (Commercial, Government, Other)

The syntax of the function is as follows:

``` r
demographics::screen_demos(table = "TABLE_NAME", metric = "METRIC_FIELD",
                           qmr_con = CON_NAME, datamart = T/F)
```

Notes about the above:

-   `table` can be either a datamart or an R dataframe. Whichever you
    choose to use, it **must** contain PAT\_KEY, VISIT\_KEY.
-   `metric` must be a numeric field in your datamart or dataframe.
-   `qmr_con` is the name of your `QMR_DEV` connection object.
-   `datamart` refers whether or not `table` is a datamart. Defaults to
    `TRUE`.

### `get_demo_data()`

`get_demo_data()` is a helper function to `screen_demos()`. It returns
the dataset with demographic information and copies the SQL query used
to generate the dataset to the clipboard. You can paste the query into
Aginity after running `get_demo_data()` or `screen_demos()`. Use this
function if you want to do further manipulations with your dataset. All
of the arguments match `screen_demos`, however the datamart argument
does **not** default to `TRUE` and must be specified.

``` r
demographics::get_demo_data(table = "TABLE_NAME", metric = "METRIC_FIELD",
                           qmr_con = CON_NAME, datamart = T/F)
```

If you have any questions or encounter any issues, contact Nonye Madu or
Paul Wildenhain.
