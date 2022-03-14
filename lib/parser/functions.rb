module Functions
  def parse_bang!
    consume! :"!"
    expr = parse_expr!
    expr.dot("bang").call
  end

  def dynamic_lookup?
    current_token.is_a?(:"[") &&
      # a[x] works, but a [x] doesn't!
      position_at_end_of_last_token == current_token.position
  end

  def arrow_function?
    return false if line_does_not_have?(:"=>")
    can_parse? do |parser|
      parser.parse_arrow_args!
      assert { parser.current_token.is_a? :"=>" }
    end
  end

  def parse_arrow_args!
    if current_token.is_a?(:"(")
      consume! :"("
      args = []
      while current_token.is_not_a?(:")") && !new_line?
        args.push consume!(:identifier).value
        consume! :comma if current_token.is_not_a?(:")")
      end
      consume! :")"
      return args
    else
      arg = consume! :identifier
      args = [arg.value]
      return args
    end
  end

  def parse_arrow_function!
    position = current_token.position
    args = parse_arrow_args!
    consume! :"=>"
    body = parse_function_body! one_liner: true
    AST::ArrowFn.new(args, body, position)
  end

  def function_call?(node)
    return true if current_token&.is_a? :"("
    return false if !node.lookup?
    return true if node.lookup? && end_of_expr?
    can_parse? do |parser|
      parser.parse_function_call_args_without_paren!
    end
  end

  def parse_anon_function_shorthand!
    fn_start_token = consume! :"#\{"
    expr = parse_expr!
    assert { !expr.is_a?(AST::Return) }
    expr = expr.to_return unless expr.is_a? AST::If
    consume! :"}"
    AST::ShortFn.new [ANON_SHORTHAND_ID], [expr], fn_start_token.position
  end

  def parse_anon_short_id!
    id_token = consume! :%
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
    consume! :"("
    expr_context.push! :declare
    while current_token.is_not_a?(:")")
      schema, new_matches = parse_schema_literal! list_schema_index
      args.push! schema
      consume! :comma if current_token.is_not_a? :")"
      matches += new_matches
      list_schema_index += 1
    end
    expr_context.pop! :declare
    consume! :")"
    return args.to_schema, matches
  end

  def parse_function_body!(one_liner: false, check_new_line: false)
    if one_liner
      expr = parse_expr!
      [expr.to_return]
    else
      assert { new_line? } if check_new_line
      @token_index, body = clone(parser_context: parser_context.push(:function)).parse_with_position!
      body
    end
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

    body = parse_function_body! one_liner: is_single_expr
    consume! :end if !is_single_expr

    arg_lookup = AST::IdLookup.new("__VALUE", id_token.position)
    decalartions = declare_variables_from(matches, arg_lookup)
    body = decalartions + body

    AST::Fn.new(["__VALUE"], body, id_token.position)
      .declare_with(id_token.value, args_schema)
  end

  def parse_do_fn_args!
    args = []
    return args if current_token.is_not_a? :"|"

    consume! :"|"
    while current_token.is_not_a?(:"|")
      id_token = consume! :identifier
      args.push id_token.value
      consume! :comma if current_token.is_not_a? :"|"
    end
    consume! :"|"

    args
  end

  def parse_anon_function_def!
    do_token = consume! :do
    args = parse_do_fn_args!
    body = parse_function_body! check_new_line: false
    consume! :end
    AST::Fn.new args, body, do_token.position
  end

  def parse_function_call_args_with_paren!
    consume! :"("
    args = []
    while current_token.is_not_a? :")"
      args.push parse_expr!
      consume! :comma if current_token.is_not_a? :")"
    end
    consume! :")"
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
    args = if current_token&.is_a? :"("
        parse_function_call_args_with_paren!
      else
        parse_function_call_args_without_paren!
      end
    # TODO: I think this is the problem right here AST::InstanceMethodLookup
    return fn_expr.or_lookup(args) if fn_expr.is_a? AST::InstanceMethodLookup
    return parse_match_assignment!(fn_expr, args[0]) if args.size == 1 && current_token&.is_a?(:":=")
    fn_expr.call(args)
  end
end
