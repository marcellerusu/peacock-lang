module Schemas
  def parse_match_assignment_without_schema!(pattern)
    pattern = replace_identifier_lookups_with_schema_any(pattern) if pattern[:node_type] == :array_lit
    pattern = replace_literal_values_with_literal_schema(pattern)
    fn_expr = function_call([pattern], schema_for)
    parse_match_assignment!(fn_expr, pattern)
  end

  def replace_identifier_lookups_with_schema_any(pattern)
    pattern[:value] = pattern[:value].map do |node|
      if node[:node_type] == :identifier_lookup
        call_schema_any(node[:sym])
      elsif node[:node_type] == :array_lit
        replace_identifier_lookups_with_schema_any(node)
      else
        node
      end
    end
    pattern
  end

  def replace_literal_values_with_literal_schema(pattern)
    return call_schema_literal(pattern) if [:int_lit, :float_lit, :str_lit, :bool_lit].include?(pattern[:node_type])
    pattern[:value] = pattern[:value].map do |node|
      if [:int_lit, :float_lit, :str_lit, :bool_lit].include?(node[:node_type])
        call_schema_literal(node)
      else
        replace_literal_values_with_literal_schema(node)
      end
    end
    pattern
  end

  def parse_match_assignment!(fn_expr, match_expr)
    # TODO: line & column #s are off
    line, c = @line, @column
    consume! :assign
    expr = parse_expr!
    if_expr = call_schema_valid(fn_expr, expr)

    pass_body = find_bound_variables(match_expr).map do |path_and_sym|
      sym, path = path_and_sym.last, path_and_sym[0...-1]
      AST::assignment(sym, eval_path_on_expr(path, expr), @line, @column)
    end
    fail_body = [
      AST::throw(@line, @column, AST::str("Match error", @line, @column)),
    ]
    AST::if if_expr, pass_body, fail_body, line, c
  end

  def eval_path_on_expr(paths, expr)
    for path in paths
      if path.is_a?(String)
        expr = dot(expr, path)
      elsif path.is_a?(Integer)
        expr = index_on(expr, path)
      else
        assert { false }
      end
    end
    return expr
  end

  def find_bound_variables(match_expr)
    assert { match_expr != nil }
    case match_expr[:node_type]
    when :identifier_lookup
      return [[match_expr[:sym]]]
    when :record_lit
      bound_variables = []
      match_expr[:value].each do |key, value|
        bound_variables += if schema_any?(value)
            [[key, key]]
          else
            find_bound_variables(value).map { |path| [key] + path }
          end
      end
      bound_variables
    when :array_lit
      bound_variables = []
      match_expr[:value].each_with_index do |node, index|
        bound_variables += if schema_any?(node)
            [[index, get_schema_any_name(node)]]
          else
            find_bound_variables(node).map { |path| [index] + path }
          end
      end
      bound_variables
    when :int_lit, :float_lit, :str_lit, :bool_lit
      []
    else
      pp match_expr
      assert { false }
    end
  end

  def get_schema_any_name(node)
    node[:args][0][:value]
  end

  def schema_any?(node)
    node[:node_type] == :function_call &&
      node[:expr][:node_type] == :property_lookup &&
      node[:expr][:lhs_expr][:lhs_expr][:sym] == "Peacock" &&
      node[:expr][:lhs_expr][:property][:value] == "Schema" &&
      node[:expr][:property][:value] == "any"
  end

  def peacock
    AST::identifier_lookup "Peacock", @line, @column
  end

  def schema
    dot(peacock, "Schema")
  end

  def call_schema_valid(schema_fn, expr)
    function_call([expr], dot(schema_fn, "valid"))
  end

  def call_schema_literal(literal)
    function_call([literal], dot(schema, "literal"))
  end

  def call_schema_any(name = nil)
    args = if name then [AST::literal(@line, @column, :str_lit, name)] else [] end
    function_call(args, dot(schema, "any"))
  end

  def schema_for
    dot(dot(peacock, "Schema"), "for")
  end
end
