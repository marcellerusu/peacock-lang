require "pry"

SCHEMA_OPERATORS = [:&, :|]

module Schemas
  def parse_case_expression!
    case_token = consume! :case
    value = parse_expr!
    cases = []
    while current_token.is_not? :end
      when_token = consume! :when
      schema, matches = parse_schema_literal!
      @token_index, body = clone(context: context.push(:function)).parse_with_position! :when
      fn = case_fn(matches, body, when_token)
      cases.push AST::List.new([schema, fn])
    end
    consume! :end
    AST::Case.new value, AST::List.new(cases), case_token.position
  end

  def case_fn(matches, body, when_token)
    match_arg_token = AST::IdLookup.new("match_expr", when_token.position)
    fn = AST::Fn.new(
      [match_arg_token.value],
      declare_variables_from(matches, match_arg_token) + body,
      when_token.position
    )
  end

  def parse_schema_literal!(index = nil)
    context.push! :schema
    schema_expr = parse_expr!
    context.pop! :schema
    schema_expr
  end

  def parse_schema_literal_deconstruction!(schema_expr)
    if current_token.is? :open_paren
      assert { schema_expr.is_a? AST::IdLookup }
      consume! :open_paren
      context.push! :schema
      pattern = parse_expr!
      context.pop! :schema
      consume! :close_paren
      pattern
    elsif schema_expr.is_a? AST::IdLookup
      nil
    else
      schema_expr
    end
  end

  def parse_match_assignment!(pattern)
    consume! :assign
    AST::MatchAssignment.new(pattern.to_schema, pattern, parse_expr!)
  end

  def parse_fn_match_assignment!(fn_expr, match_expr)
    consume! :assign
    AST::MatchAssignment.new(fn_expr, match_expr, parse_expr!)
  end

  def parse_schema_operator!(lhs)
    t = consume!
    if t.is?(:&)
      AST::CombineSchemas.new(lhs, parse_expr!, t.position)
    elsif t.is?(:|)
      AST::EitherSchemas.new(lhs, parse_expr!, t.position)
    else
      assert { false }
    end
  end

  def parse_schema!
    consume! :schema
    schema_name_token = consume! :identifier
    consume! :"="
    context.push! :schema
    schema = parse_expr!
    while current_token&.is_one_of?(*SCHEMA_OPERATORS)
      schema = parse_schema_operator!(schema)
    end
    context.pop! :schema
    AST::Assign.new(schema_name_token.value, schema, schema_name_token.position)
  end
end
