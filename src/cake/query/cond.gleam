// TODO V2?
// // TODO: CASE expressions for WHERE, SELECT and others?
//
// pub type Case {
//   SimpleCase(base: CaseValue, matches: List(CaseValue), otherwise: CaseValue)
//   BooleanCase(
//     base: CaseBoolExpression,
//     matches: List(CaseValue),
//     otherwise: CaseValue,
//   )
//   ComplexCase(branches: List(CaseWhen), otherwise: CaseValue)
// }
//
// pub type CaseWhen {
//   CaseWhen(condition: CaseBoolExpression, result: CaseValue)
// }
//
// pub type CaseBoolExpression {
//   CaseBoolExpression(
//     value_a: CaseValue,
//     operator: CaseOperator,
//     value_b: CaseValue,
//   )
// }
//
// // These need to be specific enums I guess
// pub type CaseOperator {
//   CaseOperator(String)
// }
//
// pub type CaseValue {
//   CaseColumn(column: String)
//   CaseParam(param: Param)
//   CaseFragment(fragment: Fragment)
//   SubCase(sub_case: Case)
// }
