require "utils"

OPERATORS = [:plus, :minus, :mult, :div, :pipe, :eq, :not_eq]

class Parser
  def initialize(statements, line = 0, token_index = 0)
    @statements = statements
    @line = line
    @token_index = token_index
  end

  def statement
    @statements[@line]
  end

  def token
    statement[@token_index]
  end

  def parse!
    _, _, ast = parse_with_position!
    return ast
  end

  def parse_with_position!
    ast = []
    while @line < @statements.size
      if peek_type == :let
        ast.push parse_declaration!
      elsif peek_type == :identifier && peek_type(1) == :assign
        ast.push parse_assignment!
      elsif peek_type == :return
        ast.push parse_return!
        break
      elsif peek_type == :close_brace
        break
      else
        ast.push parse_expr!
      end
      next_line!
    end
    return @line, @token_index, ast
  end

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

  def peek_type(by = 0)
    line, token_index = @line, @token_index
    line, token_index = peek_next_line if (token_index + by) >= statement.size
    @statements[line][token_index + by][1] unless @statements[line].nil? || @statements[line][token_index + by].nil?
  end

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
    when type == :open_parenthesis
      parse_function_def!
    when type == :if
      parse_if_expression!
    when type == :identifier
      sym_expr = parse_sym!
      type = peek_type
      case
      when type == :arrow
        parse_function_def! sym_expr
      when OPERATORS.include?(type)
        parse_operator_call! sym_expr
      when type == :open_parenthesis
        parse_function_call! sym_expr
      else sym_expr
      end
    else
      puts "no match [parse_expr!] :#{type}"
      assert { false }
    end
  end

  private

  def parse_return!(implicit_return = false)
    c, _ = consume! :return unless implicit_return
    expr = parse_expr!
    c = expr[:column] if implicit_return
    _return(@line, c, expr)
  end

  def parse_assignment!
    c, sym = consume! :identifier
    consume! :assign
    line = @line
    expr = parse_expr!
    { node_type: :assign,
      sym: sym,
      line: line,
      column: c,
      expr: expr }
  end

  def parse_declaration!
    consume! :let
    mut = consume! :mut if peek_type == :mut
    c, sym = consume! :identifier
    consume! :assign
    line = @line
    expr = parse_expr!
    { node_type: :declare,
      sym: sym,
      mutable: !!mut,
      line: line,
      column: c,
      expr: expr }
  end

  def parse_lit!(type)
    c, lit = consume! type
    { node_type: type,
      line: @line,
      column: c,
      value: lit }
  end

  def parse_bool!(type)
    assert { [:false, :true].include? type }
    c, _ = consume! type
    { node_type: :bool_lit,
      line: @line,
      column: c,
      value: type.to_s == "true" }
  end

  def parse_record!
    c, _ = consume! :open_brace
    record = {}
    line = @line
    while peek_type != :close_brace
      _, sym = consume! :identifier
      consume! :colon
      # TODO: will have to allow more than strings as keys at some point
      record[sym] = parse_expr!
      consume! :comma unless peek_type == :close_brace
    end
    consume! :close_brace
    { node_type: :record_lit,
      line: line,
      column: c,
      value: record }
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
    { node_type: :array_lit,
      line: line,
      column: c,
      value: elements }
  end

  def parse_function_def_args!(sym_expr)
    return @token_index, [[sym_expr[:column], sym_expr[:sym]]] unless sym_expr.nil?
    c, _ = consume! :open_parenthesis
    args = []
    while peek_type != :close_parenthesis
      c1, sym = consume! :identifier
      args.push [c1, sym]
      consume! :comma unless peek_type == :close_parenthesis
    end
    consume! :close_parenthesis
    return c, args
  end

  def parse_function_def!(sym_expr = nil)
    c, args = parse_function_def_args! sym_expr
    consume! :arrow
    fn_line = @line
    if peek_type != :open_brace
      body = [parse_return!(true)]
    else
      consume! :open_brace
      @line, @token_index, body = Parser.new(@statements, @line, @token_index).parse_with_position!
      consume! :close_brace
    end
    return function(fn_line, c, body) if args.size == 0

    for c, arg in args.reverse
      fn = function(fn_line, c, body, arg)
      body = [_return(fn_line, c, fn)]
    end

    fn
  end

  def parse_operator_call!(lhs)
    c1, _, op = consume!
    rhs_expr = parse_expr!
    fn_identifier = "Peacock.#{op.to_s}"

    function_call(
      @line,
      c1,
      rhs_expr,
      function_call(
        @line,
        c1,
        lhs,
        identifier_lookup(@line, c1, fn_identifier)
      )
    )
  end

  def parse_function_call!(fn_expr)
    consume! :open_parenthesis
    args = []
    while peek_type != :close_parenthesis
      expr = parse_expr!
      args.push expr
      consume! :comma unless peek_type == :close_parenthesis
    end

    for arg in args
      fn_call = function_call(fn_expr[:line], fn_expr[:column], arg, fn_expr)
      fn_expr = fn_call
    end

    fn_call
  end

  def parse_if_expression!
    c, _ = consume! :if
    if_line = @line
    check = parse_expr!
    consume! :open_brace
    @line, @token_index, pass_body = Parser.new(@statements, @line, @token_index).parse_with_position!
    consume! :close_brace
    return if_expr(if_line, c, check, pass_body, []) unless peek_type == :else
    consume! :else
    return if_expr(if_line, c, check, pass_body, [parse_if_expression!]) if peek_type == :if
    consume! :open_brace
    @line, @token_index, fail_body = Parser.new(@statements, @line, @token_index).parse_with_position!
    consume! :close_brace
    if_expr(if_line, c, check, pass_body, fail_body)
  end

  def parse_sym!
    c, sym = consume! :identifier
    identifier_lookup @line, c, sym
  end

  def if_expr(line, c, expr, pass, _fail)
    { node_type: :if,
      line: line,
      column: c,
      expr: expr,
      pass: pass,
      fail: _fail }
  end

  def function_call(line, c, arg, expr)
    { node_type: :function_call,
      line: line,
      column: c,
      arg: arg,
      expr: expr }
  end

  def function(line, c, body, arg = nil)
    { node_type: :function,
      line: line,
      column: c,
      arg: arg,
      body: body }
  end

  def identifier_lookup(line, c, sym)
    { node_type: :identifier_lookup,
      line: line,
      column: c,
      sym: sym }
  end

  def _return(line, c, expr)
    { node_type: :return,
      line: line,
      column: c,
      expr: expr }
  end
end
