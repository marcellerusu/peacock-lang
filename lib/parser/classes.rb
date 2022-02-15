module Classes
  def parse_class_definition!
    expr_context.push! :class
    class_token = consume! :class
    assert { !new_line? }
    class_name_token = consume! :identifier
    super_class_name = parse_super_class!
    assert { new_line? }
    @token_index, methods = clone(parser_context: parser_context.push(:class)).parse_with_position!
    consume! :end
    assert { methods.all? { |node| node[:node_type] == :declare } }
    expr_context.pop! :class
    AST::class(
      class_name_token.value,
      super_class_name,
      methods,
      class_name_token.position
    )
  end

  def parse_super_class!
    return unless extends?
    consume! :<
    id_token = consume! :identifier
    id_token.value
  end

  def extends?
    return false unless expr_context.directly_in_a? :class
    current_token.is_a? :<
  end
end
