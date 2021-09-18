require "utils"

class Parser
  def initialize(statements, line = 0, column = 0)
    @statements = statements
    @line = line
    @column = column
  end

  def statement
    @statements[@line]
  end

  def token
    statement[@column]
  end

  def parse!
    _, _, ast = parse_with_position!
    return ast
  end

  def parse_with_position!
    ast = []
    while @line < @statements.size
      if peek_type == :let
        ast.push parse_assignment
      elsif peek_type == :return
        ast.push parse_return
        break
      elsif peek_type == :close_b # end of function
        break
      else
        ast.push parse_expr
      end
      next_line!
    end
    return @line, @column, ast
  end

  def next_line!
    @line += 1
    @column = 0
  end

  def consume!(token_type)
    next_line! if @column == statement.size
    # puts "#{token_type} #{token}"
    assert { token_type == token[1] }
    column_number, type, value = token
    @column += 1
    return column_number, value
  end

  def peek_next_line
    return @line + 1, 0
  end

  def peek_type(by = 0)
    line, column = @line, @column
    line, column = peek_next_line if (column + by) >= statement.size
    return nil if line >= @statements.size
    @statements[line][column + by][1]
  end

  def parse_return(consume = true)
    c, _ = consume! :return if consume
    expr = parse_expr
    c = expr[:column] unless consume
    { type: :return,
      line: @line,
      column: c,
      expr: expr }
  end

  def parse_assignment
    consume! :let
    mut = consume! :mut if peek_type == :mut
    c, sym = consume! :sym
    consume! :assign
    line = @line
    expr = parse_expr
    { type: :declare,
      sym: sym,
      mutable: !!mut,
      line: line,
      column: c,
      expr: expr }
  end

  def parse_lit!(type)
    c, lit = consume! type
    { type: type,
      line: @line,
      column: c,
      value: lit }
  end

  def parse_bool!(type)
    assert { [:false, :true].include? type }
    c, _ = consume! type
    { type: :bool_lit,
      line: @line,
      column: c,
      value: type.to_s == "true" }
  end

  def parse_record!
    c, _ = consume! :open_b
    record = {}
    line = @line
    while peek_type != :close_b
      _, sym = consume! :sym
      consume! :colon
      record[sym] = parse_expr
      consume! :comma unless peek_type == :close_b
    end
    consume! :close_b
    { type: :record_lit,
      line: line,
      column: c,
      value: record }
  end

  def parse_array!
    c, _ = consume! :open_sb
    elements = []
    line = @line
    while peek_type != :close_sb
      elements.push parse_expr
      consume! :comma unless peek_type == :close_sb
    end
    consume! :close_sb
    { type: :array_lit,
      line: line,
      column: c,
      value: elements }
  end

  def parse_function_def_args!
    no_parens = true if peek_type != :open_p
    c, _ = consume! :open_p unless no_parens
    args = []
    while peek_type != :close_p
      c1, sym = consume! :sym
      c = c1 if no_parens
      args.push [c1, sym]
      break if no_parens # only 1 args for no parenthesis
      consume! :comma unless peek_type == :close_p
    end
    assert { args.size == 1 } if no_parens
    consume! :close_p unless no_parens
    return c, args
  end

  def parse_function_def!
    c, args = parse_function_def_args!
    consume! :arrow
    fn_line = @line
    if peek_type != :open_b
      body = [parse_return(false)]
    else
      consume! :open_b
      @line, @column, body = Parser.new(@statements, @line, @column).parse_with_position!
      consume! :close_b
    end
    return { type: :function,
             line: fn_line,
             column: c,
             arg: nil,
             body: body } if args.size == 0

    args.reverse.reduce(body) do |prev_return_value, (c, arg)|
      { type: :function,
        line: fn_line,
        column: c,
        arg: arg,
        body: prev_return_value }
    end
  end

  def parse_sym!
    c, sym = consume! :sym
    { type: :sym_lookup,
      line: @line,
      column: c,
      sym: sym }
  end

  def parse_expr
    _, type = token
    case
    when [:int_lit, :str_lit, :float_lit].include?(type)
      parse_lit! type
    when [:true, :false].include?(type)
      parse_bool! type
    when type == :open_sb
      parse_array!
    when type == :open_b
      parse_record!
    when type == :open_p
      parse_function_def!
    when type == :sym
      case peek_type(1)
      when :arrow
        parse_function_def!
      else
        parse_sym!
      end
    else
      puts "no match [parse_expr] :#{type}"
      assert { false }
    end
  end
end
