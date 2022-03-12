module Literals
  def parse_identifier!
    id_token = consume! :identifier
    expr = AST::IdLookup.new(id_token.value, id_token.position)
      .to_schema_any_depending_on(expr_context)
      .to_instance_method_lookup_depending_on(parser_context)
    return expr if expr_context.in_a? :schema
    parse_id_modifier_if_exists!(expr)
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
    str_expr = if str_token.captures.size == 0
        AST::Str.new str_token.value, str_token.position
      else
        strings = []
        strings.push AST::Str.new(
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
          strings.push ast.first.call_to_s
          if i + 1 < str_token.captures.size
            strings.push AST::Str.new(str_token.value[group[:end] + 1...str_token.captures[i + 1][:start] - 2], nil)
          end
        end
        strings.push AST::Str.new(str_token.value[str_token.captures.last[:end] + 1..], nil)

        strings.reduce do |str, cur|
          str.plus(cur)
        end
      end
    parse_id_modifier_if_exists! str_expr
  end

  def parse_record_key!
    case current_token.type
    when :identifier
      id_token = consume! :identifier
      AST::Sym.new id_token.value, id_token.position
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
    AST::Record.new(
      [
        [AST::Sym.new("splat", splat_token.position), splat],
        [AST::Sym.new("index", splat_token.position), AST::Int.new(index, splat_token.position)],
      ],
      AST::List.new([]),
      splat_token.position
    )
  end

  def parse_record!
    open_brace = consume! :open_brace
    record = []
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
            AST::schema_any(key)
          elsif key.is_a?(AST::Sym)
            AST::IdLookup.new key.value, key.position
          else
            assert_not_reached
          end
        record.push [key, value]
      end
      consume! :comma if current_token.is_not_a? :close_brace
    end
    consume! :close_brace
    node = AST::Record.new(
      record,
      AST::List.new(splats.compact),
      open_brace.position
    )
    return parse_match_assignment_without_schema!(node) if current_token&.is_a? :assign
    parse_id_modifier_if_exists!(node)
  end

  def parse_list!
    sq_bracket = consume! :open_square_bracket
    elements = []
    while current_token.is_not_a? :close_square_bracket
      elements.push parse_expr!
      consume! :comma if current_token.is_not_a? :close_square_bracket
    end
    consume! :close_square_bracket
    node = AST::List.new elements, sq_bracket.position
    return parse_match_assignment_without_schema!(node) if current_token&.is_a? :assign
    parse_id_modifier_if_exists!(node)
  end
end
