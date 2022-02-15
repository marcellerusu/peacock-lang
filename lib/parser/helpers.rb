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

    def push(context)
      clone.push! context
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

  def current_token
    @tokens[@token_index]
  end

  def prev_token
    @tokens[@token_index - 1]
  end

  def peek_token
    @tokens[@token_index + 1]
  end

  def more_tokens?
    !end_of_file?
  end

  def consume!(token_type = nil)
    # puts "#{token_type} #{current_token.type}"
    # binding.pry if token_type && token_type != current_token.type
    assert { token_type == current_token.type } unless token_type.nil?
    if current_token.is_a?(:identifier) && current_token.value == "_"
      current_token.value += unused_count.to_s
      increment_unused_count!
    end
    @token_index += 1
    return prev_token
  end

  def new_line?
    @program_string[prev_token.position..current_token.position].include? "\n"
  end

  def end_of_last_token
    assert { prev_token.is_a? :identifier }
    prev_token.position + prev_token.value.size
  end

  def operator?(type = current_token.type)
    OPERATORS.include?(type)
  end

  def end_of_expr?(*excluding)
    return true if current_token.nil?
    return false if current_token.is_one_of? *excluding
    closing_tags = [:close_parenthesis, :close_brace, :close_square_bracket, :end, :then]
    new_line? ||
    current_token.is_one_of?(*closing_tags) ||
    property_accessor? ||
    operator? ||
    current_token.type == :dot ||
    current_token.type == :comma
  end

  def end_of_file?
    @token_index >= @tokens.size
  end
end
