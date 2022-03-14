module Literals
  def parse_identifier!
    id_token = consume! :identifier
    expr = AST::IdLookup.new(id_token.value, id_token.position)
      .to_schema_any_depending_on(expr_context)
      .to_instance_method_lookup_depending_on(parser_context)
    return expr if expr_context.in_a? :schema
    parse_id_modifier_if_exists! expr
  end

  def parse_property!
    token = consume! :property
    node = AST::InstanceLookup.new token.value, token.position
    parse_id_modifier_if_exists! node
  end

  def parse_int!
    node = AST::Int.from_token consume!(:int_lit)
    parse_id_modifier_if_exists! node
  end

  def parse_float!
    node = AST::Float.from_token consume!(:float_lit)
    parse_id_modifier_if_exists! node
  end

  def parse_symbol!
    node = AST::Sym.from_token consume!(:symbol)
    parse_id_modifier_if_exists! node
  end

  def parse_nil!
    token = consume! :nil
    node = AST::Nil.new token.position
    parse_id_modifier_if_exists! node
  end

  def parse_bool!(type)
    token = consume! type
    node = AST::Bool.new type == :true, token.position
    parse_id_modifier_if_exists! node
  end

  def parse_str!
    str_token = consume! :str_lit
    str_expr = parse_str_interpolation! str_token
    parse_id_modifier_if_exists! str_expr
  end

  def parse_str_interpolation!(str_token)
    if str_token.captures.size == 0
      return AST::Str.new str_token.value, str_token.position
    end
    strings = []
    strings.push str_before_captures(str_token)
    str_token.captures.each_with_index do |group, i|
      ast = clone(
        tokens: group[:tokens],
        token_index: 0,
        parser_context: parser_context.push(:str),
      ).parse!
      assert { ast.size == 1 }
      strings.push ast.first.call_to_s
      strings.push str_between_escape(str_token, i)
    end
    strings.push AST::Str.new(str_token.value[str_token.captures.last[:end] + 1..], nil)

    strings.compact.reduce do |str, cur|
      str.plus(cur)
    end
  end

  def str_before_captures(str_token)
    # in example "oh shit #{1} something #{2}"
    # we're parsing "oh shit "
    start_index = 0
    # - 2 is to ignore `#{`
    end_index = str_token.captures[0][:start] - 2
    AST::Str.new(str_token.value[start_index...end_index], str_token.position)
  end

  def str_between_escape(str_token, i)
    return nil if i + 1 == str_token.captures.size
    # in example "oh shit #{1} something #{2}"
    # we're parsing " something "
    start_index = str_token.captures[i][:end] + 1
    # - 2 is to ignore `#{`
    end_index = str_token.captures[i + 1][:start] - 2
    AST::Str.new(str_token.value[start_index...end_index], str_token.position)
  end

  def parse_record!
    open_brace = consume! :"{"
    record = []
    splats = []
    # this is only being used for splat index
    i = 0
    while current_token.is_not_a? :"}"
      splats.push(try_parse_record_splat!(i))
      i += 1
      consume! :comma if current_token.is_a? :comma
      break if current_token.is_a? :"}"
      key = parse_record_key!
      value = parse_record_value! key
      record.push [key, value]
      consume! :comma if current_token.is_not_a? :"}"
    end
    consume! :"}"
    node = AST::Record.new(
      record,
      AST::List.new(splats.compact),
      open_brace.position
    )
    return parse_match_assignment_without_schema!(node) if current_token&.is_a? :assign
    parse_id_modifier_if_exists!(node)
  end

  def parse_record_key!
    case current_token.type
    when :identifier
      id_token = consume! :identifier
      AST::Sym.new id_token.value, id_token.position
    when :"["
      assert { !expr_context.directly_in_a?(:schema) }
      consume! :"["
      val = parse_expr!
      consume! :"]"
      val
    else
      assert_not_reached
    end
  end

  def parse_record_value!(key)
    if current_token.is_a? :colon
      consume! :colon
      parse_expr!
    elsif expr_context.in_a? :schema
      AST::schema_any(key)
    elsif key.is_a?(AST::Sym)
      AST::IdLookup.new key.value, key.position
    else
      assert_not_reached
    end
  end

  def try_parse_record_splat!(index)
    return nil if current_token.is_not_a? :*
    splat_token = consume! :*
    splat = parse_expr!
    AST::Record.new(
      [
        [AST::Sym.new("splat", splat_token.position), splat],
        [AST::Sym.new("index", splat_token.position), AST::Int.new(index, splat_token.position)],
      ],
      AST::List.new([]),
      splat_token.position
    )
  end

  def parse_list!
    sq_bracket = consume! :"["
    elements = []
    while current_token.is_not_a? :"]"
      elements.push parse_expr!
      consume! :comma if current_token.is_not_a? :"]"
    end
    consume! :"]"
    node = AST::List.new elements, sq_bracket.position
    return parse_match_assignment_without_schema!(node) if current_token&.is_a? :assign
    parse_id_modifier_if_exists!(node)
  end
end
