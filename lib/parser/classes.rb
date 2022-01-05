module Classes
  def parse_class_definition!
    line, _ = consume! :class
    _, c, class_name = consume! :identifier
    args = []
    while peek_type != :declare
      line1, c1, arg_name = consume! :identifier
      args.push(AST::function_argument(arg_name, line1, c1))
    end
    consume! :declare
    assert { new_line? }
    # next_line!
    @token_index, methods = Parser.new(@tokens, @token_index, @indentation + 2, :class).parse_with_position!
    assert { methods.all? { |node| node[:node_type] == :declare } }
    # TODO: wtf
    # @token_index = statement.size - 1
    AST::class(
      class_name,
      args,
      methods,
      line,
      c
    )
  end
end
