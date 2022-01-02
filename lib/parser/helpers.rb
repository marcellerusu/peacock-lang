module Helpers
  class Context
    def initialize(context = nil)
      @context = context
    end

    def set!(context)
      @context = context
    end

    def unset!(context)
      assert { @context == context }
      @context = nil
    end

    def is_a?(context)
      @context == context
    end
  end

  def statement
    @statements[@line]
  end

  def schema?(identifier)
    # identifiers starting w uppercase are interpreted as schemas
    identifier[0].upcase == identifier[0]
  end

  def more_statements?
    assert { @line <= @statements.size }
    @line < @statements.size
  end

  def still_indented?
    assert { !column.nil? }
    column >= @indentation
  end

  def token
    statement[@token_index]
  end

  def column
    token[0] if token
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

  def peek_expr(by = 0)
    parser = clone
    expr = nil
    (by + 1).times { expr = parser.parse_expr }
    expr
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

  def end_of_expr?
    closing_tags = [:close_parenthesis, :close_brace, :close_square_bracket]
    new_line? || closing_tags.include?(peek_type)
  end

  def end_of_file?
    @statements.size == @line + 1 && @statements[@line].size == @token_index + 1
  end
end
