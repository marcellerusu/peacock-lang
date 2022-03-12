require "pry"

module Schemas
  LITERALS = [:int_lit, :float_lit, :str_lit, :bool_lit, :symbol]

  def parse_case_expression!
    case_token = consume! :case
    value = parse_expr!
    cases = []
    match_arg_name = "match_expr"
    while current_token.is_not_a? :end
      when_token = consume! :when
      schema, matches = parse_schema_literal!
      @token_index, body = clone(
        parser_context: parser_context.push(:function),
      ).parse_with_position! :when

      fn = AST::Fn.new(
        [match_arg_name],
        matches.map do |path_and_sym|
          sym, path = path_and_sym.last, path_and_sym[0...-1]

          AST::Assign.new(
            sym,
            eval_path_on_expr(path, AST::IdLookup.new(match_arg_name, when_token.position))
          )
        end + body,
        case_token.position
      )
      cases.push AST::List.new([schema, fn])
    end
    consume! :end
    AST::Case.new value, AST::List.new(cases), case_token.position
  end

  def parse_schema_literal!(index = nil)
    expr_context.push! :schema
    schema_expr = parse_expr!
    expr_context.pop! :schema
    match_expr = if current_token.is_a? :open_parenthesis
        assert { schema_expr.is_a? AST::IdLookup }
        consume! :open_parenthesis
        expr_context.push! :schema
        pattern = parse_expr!
        expr_context.pop! :schema
        consume! :close_parenthesis
        pattern
      elsif schema_expr.is_a? AST::IdLookup
        nil
      else
        schema_expr
      end
    schema = if schema_expr.schema_any?
        schema_expr
      else
        schema_expr.to_schema
      end
    assert { current_token.is_not_one_of? *OPERATORS }
    return schema, find_bound_variables(match_expr, index)
  end

  def parse_match_assignment_without_schema!(pattern, value_expr = nil)
    parse_match_assignment!(pattern.to_schema, pattern, value_expr)
  end

  def parse_match_assignment!(fn_expr, match_expr, value_expr = nil)
    if value_expr
      position = value_expr.position
      expr = value_expr
    else
      assign_token = consume! :assign
      position = assign_token.position
      expr = parse_expr!
    end
    if_expr = fn_expr.dot("valid_q").call([expr])
    value = AST::Assign.new("__VALUE", expr)
    value_lookup = AST::IdLookup.new("__VALUE", current_token.position)

    pass_body = [value] + find_bound_variables(match_expr).map do |path_and_sym|
      sym, path = path_and_sym.last, path_and_sym[0...-1]
      AST::Assign.new(sym, eval_path_on_expr(path, value_lookup), current_token.position)
    end
    fail_body = [
      AST::Throw.new(AST::Str.new("Match error", current_token.position), current_token.position),
    ]
    AST::If.new if_expr, pass_body, fail_body, position
  end

  def eval_path_on_expr(paths, expr)
    for path in paths
      property = if path.is_a?(String)
          AST::Sym.new(path, expr.position)
        elsif path.is_a?(Integer)
          AST::Int.new(path, expr.position)
        elsif path.is_a?(Symbol)
          assert { path == :_self }
          next
        else
          assert { false }
        end
      expr = expr.lookup(property)
    end
    return expr
  end

  def find_bound_variables(match_expr, outer_index = nil)
    return [] if match_expr.nil?
    if match_expr.schema_any?
      if outer_index
        return [[outer_index, match_expr.schema_any_name]]
      else
        return [[match_expr.schema_any_name]]
      end
    end
    assert { match_expr != nil }
    bound_variables = []
    case match_expr
    when AST::IdLookup
      return [[match_expr.value]]
    when AST::Record
      match_expr.each do |key, value|
        key = key.value
        bound_variables += if value.schema_any? || value.schema_lookup?
            [[key, key]]
          else
            find_bound_variables(value).map { |path| [key] + path }
          end
      end
      if match_expr.splats.value.size > 0
        # TODO: match_expr[:splat] shouldn't be an array
        r = match_expr.splats.value[0]
        splat_name = r.lookup_sym("splat").value
        bound_variables += [[:_self, splat_name]]
      end
    when AST::List
      match_expr.each_with_index do |node, index|
        bound_variables += if node.schema_any?
            [[index, node.schema_any_name]]
          else
            find_bound_variables(node).map { |path| [index] + path }
          end
      end
    when AST::Int, AST::Float, AST::Str, AST::Bool, AST::Nil
      # pass
    else
      pp match_expr
      assert { false }
    end
    if outer_index
      bound_variables.map { |arr| [outer_index, *arr] }
    else
      bound_variables
    end
  end

  def parse_schema!
    consume! :schema
    schema_name_token = consume! :identifier
    consume! :"="
    expr_context.push! :schema
    expr = parse_expr!
    schema = expr.to_schema
    while current_token&.is_one_of?(*OPERATORS)
      schema = parse_operator_call!(schema)
    end
    expr_context.pop! :schema
    AST::Assign.new(schema_name_token.value, schema, schema_name_token.position)
  end
end
