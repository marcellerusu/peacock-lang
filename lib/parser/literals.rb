module Literals
  def parse_sym!
    id_token = consume! :identifier
    if expr_context.directly_in_a?(:schema) && !schema?(id_token.value)
      return call_schema_any(id_token.value)
    end
    AST::identifier_lookup id_token.value, id_token.position
  end

  def parse_identifier!
    return parse_sym! if expr_context.in_a? :schema
    expr = if parser_context.in_a?(:class)
        id_token = consume! :identifier
        AST::instance_method_lookup id_token.value, id_token.position
      else
        parse_sym!
      end
    parse_id_modifier_if_exists!(expr)
  end

  def parse_property!
    token = consume! :property
    node = AST::instance_lookup token.value, token.position
    parse_id_modifier_if_exists!(node)
  end

  def parse_lit!(type)
    token = consume! type
    node = AST::literal token.position, type, token.value
    parse_id_modifier_if_exists!(node)
  end

  def parse_nil!
    token = consume! :nil
    node = AST::nil token.position
    parse_id_modifier_if_exists!(node)
  end

  def parse_bool!(type)
    token = consume! type
    node = AST::bool type == :true, token.position
    parse_id_modifier_if_exists! node
  end

  def parse_str!
    str_token = consume! :str_lit
    str_expr = if str_token.captures.size == 0
        AST::str str_token.value, str_token.position
      else
        strings = []
        strings.push AST::str(
          str_token.value[0...str_token.captures.first[:start] - 2],
          str_token.position
        )
        str_token.captures.each_with_index do |group, i|
          ast = clone(
            tokens: group[:tokens],
            token_index: 0,
            parser_context: parser_context.push(:str),
          ).parse!
          assert { ast.size == 1 }
          strings.push AST::to_s(ast.first)
          if i + 1 < str_token.captures.size
            strings.push AST::str(str_token.value[group[:end] + 1...str_token.captures[i + 1][:start] - 2])
          end
        end
        strings.push AST::str(str_token.value[str_token.captures.last[:end] + 1..])

        strings.reduce do |str, cur|
          AST::plus str, cur
        end
      end
    parse_id_modifier_if_exists! str_expr
  end

  def parse_record_key!
    case current_token.type
    when :identifier
      id_token = consume! :identifier
      AST::sym id_token.value, id_token.position
    when :open_square_bracket
      assert { !expr_context.directly_in_a?(:schema) }
      consume! :open_square_bracket
      val = parse_expr!
      consume! :close_square_bracket
      val
    else
      assert_not_reached
    end
  end

  def try_parse_record_splat!(index)
    return nil if current_token.is_not_a? :*
    splat_token = consume! :*
    splat = parse_expr!
    AST::record(
      {
        AST::sym("splat") => splat,
        AST::sym("index") => AST::int(index),
      },
      AST::array([]),
      splat_token.position
    )
  end

  def parse_record!
    open_brace = consume! :open_brace
    record = {}
    splats = []
    i = 0
    while current_token.is_not_a? :close_brace
      splat = try_parse_record_splat!(i)
      i += 1
      if splat
        splats.push splat
      else
        key = parse_record_key!
        value = if current_token.is_a? :colon
            consume! :colon
            parse_expr!
          elsif expr_context.in_a? :schema
            sym = extract_data_from_constructor(key)
            call_schema_any sym[:sym]
          elsif literal_is_a?(key, "Sym")
            sym = extract_data_from_constructor(key)
            AST::identifier_lookup sym[:value], sym[:position]
          else
            assert_not_reached
          end
        record[key] = value
      end
      consume! :comma if current_token.is_not_a? :close_brace
    end
    consume! :close_brace
    node = AST::record(
      record,
      AST::array(splats.compact),
      open_brace.position
    )
    return parse_match_assignment_without_schema!(node) if current_token&.is_a? :assign
    parse_id_modifier_if_exists!(node)
  end

  def parse_array!
    sq_bracket = consume! :open_square_bracket
    elements = []
    while current_token.is_not_a? :close_square_bracket
      elements.push parse_expr!
      consume! :comma if current_token.is_not_a? :close_square_bracket
    end
    consume! :close_square_bracket
    node = AST::array elements, sq_bracket.position
    return parse_match_assignment_without_schema!(node) if current_token&.is_a? :assign
    parse_id_modifier_if_exists!(node)
  end
end
