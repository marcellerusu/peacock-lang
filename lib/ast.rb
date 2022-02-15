AST_LIT_TO_CONSTRUCTOR = {
  int_lit: "Int",
  str_lit: "Str",
  float_lit: "Float",
  symbol: "Sym",
}

module AST
  def self.remove_numbers_single(node)
    assert { node.is_a? Hash }
    node.delete(:position)
    node[:expr] = AST::remove_numbers_single(node[:expr]) if node[:expr]
    node[:schema] = AST::remove_numbers_single(node[:schema]) if node[:schema]
    node[:property] = AST::remove_numbers_single(node[:property]) if node[:property]
    node[:lhs_expr] = AST::remove_numbers_single(node[:lhs_expr]) if node[:lhs_expr]
    node[:value] = AST::remove_numbers(node[:value]) if node[:value].is_a?(Array)
    node[:value] = AST::remove_numbers_from_hash(node[:value]) if node[:value].is_a?(Hash)
    node[:args] = AST::remove_numbers(node[:args]) if node[:args]
    node[:body] = AST::remove_numbers(node[:body]) if node[:body]
    node[:methods] = AST::remove_numbers(node[:methods]) if node[:methods]
    node[:pass] = AST::remove_numbers(node[:pass]) if node[:pass]
    node[:fail] = AST::remove_numbers(node[:fail]) if node[:fail]
    node[:cases] = AST::remove_numbers_single(node[:cases]) if node[:cases]
    node[:lhs] = AST::remove_numbers_single(node[:lhs]) if node[:lhs]
    node[:rhs] = AST::remove_numbers_single(node[:rhs]) if node[:rhs]
    return node
  end

  def self.remove_numbers(nodes)
    assert { nodes.is_a? Array }
    nodes.map { |n| AST::remove_numbers_single(n) }
  end

  def self.remove_numbers_from_hash(hash)
    hash.map { |k, n| [k, AST::remove_numbers_single(n)] }.to_h
  end

  def self.int(value, position = nil)
    AST::literal_constructor(
      { node_type: :int_lit,
        value: value,
        position: position },
      "Int",
      position
    )
  end

  def self.literal(position, type, value)
    AST::literal_constructor(
      { node_type: type,
        position: position,
        value: value },
      AST_LIT_TO_CONSTRUCTOR[type],
      position
    )
  end

  def self.nil(position = nil)
    AST::literal_constructor(
      { node_type: :nil_lit,
        position: position },
      "Nil",
      position
    )
  end

  def self.array(value, position = nil)
    AST::literal_constructor(
      { node_type: :array_lit,
        position: position,
        value: value },
      "List",
      position
    )
  end

  def self.record(value, splats = AST::array([]), position = nil)
    AST::literal_constructor(
      [
        { node_type: :record_lit,
          position: position,
          value: value },
        splats,
      ],
      "Record",
      position
    )
  end

  def self.sym(value, position = nil)
    AST::literal_constructor(
      { node_type: :symbol,
        position: position,
        value: value },
      "Sym",
      position
    )
  end

  def self.naked_or(lhs, rhs)
    { node_type: :naked_or,
      lhs: lhs,
      rhs: rhs }
  end

  def self.bool(value, position = nil)
    AST::literal_constructor(
      { node_type: :bool_lit,
        position: position,
        value: value },
      "Bool",
      position
    )
  end

  def self.float(value, position = nil)
    AST::literal_constructor(
      { node_type: :float_lit,
        position: position,
        value: value },
      "Float",
      position
    )
  end

  def self.str(value, position = nil)
    AST::literal_constructor(
      { node_type: :str_lit,
        position: position,
        value: value },
      "Str",
      position
    )
  end

  def self.paren_expr(expr, position = nil)
    { node_type: :paren_expr,
      expr: expr,
      position: position }
  end

  def self.return(expr, position = expr[:position])
    { node_type: :return,
      position: position,
      expr: expr }
  end

  def self.if(expr, pass, _fail, position = nil)
    { node_type: :if,
      position: position,
      expr: expr,
      pass: pass,
      fail: _fail }
  end

  def self.function_call(args, expr, position = nil)
    { node_type: :function_call,
      position: position,
      args: args,
      expr: expr }
  end

  def self.function(args, body, position = nil)
    { node_type: :function,
      position: position,
      args: args,
      body: body }
  end

  def self.function_argument(sym, position = nil)
    { node_type: :function_argument,
      position: position,
      sym: sym }
  end

  def self.identifier_lookup(sym, position = nil)
    { node_type: :identifier_lookup,
      position: position,
      sym: sym }
  end

  def self.declare(sym, schema, expr, position = nil)
    { node_type: :declare,
      sym: sym,
      position: position,
      schema: schema,
      expr: expr }
  end

  def self.instance_assignment(lhs, expr)
    { node_type: :instance_assign,
      sym: lhs[:sym],
      position: lhs[:position],
      expr: expr }
  end

  def self.assignment(sym, expr, position = nil)
    { node_type: :assign,
      sym: sym,
      position: position,
      expr: expr }
  end

  def self.property_lookup(position, lhs_expr, property)
    # just convert to string for now... TODO: idk
    { node_type: :property_lookup,
      lhs_expr: lhs_expr,
      position: position,
      property: property }
  end

  def self.dot(lhs_expr, id, position = nil)
    id = [id.position, id.value] if id.class == Lexer::Token
    id = [lhs_expr[:position], id] if id.is_a?(String)
    lit_position, sym = id
    property = { position: lit_position, node_type: :str_lit, value: sym }
    AST::property_lookup position, lhs_expr, property
  end

  def self.instance_method_lookup(name, position = nil)
    { node_type: :instance_method_lookup,
      sym: name,
      position: position }
  end

  def self.instance_lookup(name, position = nil)
    { node_type: :instance_lookup,
      sym: name,
      position: position }
  end

  def self.lookup(lhs, expr)
    AST::function_call(
      [expr],
      AST::dot(lhs, "__lookup__", lhs[:position])
    )
  end

  def self.plus(expr_a, expr_b)
    AST::function_call([expr_b], AST::dot(expr_a, "__plus__"))
  end

  def self.to_s(expr)
    AST::function_call([], AST::dot(expr, "to_s"))
  end

  def self.throw(expr, position = nil)
    { node_type: :throw,
      position: position,
      expr: expr }
  end

  def self.literal_constructor(args, type_name, position = nil)
    args = [args] unless args.is_a? Array
    AST::function_call(
      args,
      AST::dot(
        AST::identifier_lookup(type_name, position),
        [position, "new"],
        position
      ),
      position
    )
  end

  def self.html_tag(name, attributes, children, position = nil)
    { node_type: :html_tag,
      name: name,
      attributes: attributes,
      children: children,
      position: position }
  end

  def self.html_text_node(value, position = nil)
    { node_type: :html_text_node,
      value: value,
      position: position }
  end

  def self.class(name, super_class, methods, position = nil)
    { node_type: :class,
      sym: name,
      super_class: super_class,
      methods: methods,
      position: position }
  end

  def self.case(expr, cases, position = nil)
    { node_type: :case,
      expr: expr,
      cases: cases,
      position: position }
  end

  # TODO Nasty helpers

  def self.try_lookup(sym, position)
    raw_str = { node_type: :str_lit,
                position: position,
                value: sym }
    AST::function_call(
      [AST::function(
        [],
        [AST::return(AST::function_call([raw_str], AST::identifier_lookup("eval")))]
      )],
      AST::identifier_lookup("__try")
    )
  end

  def self.or_lookup(node, args)
    position = node[:position]
    if args.size == 0
      AST::naked_or(
        AST::try_lookup(node[:sym], position),
        AST::function_call([], node, position)
      )
    else
      AST::function_call(
        args,
        AST::naked_or(
          AST::try_lookup(node[:sym], position),
          node
        ),
        position
      )
    end
  end
end
