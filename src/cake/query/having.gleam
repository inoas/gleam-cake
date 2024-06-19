//// Please use the `where` module instead of this module to specify `HAVING`
//// constraints.
////
//// `HAVING` and `WHERE` are similar in so far that they both filter data:
////
//// - `WHERE` filters input rows before groups and aggregates are computed, and
////   by that controls which rows go into the aggregate computation.
//// - `HAVING` filters group rows after groups and aggregates are computed.
////
//// Becaue of this difference, `WHERE` can refer to columns that are not part
//// of the `GROUP BY` clause, while `HAVING` cannot.
////
//// ## Notice
////
//// This module is a placeholder until rexporting functions is supported by
//// Gleam.
////

