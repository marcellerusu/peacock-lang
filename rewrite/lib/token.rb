TOKENS = {
  "=" => :assign,
  "let" => :let,
  "==" => :eq,
  "!=" => :not_eq,
  "|>" => :pipe,
  "(" => :open_p,
  ")" => :close_p,
  "{" => :open_b,
  "}" => :close_b,
  "[" => :open_sb,
  "]" => :close_sb,
  "=>" => :arrow,
  ":" => :colon,
  "," => :comma,
}

class Token
  def initialize(token, index)
    @token = token
    @index = index
  end

  def consume(char)
    @token += char
  end

  def as_keyword(peek)
    if k = keyword(peek)
      return [@index, k]
    end
  end

  def as_symbol
    [@index, :sym, @token]
  end

  def as_literal
    return [@index, :int_lit, as_int] if is_int?
    return [@index, :float_lit, as_float] if is_float?
  end

  def is_literal?
    is_int? || is_float?
  end

  private

  def keyword(peek)
    TOKENS[@token] if !peek || (peek && !TOKENS.include?(@token + peek))
  end

  def is_int?
    as_int.to_s == @token
  end

  def as_int
    @token.to_i
  end

  def is_float?
    as_float.to_s == @token
  end

  def as_float
    @token.to_f
  end
end
