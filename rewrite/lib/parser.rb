require "utils"

class Parser
  def initialize(statements)
    @statements = statements
    @index = 0
    @line = 0
  end

  def parse
    statements = []
    for @statement in @statements
      if peek_type == :let
        statements.push parse_assignment
      else
        statements.push parse_expr
      end
      @line += 1
    end
    statements
  end

  def consume!(token_type)
    # puts "#{token_type} #{@statement[@index]}"
    assert { token_type == @statement[@index][1] }
    column_number, type, value = @statement[@index]
    @index += 1
    return column_number, value
  end

  def peek_type
    @statement[@index][1]
  end

  def parse_assignment
    consume! :let
    mut = consume! :mut if peek_type == :mut
    c, sym = consume! :sym
    consume! :assign
    expr = parse_expr
    {
      type: :declare,
      sym: sym,
      mutable: !!mut,
      line: @line,
      column: c,
      expr: expr,
    }
  end

  def parse_lit(type)
    c, lit = consume! type
    {
      type: type,
      line: @line,
      column: c,
      value: lit,
    }
  end

  def parse_bool(type)
    c, _ = consume! type
    {
      type: :bool_lit,
      line: @line,
      column: c,
      value: type.to_s == "true",
    }
  end

  def parse_record
    c, _ = consume! :open_b
    record = {}
    while peek_type != :close_b
      _, sym = consume! :sym
      consume! :colon
      record[sym] = parse_expr
      consume! :comma unless peek_type == :close_b
    end
    consume! :close_b
    {
      type: :record_lit,
      line: @line,
      column: c,
      value: record,
    }
  end

  def parse_array
    c, _ = consume! :open_sb
    elements = []
    while peek_type != :close_sb
      elements.push parse_expr
      consume! :comma unless peek_type == :close_sb
    end
    consume! :close_sb
    {
      type: :array_lit,
      line: @line,
      column: c,
      value: elements,
    }
  end

  def parse_expr
    _, type = @statement[@index]
    case
    when [:int_lit, :str_lit, :float_lit].include?(type)
      parse_lit type
    when [:true, :false].include?(type)
      parse_bool type
    when type == :open_sb
      parse_array
    when type == :open_b
      parse_record
    else
      puts "no match [parse_expr] #{type}"
      assert { false }
    end
  end
end
