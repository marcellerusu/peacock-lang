module AST
  def self.schema(token)
    # this is for tests only.. :/
    if token.is_a? String
      token = Lexer::Token.new(nil, token, nil)
    end
    IdLookup.new("Schema", token.position)
  end

  def self.schema_any(token)
    schema(token)
      .dot("any")
      .call([AST::Sym.from_token(token)])
  end

  class Node
    attr_reader :value, :position

    def to_h
      val = self.value
      val = value.to_h if value.is_a? Node
      { value: val }
    end

    def position=(val)
      @position = val
    end

    def sub_symbols
      sym
        .sub("?", "_q")
        .sub("!", "_b")
    end

    def call(args = [], position = self.position)
      FnCall.new(args, self, position)
    end

    def dot(property, position = self.position)
      PropertyLookup.new(self, property, position)
    end

    def to_return
      Return.new(self, position)
    end

    def schema_lookup?
      false
    end

    def to_s
      "#{self.class}.new(#{value})"
    end

    def wrap_in_fn
      wrap_in_fn_with([])
    end

    def wrap_in_fn_with(ast)
      AST::Fn.new([], [*ast, self], position)
    end

    def exportable?
      false
    end

    def lookup(expr)
      dot("__lookup__").call([expr])
    end

    def lookup?
      false
    end

    def plus(expr)
      dot("__plus__").call([expr])
    end

    def call_to_s
      dot("to_s").call
    end

    def schema_any?
      false
    end

    def collection?
      false
    end

    def to_schema
      IdLookup.new("Schema", position)
        .dot("for")
        .call([self])
    end
  end

  class NakedOr < Node
    attr_reader :lhs, :rhs

    def to_h
      { lhs: lhs.to_h, rhs: rhs.to_h }
    end

    def initialize(lhs, rhs)
      @lhs = lhs
      @rhs = rhs
    end
  end

  class TryLookup < Node
    def naked_or(rhs)
      NakedOr.new(self, rhs)
    end

    def initialize(value, position)
      @value = value
      @position = position
    end
  end

  class Int < Node
    def self.from_token(token)
      Int.new(token.value, token.position)
    end

    def initialize(value, position)
      @value = value
      @position = position
    end
  end

  class Float < Node
    def self.from_token(token)
      Float.new(token.value, token.position)
    end

    def initialize(value, position)
      @value = value
      @position = position
    end
  end

  class Bool < Node
    def initialize(value, position)
      @value = value
      @position = position
    end
  end

  class Str < Node
    def initialize(value, position)
      @value = value
      @position = position
    end
  end

  class Sym < Node
    def self.from_token(token)
      if token.is_a? String
        token = Lexer::Token.new(nil, token, nil)
      end
      Sym.new(token.value, token.position)
    end

    def initialize(value, position)
      @value = value
      @position = position
    end
  end

  class Nil < Node
    def initialize(position)
      @position = position
    end
  end

  class List < Node
    def to_h
      value.map(&:to_h)
    end

    def initialize(value = [], position = nil)
      assert { value.is_a? Array }
      @value = value
      @position = position
    end

    def collection?
      true
    end

    def each_with_index(&block)
      @value.each_with_index { |v, i| block.call(v, i) }
    end

    def replace_id_lookups_with_schema_any
      new_value = @value.map do |val|
        if val.is_a?(IdLookup)
          val = IdLookup.new("Schema").dot("any").call([Sym.new(key)])
        end
        val
      end

      List.new new_value, position
    end

    def push!(val)
      @value.push val
    end
  end

  class Record < Node
    attr_reader :splats

    def to_h
      { value: value.map { |k, v| [k.to_h, v.to_h] }, splats: splats.to_h }
    end

    def initialize(value, splats, position)
      @value = value
      @splats = splats
      @position = position
    end

    def collection?
      true
    end

    def replace_id_lookups_with_schema_any
      new_value = @value.map do |key, val|
        if val.is_a?(IdLookup)
          val = IdLookup.new("Schema").dot("any").call([Sym.new(key)])
        end
        [key, val]
      end

      Record.new new_value, @splats, position
    end

    def each(&block)
      @value.each { |k, v| block.call(k, v) }
    end

    def insert_sym!(sym, val)
      key = Sym.new(sym, val.position)
      @value.push [key, val]
    end

    def lookup_sym(sym)
      _, value = @value.find { |key, _| key.value == sym }
      value
    end

    def does_not_have_sym?(sym)
      @value.none? do |key, value|
        key.value == sym
      end
    end
  end

  class ParenExpr < Node
    def initialize(value, position)
      @value = value
      @position = position
    end
  end

  class Return < Node
    def initialize(value, position = value.position)
      @value = value
      @position = position
    end
  end

  class If < Node
    attr_reader :pass, :fail, :value
    attr_writer :pass, :fail

    def to_h
      { value: value.to_h, pass: pass.map(&:to_h), fail: self.fail.map(&:to_h) }
    end

    def initialize(value, pass, _fail, position)
      @value = value
      @pass = pass
      @fail = _fail
      @position = position
    end
  end

  class FnCall < Node
    attr_reader :expr, :args

    def to_h
      { args: args.map(&:to_h), expr: expr.to_h }
    end

    def initialize(args, expr, position)
      assert { args.is_a? Array }
      @args = args
      @expr = expr
      @position = position
    end

    def schema_any_name
      assert { schema_any? }
      args[0].value
    end

    def schema_any?
      expr.is_a?(PropertyLookup) &&
      expr.lhs_expr.value == "Schema" &&
      expr.property == "any"
    end
  end

  class Fn < Node
    attr_reader :args, :body

    def to_h
      { args: args, body: body.map(&:to_h) }
    end

    def initialize(args, body, position)
      @args = args
      @body = body
      @position = position
    end

    def declare_with(name, schema)
      Declare.new(name, schema, self, position)
    end
  end

  class IdLookup < Node
    def initialize(value, position)
      @value = value
      @position = position
    end

    def schema?
      return false if value[0] == "_"
      value[0].upcase == value[0]
    end

    def schema_lookup?
      schema?
    end
  end

  class Declare < Node
    attr_reader :name, :schema, :expr

    def to_h
      { name: name, schema: schema.to_h, expr: expr.to_h }
    end

    def initialize(name, schema, expr, position)
      @name = name
      @schema = schema
      @expr = expr
      @position = position
    end

    def exportable?
      true
    end
  end

  class InstanceAssign < Node
    attr_reader :lhs, :expr

    def to_h
      { lhs: lhs.to_h, expr: expr.to_h }
    end

    def initialize(lhs, expr)
      @lhs = lhs
      @expr = expr
      @position = expr.position
    end
  end

  class Assign < Node
    attr_reader :name, :expr

    def to_h
      { name: name, expr: expr.to_h }
    end

    def initialize(name, expr, position = expr.position)
      @name = name
      @expr = expr
      @position = position || expr.position
    end

    def exportable?
      true
    end
  end

  class PropertyLookup < Node
    attr_reader :lhs_expr, :property

    def to_h
      { lhs_expr: lhs_expr.to_h, property: property }
    end

    def initialize(lhs_expr, property, position)
      @lhs_expr = lhs_expr
      @property = property
      @position = position
    end

    def lookup?
      true
    end
  end

  class InstanceMethodLookup < Node
    attr_reader :name

    def to_h
      { name: name }
    end

    def initialize(name, position)
      @name = name
      @position = position
    end

    def or_lookup(args)
      if args.size > 0
        # __try(() => eval('a') || this.a)(arg1, arg2, ..)
        TryLookup.new(self, position)
          .naked_or(self)
          .call(args, position)
      else
        # __try(() => eval('a') || this.a())
        TryLookup.new(self, position)
          .naked_or(self.call)
      end
    end

    def lookup?
      true
    end
  end

  class InstanceLookup < Node
    attr_reader :name

    def to_h
      { name: name }
    end

    def initialize(name, position)
      @name = name
      @position = position
    end
  end

  class Throw < Node
    attr_reader :expr

    def to_h
      { expr: expr.to_h }
    end

    def initialize(expr, position)
      @expr = expr
      @position = position
    end
  end

  class HtmlTag < Node
    attr_reader :name, :attributes, :children

    def to_h
      { name: name.to_h, attributes: attributes.to_h, children: children.to_h }
    end

    def initialize(name, attributes, children, position)
      @name = name
      @attributes = attributes
      @children = children
      @position = position
    end
  end

  class HtmlText < Node
    def initialize(value, position)
      @value = value
      @position = position
    end
  end

  class Class < Node
    attr_reader :name, :super_class, :methods

    def to_h
      { name: name, super_class: super_class, methods: methods.map(&:to_h) }
    end

    def initialize(name, super_class, methods, position)
      @name = name
      @super_class = super_class
      @methods = methods
      @position = position
    end

    def exportable?
      true
    end
  end

  class Case < Node
    attr_reader :expr, :cases

    def to_h
      { expr: expr.to_h, cases: cases.to_h }
    end

    def initialize(expr, cases, position)
      @expr = expr
      @cases = cases
      @position = position
    end
  end
end
