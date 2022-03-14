module Helpers
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

  def can_parse?
    cloned_parser = clone
    begin
      yield cloned_parser
    rescue AssertionError
      return false
    else
      return true
    end
  end

  def consume!(token_type = nil)
    # puts "#{token_type} #{current_token.type}"
    # binding.pry if token_type && token_type != current_token.type
    assert { token_type == current_token.type } unless token_type.nil?
    if current_token.is?(:identifier) && current_token.value == "_"
      current_token.value += unused_count.to_s
      increment_unused_count!
    end
    @token_index += 1
    return prev_token
  end

  def new_line?
    @program_string[prev_token.position..current_token.position].include? "\n"
  end

  def line_has?(token)
    # end of file
    return false if current_token.nil?
    # no more new lines
    if @program_string[current_token.position..].index("\n") == nil
      return @tokens[@token_index..].any? { |t| t.is?(token) }
    end
    # somewhere in the file
    new_line_index = @program_string[current_token.position..].index("\n") + current_token.position
    index = @token_index
    while @tokens[index] && @tokens[index].position < new_line_index
      if @tokens[index].is?(token)
        return true
      end
      index += 1
    end
    return false
  end

  def line_does_not_have?(token)
    !line_has?(token)
  end

  def position_at_end_of_last_token
    assert { prev_token.is? :identifier }
    prev_token.position + prev_token.value.size
  end

  def operator?(type = current_token.type)
    # TODO: remove, look at operator? in Parser
    OPERATORS.include?(type)
  end

  def end_of_expr?(*excluding)
    return true if end_of_file?
    return false if current_token.is_one_of? *excluding
    closing_tags = [:close_paren, :"}", :"]", :with, :end, :then]
    new_line? ||
    current_token.is_one_of?(*closing_tags) ||
    dynamic_lookup? ||
    operator? ||
    current_token.type == :dot ||
    current_token.type == :comma
  end

  def end_of_file?
    @token_index >= @tokens.size
  end
end
