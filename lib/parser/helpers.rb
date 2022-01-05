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

  def schema?(identifier)
    # identifiers starting w uppercase are interpreted as schemas
    identifier[0].upcase == identifier[0]
  end

  def more_tokens?
    assert { @token_index <= @tokens.size }
    @token_index < @tokens.size
  end

  def still_indented?
    assert { !column.nil? }
    column >= @indentation
  end

  def token
    @tokens[@token_index]
  end

  def prev_token_line
    assert { @token_index > 0 }
    peek_token(-1)[0]
  end

  def line
    token[0] if token
  end

  def column
    token[1] if token
  end

  def consume!(token_type = nil)
    # puts "#{token_type} #{token}"
    assert { token_type == token[2] } unless token_type.nil?
    line_number, column_number, type, value = token
    @token_index += 1
    return line_number, column_number, value, type
  end

  def peek_expr(by = 0)
    parser = clone
    expr = nil
    (by + 1).times { expr = parser.parse_expr }
    expr
  end

  def peek_token(by = 0)
    return @tokens[@token_index + by]
  end

  def peek_type(by = 0)
    return nil if @token_index + by > @tokens.size
    line, column, type = peek_token(by)
    type
  end

  def new_line?
    prev_token_line != line
  end

  def end_of_expr?
    closing_tags = [:close_parenthesis, :close_brace, :close_square_bracket]
    new_line? ||
    closing_tags.include?(peek_type) ||
    peek_type == :dot
  end

  def end_of_file?
    @token_index >= @tokens.size
  end
end
