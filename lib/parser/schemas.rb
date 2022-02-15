require "pry"

module Schemas
  LITERALS = [:int_lit, :float_lit, :str_lit, :bool_lit, :symbol]

  def parse_case_expression!
    consume! :case
    value = parse_expr!
    cases = []
    match_arg_name = "match_expr"
    while peek_type != :end
      consume! :when
      schema, matches = parse_schema_literal!
      @token_index, body = clone(parser_context: parser_context.clone.push!(:function)).parse_with_position! [:when]
      fn = AST::function(
        [AST::function_argument(match_arg_name)],
        matches.map do |path_and_sym|
          sym, path = path_and_sym.last, path_and_sym[0...-1]
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

  def parse_schema_literal!(index = nil)
    expr_context.push! :schema
    schema_expr = parse_expr!
    expr_context.pop! :schema
    match_expr = if peek_type == :open_parenthesis
        assert { schema_expr[:node_type] == :identifier_lookup }
        consume! :open_parenthesis
        expr_context.push! :schema
        pattern = parse_expr!
        expr_context.pop! :schema
        consume! :close_parenthesis
        pattern
      elsif schema_expr[:node_type] == :identifier_lookup
        nil
      else
        schema_expr
      end
    schema = if schema_any?(schema_expr)
        schema_expr
      else
        function_call([schema_expr], schema_for)
      end
    assert { !OPERATORS.include?(peek_type) }
    return schema, find_bound_variables(match_expr, index)
  end

  def parse_match_assignment_without_schema!(pattern, value_expr = nil)
    fn_expr = function_call([pattern], schema_for)
    parse_match_assignment!(fn_expr, pattern, value_expr)
  end

  def extract_data_from_constructor(pattern)
    return pattern unless constructor? pattern
    raw_value = pattern[:args][0]
    if raw_value[:node_type] == :array_lit
      # TODO: array splats
      { **raw_value,
        value: raw_value[:value].map { |node| extract_data_from_constructor(node) } }
    elsif raw_value[:node_type] == :record_lit
      assert { pattern[:args][1][:args].size <= 1 } # only have 1 splat
      splat = pattern[:args][1][:args][0]
      { **raw_value,
        value: raw_value[:value].transform_values { |node| extract_data_from_constructor(node) },
        splat: splat && splat[:value].map { |node| extract_data_from_constructor(node) } }
    else
      raw_value
    end
  end

  def collection_lit?(node)
    [:record_lit, :array_lit].include? node[:node_type]
  end

  def replace_identifier_lookups_with_schema_any(pattern)
    def transform_array(array)
      array.map do |node|
        if schema_any?(node)
          node
        elsif node[:node_type] == :identifier_lookup
          call_schema_any(node[:sym])
        elsif collection_lit?(node)
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
          elsif collection_lit?(node)
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

  def parse_match_assignment!(fn_expr, match_expr, value_expr = nil)
    # TODO: line & column #s are off
    if value_expr
      line, c = value_expr[:line], value_expr[:column]
      expr = value_expr
    else
      line, c = consume! :assign
      expr = parse_expr!
    end
    if_expr = call_schema_valid(fn_expr, expr)
    value = AST::assignment("__VALUE", expr)
    value_lookup = AST::identifier_lookup("__VALUE", self.line, self.column)

    pass_body = [value] + find_bound_variables(match_expr).map do |path_and_sym|
      sym, path = path_and_sym.last, path_and_sym[0...-1]
      AST::assignment(sym, eval_path_on_expr(path, value_lookup), self.line, self.column)
    end
    fail_body = [
      AST::throw(AST::str("Match error", self.line, self.column), self.line, self.column),
    ]
    AST::if if_expr, pass_body, fail_body, line, c
  end

  def eval_path_on_expr(paths, expr)
    for path in paths
      property = if path.is_a?(String)
          AST::sym(path)
        elsif path.is_a?(Integer)
          AST::int(path)
        elsif path.is_a?(Symbol)
          assert { path == :_self }
          next
        else
          assert { false }
        end
      expr = AST::lookup(expr, property)
    end
    return expr
  end

  def literal_is_a?(expr, constructor_type)
    constructor?(expr) &&
      expr[:expr][:lhs_expr][:sym] == constructor_type
  end

  def constructor?(expr)
    constructors = ["List", "Int", "Float", "Str", "Sym", "Record", "Bool", "Nil"]

    constructors.include?(expr.dig(:expr, :lhs_expr, :sym)) &&
    expr.dig(:expr, :property, :value) == "new"
  end

  def schema_lookup?(node)
    return node[:node_type] == :identifier_lookup && schema?(node[:sym])
  end

  def find_bound_variables(match_expr, outer_index = nil)
    return [] if match_expr.nil?
    if schema_any?(match_expr)
      if outer_index
        return [[outer_index, get_schema_any_name(match_expr)]]
      else
        return [[get_schema_any_name(match_expr)]]
      end
    end
    match_expr = extract_data_from_constructor(match_expr) if constructor?(match_expr)
    assert { match_expr != nil }
    bound_variables = []
    case match_expr[:node_type]
    when :identifier_lookup
      return [[match_expr[:sym]]]
    when :record_lit
      match_expr[:value].each do |key, value|
        key = extract_data_from_constructor(key)[:value]
        bound_variables += if schema_any?(value) || schema_lookup?(value)
            [[key, key]]
          else
            find_bound_variables(value).map { |path| [key] + path }
          end
      end
      if match_expr[:splat]
        # TODO: match_expr[:splat] shouldn't be an array
        r = match_expr[:splat][0][:value]
        splat_name = r[AST::sym("splat")][:sym]
        bound_variables += [[:_self, splat_name]]
      end
    when :array_lit
      match_expr[:value].each_with_index do |node, index|
        bound_variables += if schema_any?(node)
            [[index, get_schema_any_name(node)]]
          else
            find_bound_variables(node).map { |path| [index] + path }
          end
      end
    when :int_lit, :float_lit, :str_lit, :bool_lit, :nil_lit
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
    line = self.line
    consume! :schema
    _, c, sym = consume! :identifier
    consume! :"="
    expr_context.push! :schema
    expr = parse_expr!
    schema = function_call([expr], schema_for)
    while OPERATORS.include?(peek_type)
      schema = parse_operator_call!(schema)
    end
    expr_context.pop! :schema
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
    AST::identifier_lookup("Schema", line, column)
  end

  def call_schema_valid(schema_fn, expr)
    function_call([expr], dot(schema_fn, "valid_q"))
  end

  def call_schema_literal(literal)
    function_call([literal], dot(schema, "literal"))
  end

  def call_schema_any(name)
    function_call(
      [AST::sym(name, line, column)],
      dot(schema, "any")
    )
  end

  def schema_for
    dot(schema, "for")
  end
end
