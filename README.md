# jlDates
a translation of Base.Dates from julia to Nim

Most of the basic functionality of Base.Dates has been translated to Nim with two notable exceptions:
- jlDates has no implementation of vectorized operations
- for parsing/formatting dates/times a simplified version of strptime/strftime has been implemented

To see what is possible with jlDates please take a look at the tests. The official [documentation](https://docs.julialang.org/en/stable/stdlib/dates/) from julia is also useful to get an overview. The main feature of the design of  julia's Base.Dates module is that dates/times are essentially wrappers around int64 values. No broken down calendar fields are stored. They are computed whenever needed for calculations or presentation purposes. This design essentially enables very fast date/time arithmetic.
Unfortunately i was not capable enough to get the same speed in Nim as julia gets. But jlDates is still reasonably fast. Date/Time arithmetic is much faster with jlDates than with the times module from Nims standard library.

