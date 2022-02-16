module Functions
  def parse_bang!
    consume! :bang
    expr = parse_expr!
    expr.dot("bang").call
  end

  def property_accessor?
    current_token.is_a?(:open_square_bracket) &&
      end_of_last_token == current_token.position
  end

  def function_call?(node)
    return true if current_token&.is_a? :open_parenthesis
    return false if !node.lookup?
    return true if node.lookup? && end_of_expr?
    cloned = clone
    begin
      cloned.parse_function_call_args_without_paren!
    rescue AssertionError
      return false
    else
      return true
    end
  end

  def parse_anon_function_shorthand!
    fn_start_token = consume! :anon_short_fn_start
    # binding.pry
    expr = parse_expr!
    assert { !expr.is_a?(AST::Return) }
    expr = expr.to_return unless expr.is_a? AST::If
    consume! :close_brace
    AST::Fn.new [ANON_SHORTHAND_ID], [expr], fn_start_token.position
  end

  def parse_anon_short_id!
    id_token = consume! :anon_short_id
    sym_expr = AST::IdLookup.new ANON_SHORTHAND_ID, id_token.position
    parse_id_modifier_if_exists!(sym_expr)
  end

  def parse_function_args_schema!
    args = AST::List.new([])
    matches = []
    # in case of
    # def f = 0
    # OR
    # def f
    #   function_code()
    # end
    if current_token.is_a?(:"=") || new_line?
      return args.to_schema, matches
    end
    list_schema_index = 0
    consume! :open_parenthesis
    expr_context.push! :declare
    while current_token.is_not_a?(:close_parenthesis)
      schema, new_matches = parse_schema_literal! list_schema_index
      args.push! schema
      consume! :comma if current_token.is_not_a? :close_parenthesis
      matches += new_matches
      list_schema_index += 1
    end
    expr_context.pop! :declare
    consume! :close_parenthesis
    return args.to_schema, matches
  end

  def parse_function_def!
    consume! :def
    id_token = consume! :identifier
    args_schema, matches = parse_function_args_schema!
    is_single_expr = false
    if current_token.is_a? :"="
      is_single_expr = true
      consume! :"="
    end

    if new_line?
      assert { !is_single_expr }
      @token_index, body = clone(parser_context: parser_context.push(:function)).parse_with_position!
      consume! :end
    else
      expr = parse_expr!
      body = [expr.to_return]
    end
    body = matches.map do |path_and_sym|
      sym, path = path_and_sym.last, path_and_sym[0...-1]
      AST::Assign.new(
        sym,
        eval_path_on_expr(path, AST::IdLookup.new("__VALUE", id_token.position)),
        id_token.position
      )
    end + body

    AST::Fn.new(["__VALUE"], body, id_token.position)
      .declare_with(id_token.value, args_schema)
  end

  def parse_anon_function_def!
    do_token = consume! :do
    args = []
    if current_token.is_a? :"|"
      consume! :"|"
      while current_token.is_not_a?(:"|")
        id_token = consume! :identifier
        args.push id_token.value
        consume! :comma if current_token.is_not_a? :"|"
      end
      consume! :"|"
    end
    @token_index, body = clone(parser_context: parser_context.push(:function)).parse_with_position!
    consume! :end
    AST::Fn.new args, body, do_token.position
  end

  def parse_function_call_args_with_paren!
    consume! :open_parenthesis
    args = []
    while current_token.is_not_a? :close_parenthesis
      args.push parse_expr!
      consume! :comma if current_token.is_not_a? :close_parenthesis
    end
    consume! :close_parenthesis
    args
  end

  def parse_function_call_args_without_paren!
    args = []
    return args if current_token&.is_a? :comma
    until end_of_expr?
      args.push parse_expr!
      # TODO: shouldn't this be a break?
      next if current_token&.is_a? :do
      break if end_of_expr?(:comma)
      consume! :comma
    end
    args
  end

  def parse_function_call!(fn_expr)
    args = if current_token&.is_a? :open_parenthesis
        parse_function_call_args_with_paren!
      else
        parse_function_call_args_without_paren!
      end
    # TODO: I think this is the problem right here AST::InstanceMethodLookup
    return fn_expr.or_lookup(args) if fn_expr.is_a? AST::InstanceMethodLookup
    return parse_match_assignment!(fn_expr, args[0]) if args.size == 1 && current_token&.is_a?(:assign)
    fn_expr.call(args)
  end
end
