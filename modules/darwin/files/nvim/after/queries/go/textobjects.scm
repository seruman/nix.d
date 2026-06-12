; extends

(struct_type
  (field_declaration_list
    (field_declaration
      tag: (raw_string_literal) @structtag.outer)))


((call_expression
  function: (selector_expression
    operand: (identifier) @receiver
    field: (field_identifier) @method
    (#eq? @receiver "t")
    (#eq? @method "Run"))
  arguments: (argument_list
    (interpreted_string_literal) @go.subtest_call.name.outer
    (func_literal)               )) @go.subtest_call.outer)
