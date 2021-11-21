require "utils"
# require "pry"

OPERATORS = [:plus, :minus, :mult, :div, :and, :or, :schema_and, :schema_or, :eq, :not_eq, :gt, :ls, :gt_eq, :ls_eq]

ANON_SHORTHAND_ID = "__ANON_SHORT_ID"

class Parser
  def initialize(statements, line = 0, token_index = 0, indentation = 0)
    @statements = statements
    @line = line
    @token_index = token_index
    @indentation = indentation
  end

  def parse!
    _, _, ast = parse_with_position!
    return ast
  end

  def parse_with_position!(end_tokens = [])
    ast = []
    next_line! unless token
    while @line < @statements.size && (column.nil? || column >= @indentation)
      break if end_tokens.include? peek_type
      if peek_type == :schema
        ast.push parse_schema!
      elsif peek_type == :identifier && peek_type(1) == :assign
        ast.push parse_assignment!
      elsif peek_type == :return
        ast.push parse_return!
        break
      else
        ast.push parse_expr!
      end
      next_line!
    end
    # TODO: find a better way to know if we're in a function
    # Add implicit return
    unless @indentation == 0 || ast.last[:node_type] == :return
      node = ast.pop
      ast.push AST::return(node[:line], node[:column], node)
    end
    return @line, @token_index, ast
  end

  private

  # Convenience methods

  def statement
    @statements[@line]
  end

  def token
    statement[@token_index]
  end

  def column
    token[0] if token
  end

  # Parsing helpers

  def next_line!
    @line += 1
    @token_index = 0
  end

  def consume!(token_type = nil)
    next_line! if @token_index == statement.size
    # puts "#{token_type} #{token}"
    assert { token_type == token[1] } unless token_type.nil?
    column_number, type, value = token
    @token_index += 1
    return column_number, value, type
  end

  def peek_next_line
    return @line + 1, 0
  end

  def peek_token(by = 0)
    line, token_index = @line, @token_index
    line, token_index = peek_next_line if (token_index + by) >= statement.size
    return @statements[line][token_index + by], line, token_index unless @statements[line].nil? || @statements[line][token_index + by].nil?
  end

  def peek_type(by = 0)
    t, line = peek_token(by)
    t[1] if t
  end

  def new_line?(by = 0)
    _, line = peek_token(by)
    line != @line
  end

  def end_of_file?
    @statements.size == @line + 1 && @statements[@line].size == @token_index + 1
  end

  def is_function?
    # skip params
    i = 0
    while peek_type(i) == :identifier
      i += 1
    end
    peek_type(i) == :declare
  end

  def is_function_call?
    peek_type == :open_parenthesis
  end

  # Parsing begins!

  def parse_expr!
    type = peek_type
    case
    when [:int_lit, :str_lit, :float_lit, :symbol].include?(type)
      lit_expr = parse_lit! type
      peek = peek_type
      case
      when OPERATORS.include?(peek)
        parse_operator_call! lit_expr
      else lit_expr
      end
    when [:true, :false].include?(type)
      parse_bool! type
    when type == :open_square_bracket
      parse_array!
    when type == :open_brace
      parse_record!
    when type == :fn
      parse_anon_function_def!
    when type == :if
      parse_if_expression!
    when type == :identifier
      parse_identifier!
    when type == :anon_short_fn_start
      parse_anon_function_shorthand!
    when type == :anon_short_id
      parse_anon_short_id!
    else
      puts "no match [parse_expr!] :#{type}"
      assert { false }
    end
  end

  def parse_id_modifier_if_exists!(sym_expr)
    type = peek_type
    case
    when type == :open_square_bracket
      parse_dynamic_lookup! sym_expr
    when type == :dot
      parse_dot_expression! sym_expr
    when OPERATORS.include?(type)
      parse_operator_call! sym_expr
    when is_function_call?
      parse_function_call! sym_expr
    when is_function?
      parse_function_def! sym_expr
    else sym_expr
    end
  end

  # Individual parsers

  def parse_identifier!
    sym_expr = parse_sym!
    parse_id_modifier_if_exists!(sym_expr)
  end

  def parse_return!(implicit_return = false)
    c, _ = consume! :return unless implicit_return
    expr = parse_expr!
    c = expr[:column] if implicit_return
    AST::return @line, c, expr
  end

  def parse_assignment!
    c, sym = consume! :identifier
    consume! :assign
    line = @line
    expr = parse_expr!
    AST::assignment sym, line, c, expr
  end

  def parse_lit!(type)
    c, lit = consume! type
    AST::literal @line, c, type, lit
  end

  def parse_bool!(type)
    c, _ = consume! type
    AST::bool @line, c, type == :true
  end

  def parse_record!
    c, _ = consume! :open_brace
    record = {}
    line = @line
    while peek_type != :close_brace
      # TODO: will have to allow more than strings as keys at some point
      _, sym = consume! :identifier
      if peek_type == :colon
        consume! :colon
        record[sym] = parse_expr!
      else
        # We can't always do this
        record[sym] = call_schema_any
      end
      consume! :comma unless peek_type == :close_brace
    end
    consume! :close_brace
    node = AST::record line, c, record
    return parse_match_assignment_without_schema!(node) if peek_type == :assign
    # TODO: make more specific to records
    parse_id_modifier_if_exists!(node)
  end

  def parse_array!
    c, _ = consume! :open_square_bracket
    elements = []
    line = @line
    while peek_type != :close_square_bracket
      elements.push parse_expr!
      consume! :comma unless peek_type == :close_square_bracket
    end
    consume! :close_square_bracket
    node = AST::array line, c, elements
    return parse_match_assignment_without_schema!(node) if peek_type == :assign
    # TODO: make more specific to records
    parse_id_modifier_if_exists!(node)
  end

  def parse_anon_function_shorthand!
    line, c = @line, @column
    consume! :anon_short_fn_start
    expr = parse_expr!
    expr = AST::return(line, c, expr) unless expr[:node_type] == :return
    consume! :close_brace
    args = [AST::function_argument(line, c, ANON_SHORTHAND_ID)]
    AST::function line, c, [expr], args
  end

  def parse_anon_short_id!
    consume! :anon_short_id
    sym_expr = AST::identifier_lookup(@line, @column, ANON_SHORTHAND_ID)
    parse_id_modifier_if_exists!(sym_expr)
  end

  def parse_function_arguments!(end_type)
    args = []
    while peek_type != end_type
      c1, sym = consume! :identifier
      args.push AST::function_argument(@line, c1, sym)
    end
    args
  end

  def parse_function_def!(sym_expr)
    args = parse_function_arguments! :declare
    consume! :declare
    fn_line = @line
    if new_line?
      next_line!
      @line, @token_index, body = Parser.new(@statements, @line, @token_index, @indentation + 2).parse_with_position!
    else
      return_c = column
      expr = parse_expr!
      body = [AST::return(@line, return_c, expr)]
    end

    function = AST::function(fn_line, sym_expr[:column], body, args)
    AST::declare(sym_expr, function)
  end

  def parse_anon_function_def!
    c, _ = consume! :fn
    args = parse_function_arguments! :arrow
    consume! :arrow
    fn_line = @line
    expr = parse_expr!
    body = [AST::return(@line, expr[:column], expr)]
    # TODO: none 1-liners
    # @line, @token_index, body = Parser.new(@statements, @line, @token_index).parse_with_position!
    AST::function fn_line, c, body, args
  end

  def parse_operator_call!(lhs)
    c1, _, op = consume!
    rhs_expr = parse_expr!
    operator = case op
      when :schema_and, :schema_or
        dot(schema, [c1, op.to_s.split("schema_")[1]])
      else
        dot(peacock, [c1, op.to_s])
      end
    AST::function_call @line, c1, [lhs, rhs_expr], operator
  end

  def parse_function_call!(fn_expr)
    consume! :open_parenthesis
    args = []
    while peek_type != :close_parenthesis
      args.push parse_expr!
      consume! :comma unless peek_type == :close_parenthesis
    end
    consume! :close_parenthesis

    return parse_match_assignment!(fn_expr, args[0]) if args.size == 1 && peek_type == :assign

    AST::function_call fn_expr[:line], fn_expr[:column], args, fn_expr
  end

  def parse_match_assignment_without_schema!(pattern)
    pattern = replace_identifier_lookups_with_schema_any(pattern) if pattern[:node_type] == :array_lit
    fn_expr = function_call([pattern], schema_for)
    parse_match_assignment!(fn_expr, pattern)
  end

  def replace_identifier_lookups_with_schema_any(pattern)
    # TODO: make recursive
    pattern[:value] = pattern[:value].map do |node|
      if node[:node_type] == :identifier_lookup
        call_schema_any(node[:sym])
      else
        node
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
      AST::assignment(sym, @line, @column, eval_path_on_expr(path, expr))
    end
    fail_body = [
      AST::throw(@line, @column, AST::str(@line, @column, "Match error")),
    ]
    AST::if line, c, if_expr, pass_body, fail_body
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

  def parse_if_expression!
    end_tokens = [:end, :else]
    c, _ = consume! :if
    if_line = @line
    check = parse_expr!
    @line, @token_index, pass_body = Parser.new(@statements, @line, @token_index, @indentation).parse_with_position! end_tokens
    consume! :then if peek_type == :then
    unless peek_type == :else
      consume! :end
      return AST::if if_line, c, check, pass_body, []
    end
    consume! :else
    return AST::if(if_line, c, check, pass_body, [parse_if_expression!]) if peek_type == :if
    @line, @token_index, fail_body = Parser.new(@statements, @line, @token_index, @indentation).parse_with_position! end_tokens
    consume! :end
    AST::if if_line, c, check, pass_body, fail_body
  end

  def parse_sym!
    c, sym = consume! :identifier
    AST::identifier_lookup @line, c, sym
  end

  def parse_dot_expression!(lhs)
    c, line = @column, @line
    consume! :dot
    AST::dot line, c, lhs, consume!(:identifier)
  end

  def parse_dynamic_lookup!(lhs)
    c, line = @column, @line
    consume! :open_square_bracket
    expr = parse_expr!
    consume! :close_square_bracket
    assert { [:str_lit, :symbol, :int_lit, :float_lit].include? expr[:node_type] }
    node = AST::property_lookup(line, c, lhs, expr)
    parse_id_modifier_if_exists!(node)
  end

  # Schema parsing

  def peacock
    AST::identifier_lookup @line, @column, "Peacock"
  end

  def schema
    dot(peacock, "Schema")
  end

  def call_schema_valid(schema_fn, expr)
    function_call([expr], dot(schema_fn, "valid"))
  end

  def call_schema_any(name = nil)
    args = if name then [AST::literal(@line, @column, :str_lit, name)] else [] end
    function_call(args, dot(schema, "any"))
  end

  def schema_for
    dot(dot(peacock, "Schema"), "for")
  end

  def dot(lhs, id)
    id = [@column, id] unless id.is_a?(Array)
    AST::dot @line, @column, lhs, id
  end

  def index_on(lhs, index)
    index = AST::literal(lhs[:line], lhs[:column], :int_lit, index)
    AST::index_on(lhs, index)
  end

  def function_call(args, expr)
    AST::function_call(@line, @column, args, expr)
  end

  def parse_schema!
    line = @line
    consume! :schema
    c, sym = consume! :identifier
    consume! :declare
    expr = parse_expr!
    schema = function_call([expr], schema_for)
    while OPERATORS.include?(peek_type)
      schema = parse_operator_call!(schema)
    end
    AST::assignment(sym, line, c, schema)
  end
end

module AST
  def self.remove_numbers_single(node)
    node = node.except(:line, :column)
    node[:expr] = AST::remove_numbers_single(node[:expr]) if node[:expr]
    node[:property] = AST::remove_numbers_single(node[:property]) if node[:property]
    node[:lhs_expr] = AST::remove_numbers_single(node[:lhs_expr]) if node[:lhs_expr]
    node[:value] = AST::remove_numbers(node[:value]) if node[:value].is_a?(Array)
    node[:args] = AST::remove_numbers(node[:args]) if node[:args]
    node[:body] = AST::remove_numbers(node[:body]) if node[:body]
    return node
  end

  def self.remove_numbers(nodes)
    nodes.map { |n| AST::remove_numbers_single(n) }
  end

  def self.literal(line, c, type, value)
    { node_type: type,
      line: line,
      column: c,
      value: value }
  end

  def self.array(line, c, value)
    { node_type: :array_lit,
      line: line,
      column: c,
      value: value }
  end

  def self.record(line, c, value)
    { node_type: :record_lit,
      line: line,
      column: c,
      value: value }
  end

  def self.bool(line, c, value)
    { node_type: :bool_lit,
      line: line,
      column: c,
      value: value }
  end

  def self.str(line, c, value)
    { node_type: :str_lit,
      line: line,
      column: c,
      value: value }
  end

  def self.return(line, c, expr)
    { node_type: :return,
      line: line,
      column: c,
      expr: expr }
  end

  def self.if(line, c, expr, pass, _fail)
    { node_type: :if,
      line: line,
      column: c,
      expr: expr,
      pass: pass,
      fail: _fail }
  end

  def self.function_call(line, c, args, expr)
    { node_type: :function_call,
      line: line,
      column: c,
      args: args,
      expr: expr }
  end

  def self.function(line, c, body, args)
    { node_type: :function,
      line: line,
      column: c,
      args: args,
      body: body }
  end

  def self.function_argument(line, c, sym)
    { node_type: :function_argument,
      line: line,
      column: c,
      sym: sym }
  end

  def self.identifier_lookup(line, c, sym)
    { node_type: :identifier_lookup,
      line: line,
      column: c,
      sym: sym }
  end

  def self.declare(sym_expr, expr)
    { node_type: :declare,
      sym: sym_expr[:sym],
      line: sym_expr[:line],
      column: sym_expr[:column],
      expr: expr }
  end

  def self.assignment(sym, line, c, expr)
    { node_type: :assign,
      sym: sym,
      line: line,
      column: c,
      expr: expr }
  end

  def self.property_lookup(line, c, lhs_expr, property)
    # just convert to string for now... TODO: idk
    { node_type: :property_lookup,
      lhs_expr: lhs_expr,
      line: line,
      column: c,
      property: property }
  end

  def self.dot(line, c, lhs_expr, id)
    lit_c, sym = id
    property = AST::literal line, lit_c, :str_lit, sym
    AST::property_lookup line, c, lhs_expr, property
  end

  def self.index_on(lhs, index)
    AST::property_lookup lhs[:line], lhs[:column], lhs, index
  end

  def self.throw(line, c, expr)
    { node_type: :throw,
      line: line,
      column: c,
      expr: expr }
  end
end
