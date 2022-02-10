module Helpers
  # TODO: later we could use this to store the
  # entire ast parents here
  # & use this to search local scopes
  # not have to rely on __try(() => eval('var_name')) || this.var_name())
  # we could just know if its in scope, or if its a method of parent class..
  class Context
    def initialize(contexts = [])
      @contexts = contexts
    end

    def push!(context)
      @contexts.push context
      self
    end

    def empty?
      @contexts.size == 0
    end

    def clone
      Context.new @contexts.clone
    end

    def pop!(context)
      assert { @contexts.last == context }
      @contexts.pop
    end

    def directly_in_a?(context)
      @contexts.last == context
    end

    def in_a?(context)
      @contexts.any? { |c| c == context }
    end
  end

  def schema?(identifier)
    # identifiers starting w uppercase are interpreted as schemas
    return false if identifier[0] == "_"
    identifier[0].upcase == identifier[0]
  end

  def more_tokens?
    assert { @token_index <= @tokens.size }
    @token_index < @tokens.size
  end

  def token
    @tokens[@token_index]
  end

  def end_of_last_token
    _, column, type, val = peek_token(-1)
    assert { type == :identifier }
    column + val.size
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
    line_number, column_number, type, value, tokens = token
    if type == :identifier && value == "_"
      value += unused_count.to_s
      increment_unused_count!
    end
    @token_index += 1
    return line_number, column_number, value, type, tokens
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

  def operator?(type = peek_type)
    OPERATORS.include?(type)
  end

  def end_of_expr?(*excluding)
    return false if excluding.include? peek_type
    closing_tags = [:close_parenthesis, :close_brace, :close_square_bracket, :of, :then]
    new_line? ||
    closing_tags.include?(peek_type) ||
    property_accessor? ||
    operator? ||
    peek_type == :dot ||
    peek_type == :comma
  end

  def end_of_file?
    @token_index >= @tokens.size
  end
end
