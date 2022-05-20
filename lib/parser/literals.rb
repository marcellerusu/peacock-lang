module Literals
  def parse_identifier!
    id_token = consume! :identifier
    context.push! :identifier
    expr = AST::IdLookup.new(id_token.value, id_token.position)
      .to_schema_capture_depending_on(context)
    return expr if context.in_a? :schema
    res = parse_id_modifier_if_exists! expr
    context.pop! :identifier
    res
  end

  def parse_int!
    node = AST::Int.from_token consume!(:int_lit)
    parse_id_modifier_if_exists! node
  end

  def parse_float!
    node = AST::Float.from_token consume!(:float_lit)
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
        context: context.push(:str),
      ).parse!
      assert { ast.size == 1 }
      strings.push ast.first
      strings.push str_between_escape(str_token, i)
    end
    strings.push AST::Str.new(str_token.value[str_token.captures.last[:end] + 1..], nil)

    AST::StrTemplate.new strings
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

  def parse_object_literal!
    open_brace = consume! :"{"
    record = []
    spreads = []
    # this is only being used for spread index
    i = 0
    while current_token.is_not? :"}"
      spreads.push(try_parse_object_literal_spread!(i))
      i += 1
      consume! :comma if current_token.is? :comma
      break if current_token.is? :"}"
      key = parse_object_literal_key!
      value = parse_object_literal_value! key
      record.push [key, value]
      consume! :comma if current_token.is_not? :"}"
    end
    consume! :"}"
    node = AST::ObjectLiteral.new(
      record,
      spreads.compact,
      open_brace.position
    )
    return parse_match_assignment!(node) if current_token&.is? :assign
    parse_id_modifier_if_exists!(node)
  end

  def parse_object_literal_key!
    case current_token.type
    when :identifier
      id_token = consume! :identifier
      AST::Str.new id_token.value, id_token.position
    when :"["
      assert { !context.directly_in_a?(:schema) }
      consume! :"["
      val = parse_expr!
      consume! :"]"
      val
    else
      assert_not_reached
    end
  end

  def parse_object_literal_value!(key)
    if current_token.is? :colon
      consume! :colon
      parse_expr!
    elsif context.in_a? :schema
      AST::SchemaCapture.new(key.value, key.position)
    elsif key.is_a?(AST::Str)
      AST::IdLookup.new key.value, key.position
    else
      assert_not_reached
    end
  end

  def try_parse_object_literal_spread!(index)
    return nil if current_token.is_not? :"..."
    spread_token = consume! :"..."
    spread = parse_expr!
  end

  def parse_array_literal!
    sq_bracket = consume! :"["
    elements = []
    while current_token.is_not? :"]"
      elements.push parse_expr!
      consume! :comma if current_token.is_not? :"]"
    end
    consume! :"]"
    node = AST::ArrayLiteral.new elements, sq_bracket.position
    return parse_match_assignment! node if current_token&.is? :assign
    parse_id_modifier_if_exists! node
  end
end
