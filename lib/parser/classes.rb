module Classes
  def parse_class_definition!
    expr_context.push! :class
    line, _ = consume! :class
    _, c, class_name = consume! :identifier
    super_class = parse_super_class!
    args = parse_class_args! if super_class.nil?
    consume! :declare
    assert { new_line? }
    @token_index, methods = clone(
      indentation: @indentation + 2,
      parser_context: parser_context.clone.push!(:class),
    ).parse_with_position!
    assert { methods.all? { |node| node[:node_type] == :declare } }
    expr_context.pop! :class
    AST::class(
      class_name,
      super_class,
      args || [],
      methods,
      line,
      c
    )
  end

  def parse_super_class!
    return unless extends?
    consume! :lt
    _, _, name = consume! :identifier
    name
  end

  def parse_class_args!
    args = []
    while peek_type != :declare
      line, c, arg_name = consume! :identifier
      args.push(AST::function_argument(arg_name, line, c))
    end
    args
  end

  def extends?
    return false unless expr_context.directly_in_a? :class
    peek_type == :lt
  end
end
