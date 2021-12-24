module Classes
  def parse_class_definition!
    consume! :class
    line = @line
    c, class_name = consume! :identifier
    args = []
    while peek_type != :declare
      c1, arg_name = consume! :identifier
      args.push(AST::function_argument(arg_name, @line, c1))
    end
    consume! :declare
    next_line!
    @line, @token_index, methods = Parser.new(@statements, @line, @token_index, @indentation + 2, :class).parse_with_position!
    assert { methods.all? { |node| node[:node_type] == :declare } }
    # TODO: wtf
    # @line -= 1
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
