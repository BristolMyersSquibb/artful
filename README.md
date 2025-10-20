# artful
a**rtf**ul is an R package to convert RTF tables into native R data frames.

artful works by first converting RTF tables into HTML tables via [Pandoc](https://pandoc.org/).
Then, [rvest](https://rvest.tidyverse.org/) is used to extract the HTML table into an R data frame.
Finally, the tables are cleaned and processed to remove redundant information such as headers and footers.

## Coverage
As the RTF tables this package attempts to convert are designed to be human readable, and not machine readable, this package will never be able to guarantee 100% coverage across all tables.
Instead the heuristics described in `R/parse.R` should continually be updated to accomodate new RTF tables which do not fit the previous rule set.
