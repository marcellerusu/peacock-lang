module Classes
  def parse_class_definition!
    context.push! :class
    class_token = consume! :class
    assert { !new_line? }
    class_name_token = consume! :identifier
    super_class_name = parse_super_class! if current_token.is? :<
    assert { new_line? }
    @token_index, methods = clone(context: context.push(:class)).parse_with_position!
    consume! :end
    assert { methods.all? { |node| node.is_a? AST::Declare } }
    context.pop! :class
    AST::Class.new(
      class_name_token.value,
      super_class_name,
      methods,
      class_name_token.position
    )
  end

  def parse_super_class!
    consume! :<
    id_token = consume! :identifier
    id_token.value
  end
end
