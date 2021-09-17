TOKENS = {
  "=" => :assign,
  "let" => :let,
  "==" => :eq,
  "!=" => :not_eq,
}

class Lexer
  def initialize(program)
    @program = program
  end

  def tokenize
    lines = @program.split("\n")
    lines.map do |line|
      @line = line
      tokenize_line
    end
  end

  private

  def reset_current_token!
    @current_token = { str: "", index: @col + 2 }
  end

  def symbol
    [@current_token[:index], :sym, @current_token[:str]]
  end

  def end_of_line?
    @col == @line.size - 1
  end

  def peek
    @line[@col + 1]
  end

  def peek_empty_or_end_of_line?
    peek == " " || @col == @line.size - 1
  end

  def token_sym
    TOKENS[@current_token[:str]] if !TOKENS.include?(@current_token[:str] + peek)
  end

  def tokenize_line
    tokens = []
    @col = 0
    @current_token = { str: "", index: @col }
    while @col < @line.size
      break if @line[@col] == "#"
      @current_token[:str] += @line[@col] if @line[@col] != " "
      if token = token_sym
        tokens.push [@current_token[:index], token]
        reset_current_token!
      elsif peek_empty_or_end_of_line?
        if is_literal?
          tokens.push literal
        else
          tokens.push symbol if @current_token[:str].size > 0
        end
        reset_current_token!
      end

      @col += 1
    end

    return tokens
  end

  # Literal parsing

  def int_lit
    [@current_token[:index], :sym, @current_token[:str].to_i]
  end

  def is_int?
    as_int.to_s == @current_token[:str]
  end

  def as_int
    @current_token[:str].to_i
  end

  def is_float?
    as_float.to_s == @current_token[:str]
  end

  def as_float
    @current_token[:str].to_f
  end

  def is_literal?
    is_int? || is_float?
  end

  def literal
    i = @current_token[:index]
    return [i, :int_lit, as_int] if is_int?
    return [i, :float_lit, as_float] if is_float?
  end
end
