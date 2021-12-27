require "pry"

module Schemas
  LITERALS = [:int_lit, :float_lit, :str_lit, :bool_lit, :symbol]

  def parse_case_expression!
    consume! :case
    value = parse_expr!
    consume! :of
    cases = []
    match_arg_name = "match_expr"
    while peek_type != :end
      schema, matches = parse_schema_literal!
      consume! :arrow
      @line, @token_index, body = Parser.new(@statements, @line, @token_index, @indentation + 2, :function).parse_with_position!
      fn = AST::function(
        [AST::function_argument(match_arg_name)],
        matches.map do |path_and_sym|
          sym, path = path_and_sym.last, path_and_sym[0...-1]
          # binding.pry
          AST::assignment(
            sym,
            eval_path_on_expr(path, AST::identifier_lookup(match_arg_name))
          )
        end + body
      )
      cases.push AST::array([schema, fn])
    end
    consume! :end
    AST::case value, AST::array(cases)
  end

  def parse_schema_literal!
    expr = parse_expr!
    expr = extract_data_from_constructor(expr)
    expr = replace_identifier_lookups_with_schema_any(expr)
    expr = replace_literal_values_with_literal_schema(expr)
    schema = function_call([expr], schema_for)
    while OPERATORS.include?(peek_type)
      schema = parse_operator_call!(schema)
    end
    # binding.pry
    return schema, find_bound_variables(expr)
  end

  def parse_match_assignment_without_schema!(pattern)
    pattern = extract_data_from_constructor(pattern)
    pattern = replace_identifier_lookups_with_schema_any(pattern)
    pattern = replace_literal_values_with_literal_schema(pattern)
    fn_expr = function_call([pattern], schema_for)
    parse_match_assignment!(fn_expr, pattern)
  end

  def extract_data_from_constructor(pattern)
    pattern[:args][0]
  end

  def replace_identifier_lookups_with_schema_any(pattern)
    def transform_array(array)
      array.map do |node|
        if schema_any?(node)
          node
        elsif node[:node_type] == :identifier_lookup
          call_schema_any(node[:sym])
        elsif node[:node_type] == :array_lit
          replace_identifier_lookups_with_schema_any(node)
        else
          node
        end
      end
    end

    def transform_record(record)
      record.map do |key, node|
        node = if schema_any?(node)
            node
          elsif node[:node_type] == :identifier_lookup
            call_schema_any(node[:sym])
          elsif node[:node_type] == :array_lit
            replace_identifier_lookups_with_schema_any(node)
          else
            node
          end
        [key, node]
      end.to_h
    end

    pattern[:value] = if pattern[:node_type] == :record_lit
        transform_record(pattern[:value])
      elsif pattern[:node_type] == :array_lit
        transform_array(pattern[:value])
      else
        assert { false }
      end
    pattern
  end

  def replace_literal_values_with_literal_schema(pattern)
    return call_schema_literal(pattern) if LITERALS.include?(pattern[:node_type])

    def transform_array(array)
      array.map do |node|
        if schema_any?(node)
          node
        elsif LITERALS.include?(node[:node_type])
          call_schema_literal(node)
        else
          replace_literal_values_with_literal_schema(node)
        end
      end
    end

    def transform_record(record)
      record.map do |key, node|
        node = if schema_any?(node)
            node
          elsif LITERALS.include?(node[:node_type])
            call_schema_literal(node)
          else
            replace_literal_values_with_literal_schema(node)
          end
        [key, node]
      end.to_h
    end

    pattern[:value] = if pattern[:node_type] == :record_lit
        transform_record(pattern[:value])
      elsif pattern[:node_type] == :array_lit
        transform_array(pattern[:value])
      else
        assert { false }
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
      AST::throw(AST::str("Match error", @line, @column), @line, @column),
    ]
    AST::if if_expr, pass_body, fail_body, line, c
  end

  def eval_path_on_expr(paths, expr)
    for path in paths
      property = if path.is_a?(String)
          AST::str(path)
        elsif path.is_a?(Integer)
          AST::int(path)
        else
          assert { false }
        end
      expr = AST::lookup(expr, property)
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

  def parse_schema!
    @expr_context = :schema
    line = @line
    consume! :schema
    c, sym = consume! :identifier
    consume! :declare
    expr = parse_expr!
    schema = function_call([expr], schema_for)
    while OPERATORS.include?(peek_type)
      schema = parse_operator_call!(schema)
    end
    AST::assignment(sym, schema, line, c)
  end

  def get_schema_any_name(node)
    node[:args][0][:args][0][:value]
  end

  def schema_any?(node)
    node.is_a?(Hash) &&
      node[:node_type] == :function_call &&
      node[:expr][:node_type] == :property_lookup &&
      node[:expr][:lhs_expr][:sym] == "Schema" &&
      node[:expr][:property][:value] == "any"
  end

  def schema
    AST::identifier_lookup("Schema", @line, @column)
  end

  def call_schema_valid(schema_fn, expr)
    function_call([expr], dot(schema_fn, "valid_q"))
  end

  def call_schema_literal(literal)
    function_call([literal], dot(schema, "literal"))
  end

  def call_schema_any(name)
    function_call(
      [AST::sym(name, @line, @column)],
      dot(schema, "any")
    )
  end

  def schema_for
    dot(schema, "for")
  end
end
