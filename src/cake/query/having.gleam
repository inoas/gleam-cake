//// Please use where.gleam instead of this module to specify HAVING constraints.
////
//// NOTICE: This module is a placeholder until rexporting functions is supported by Gleam.
////
//// HAVING and WHERE are similar in so far that they both filter data.
//// - WHERE selects input rows before groups and aggregates are computed, and by that controls which rows go into the aggregate computation
//// - HAVING selects group rows after groups and aggregates are computed.
////
//// Becaue of this difference, WHERE can refer to columns that are not part of the GROUP BY clause, while HAVING cannot.
////
//// Please use where.gleam instead of this module to specify HAVING constraints.
////

// TODO v1 tests for HAVING
