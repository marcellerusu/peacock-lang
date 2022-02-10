module Classes
  def parse_class_definition!
    expr_context.push! :class
    line, _ = consume! :class
    _, c, class_name = consume! :identifier
    super_class = parse_super_class!
    # args = parse_class_args! if super_class.nil?
    assert { new_line? }
    @token_index, methods = clone(parser_context: parser_context.clone.push!(:class)).parse_with_position!
    consume! :end
    assert { methods.all? { |node| node[:node_type] == :declare } }
    expr_context.pop! :class
    AST::class(
      class_name,
      super_class,
      methods,
      line,
      c
    )
  end

  def parse_super_class!
    return unless extends?
    consume! :<
    _, _, name = consume! :identifier
    name
  end

  def parse_class_args!
    args = []
    while peek_type != :"="
      line, c, arg_name = consume! :identifier
      args.push(AST::function_argument(arg_name, line, c))
    end
    args
  end

  def extends?
    return false unless expr_context.directly_in_a? :class
    peek_type == :<
  end
end
