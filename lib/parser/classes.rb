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
    @line, @token_index, methods = Parser.new(@statements, @line, @token_index, @indentation + 2, :class).parse_with_position!
    # binding.pry
    assert { methods.all? { |node| node[:node_type] == :declare } }
    AST::class(
      class_name,
      args,
      methods,
      line,
      c
    )
  end
end
