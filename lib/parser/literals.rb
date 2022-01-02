module Literals
  def parse_sym!
    c, sym = consume! :identifier
    return call_schema_any(sym) if expr_context.is_a?(:schema) && !schema?(sym)
    AST::identifier_lookup sym, @line, c
  end

  def parse_identifier!
    sym_expr = parse_sym!
    parse_id_modifier_if_exists!(sym_expr)
  end

  def parse_property!
    c, name = consume! :property
    node = AST::instance_lookup name, @line, c
    parse_id_modifier_if_exists!(node)
  end

  def parse_lit!(type)
    c, lit = consume! type
    AST::literal @line, c, type, lit
  end

  def parse_nil!
    c, _ = consume! :nil
    AST::nil @line, c
  end

  def parse_bool!(type)
    c, _ = consume! type
    AST::bool type == :true, @line, c
  end

  def parse_record!
    c, _ = consume! :open_brace
    record = {}
    line = @line
    while peek_type != :close_brace
      # TODO: will have to allow more than strings as keys at some point
      c1, sym = consume! :identifier
      if peek_type == :colon
        consume! :colon
        record[sym] = parse_expr!
      elsif expr_context.is_a?(:schema)
        record[sym] = call_schema_any(sym)
      else
        record[sym] = AST::identifier_lookup(sym, line, c1)
      end
      consume! :comma unless peek_type == :close_brace
    end
    consume! :close_brace
    node = AST::record record, line, c
    return parse_match_assignment_without_schema!(node) if peek_type == :assign
    # TODO: make more specific to records
    parse_id_modifier_if_exists!(node)
  end

  def parse_array!
    c, _ = consume! :open_square_bracket
    elements = []
    line = @line
    while peek_type != :close_square_bracket
      elements.push parse_expr!
      consume! :comma unless peek_type == :close_square_bracket
    end
    consume! :close_square_bracket
    node = AST::array elements, line, c
    return parse_match_assignment_without_schema!(node) if peek_type == :assign
    # TODO: make more specific to records
    parse_id_modifier_if_exists!(node)
  end
end
