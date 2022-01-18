module Literals
  def parse_sym!
    line, c, sym = consume! :identifier
    return call_schema_any(sym) if expr_context.directly_in_a?(:schema) && !schema?(sym)
    AST::identifier_lookup sym, line, c
  end

  def parse_identifier!
    expr = if parser_context.in_a?(:class) && !is_function?(1)
        line, c, sym = consume! :identifier
        AST::instance_method_lookup sym, line, c
      else
        parse_sym!
      end
    parse_id_modifier_if_exists!(expr)
  end

  def parse_property!
    line, c, name = consume! :property
    node = AST::instance_lookup name, line, c
    parse_id_modifier_if_exists!(node)
  end

  def parse_lit!(type)
    line, c, lit = consume! type
    node = AST::literal line, c, type, lit
    parse_id_modifier_if_exists!(node)
  end

  def parse_nil!
    line, c, _ = consume! :nil
    AST::nil line, c
  end

  def parse_bool!(type)
    line, c, _ = consume! type
    AST::bool type == :true, line, c
  end

  def parse_str!
    line, c, value, _, escaped = consume! :str_lit
    str_expr = if escaped.size == 0
        AST::str value, line, c
      else
        strings = []
        strings.push AST::str(value[0...escaped.first[:start] - 2], line, c)
        escaped.each_with_index do |group, i|
          ast = clone(
            tokens: group[:tokens],
            token_index: 0,
            indentation: 0,
          ).parse!
          assert { ast.size == 1 }
          strings.push AST::to_s(ast.first)
          if i + 1 < escaped.size
            strings.push AST::str(value[group[:end] + 1...escaped[i + 1][:start] - 2])
          end
        end
        strings.push AST::str(value[escaped.last[:end] + 1..])

        strings.reduce do |str, cur|
          AST::plus str, cur
        end
      end
    parse_id_modifier_if_exists! str_expr
  end

  def parse_record_key!
    if peek_type == :identifier
      line, c, sym = consume! :identifier
      AST::sym sym, line, c
    elsif peek_type == :open_square_bracket
      assert { !expr_context.directly_in_a?(:schema) }
      consume! :open_square_bracket
      val = parse_expr!
      consume! :close_square_bracket
      val
    else
      assert_not_reached
    end
  end

  def parse_record!
    line, c, _ = consume! :open_brace
    record = {}
    while peek_type != :close_brace
      key = parse_record_key!
      value = if peek_type == :colon
          consume! :colon
          parse_expr!
        elsif expr_context.directly_in_a? :schema
          sym = extract_data_from_constructor(key)
          call_schema_any sym[:sym]
        elsif literal_is_a?(key, "Sym")
          sym = extract_data_from_constructor(key)
          AST::identifier_lookup sym[:value], sym[:line], sym[:column]
        else
          assert_not_reached
        end
      record[key] = value
      consume! :comma unless peek_type == :close_brace
    end
    consume! :close_brace
    node = AST::record(record, line, c)
    return parse_match_assignment_without_schema!(node) if peek_type == :assign
    parse_id_modifier_if_exists!(node)
  end

  def parse_array!
    line, c, _ = consume! :open_square_bracket
    elements = []
    while peek_type != :close_square_bracket
      elements.push parse_expr!
      consume! :comma unless peek_type == :close_square_bracket
    end
    consume! :close_square_bracket
    node = AST::array elements, line, c
    return parse_match_assignment_without_schema!(node) if peek_type == :assign
    parse_id_modifier_if_exists!(node)
  end
end
