require "utils"
# require "pry"

OPERATORS = [:plus, :minus, :mult, :div, :pipe, :eq, :not_eq]

class Parser
  def initialize(statements, line = 0, token_index = 0, indentation = 0)
    @statements = statements
    @line = line
    @token_index = token_index
    @indentation = indentation
  end

  def statement
    @statements[@line]
  end

  def token
    statement[@token_index]
  end

  def column
    token[0] if token
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
      if peek_type == :identifier && peek_type(1) == :assign
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
    # TODO: find a better way to know if we're in a function
    unless @indentation == 0 || ast.last[:node_type] == :return
      node = ast.pop
      ast.push AST::return(node[:line], node[:column], node)
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
    # TODO: multi-line function calls
    !new_line?(1)
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
    when type == :fn
      parse_anon_function_def!
    when type == :if
      parse_if_expression!
    when type == :identifier
      sym_expr = parse_sym!
      type = peek_type
      case
      when is_function?
        parse_function_def! sym_expr
      when OPERATORS.include?(type)
        parse_operator_call! sym_expr
      when is_function_call?
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
    { node_type: type,
      line: @line,
      column: c,
      value: lit }
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
      _, sym = consume! :identifier
      consume! :colon
      # TODO: will have to allow more than strings as keys at some point
      record[sym] = parse_expr!
      consume! :comma unless peek_type == :close_brace
    end
    consume! :close_brace
    AST::record line, c, record
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
    AST::array line, c, elements
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
    fn_identifier = "Peacock.#{op.to_s}"

    operator = AST::identifier_lookup @line, c1, fn_identifier
    AST::function_call @line, c1, [lhs, rhs_expr], operator
  end

  def parse_function_call!(fn_expr)
    args = []
    while !new_line?
      args.push parse_expr!
    end

    AST::function_call fn_expr[:line], fn_expr[:column], args, fn_expr
  end

  def parse_if_expression!
    end_tokens = [:end, :else]
    c, _ = consume! :if
    if_line = @line
    check = parse_expr!
    @line, @token_index, pass_body = Parser.new(@statements, @line, @token_index, @indentation).parse_with_position! end_tokens
    # consume! :then if peek_token :then
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
end

module AST
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

  def self.assignment(sym, line, c, expr)
    { node_type: :assign,
      sym: sym,
      line: line,
      column: c,
      expr: expr }
  end
end
