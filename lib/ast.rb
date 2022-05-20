module AST
  def self.schema(token)
    # this is for tests only.. :/
    if token.is_a? String
      token = Lexer::Token.new(nil, token, nil)
    end
    IdLookup.new("Schema", token.position)
  end

  class Node
    attr_reader :value, :position

    def is_not_one_of?(*klasses)
      klasses.none? { |klass| self.is_a? klass }
    end

    def is_not_a?(klass)
      !is_a?(klass)
    end

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

    def lookup?
      false
    end

    def plus(expr)
      Add.new(self, expr, self.position)
    end

    def collection?
      false
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

  class None < Node
  end

  class Int < Node
    def self.from_token(token)
      Int.new(token.value, token.position)
    end

    def from_schema
      None.new
    end

    def to_schema
      self
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

  class StrTemplate < Node
    def initialize(strings)
      @strings = strings
    end
  end

  class Str < Node
    def initialize(value, position)
      @value = value
      @position = position
    end

    def alpha_numeric?
      !!(value =~ /^[a-zA-Z_]+$/)
    end

    def captures
      []
    end
  end

  class Nil < Node
    def initialize(position)
      @position = position
    end
  end

  class ArrayLiteral < Node
    def to_h
      value.map(&:to_h)
    end

    def from_schema
      ArrayLiteral.new(value.map(&:from_schema), position)
    end

    def to_schema
      # Maybe we should create ArraySchema?
      ArrayLiteral.new(value.map(&:to_schema), position)
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

    def captures
      list = []
      @value.each do |val|
        list.concat val.captures
      end
      list
    end

    def push!(val)
      @value.push val
    end
  end

  class ObjectLiteral < Node
    attr_reader :splats

    def to_h
      { value: value.map { |k, v| [k.to_h, v.to_h] }, splats: splats.to_h }
    end

    def initialize(value, spreads, position)
      @value = value
      @splats = spreads
      @position = position
    end

    def collection?
      true
    end

    def insert!(key, v)
      @value.push [key, v]
    end

    def to_schema
      ObjectLiteral.new(value.map do |key, value|
        [key, value.to_schema]
      end, splats, position)
    end

    def captures
      list = []
      @value.each do |key, val|
        list.concat val.captures
      end
      list
    end

    def each(&block)
      @value.each { |k, v| block.call(k, v) }
    end

    def lookup_key(_key)
      _, value = @value.find { |key, _| key.value == _key }
      value
    end

    def does_not_have_key?(_key)
      @value.none? do |key, value|
        key.value == _key
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

    def to_return
      self
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

    def has_return?
      (self.pass + self.fail)
        .any? { |node| node.is_a? AST::Return }
    end
  end

  class FnCall < Node
    attr_reader :args, :expr

    def to_h
      { args: args.map(&:to_h), expr: expr.to_h }
    end

    def initialize(args, expr, position)
      assert { args.is_a? Array }
      @args = args
      @expr = expr
      @position = position
    end

    def as_op
      OpCall.new(args, expr, position)
    end
  end

  class OpCall < FnCall
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

  class ShortFn < Fn
  end

  class ArrowFn < Fn
  end

  class IdLookup < Node
    def initialize(value, position)
      @value = value
      @position = position
    end

    def to_schema
      SchemaCapture.new(value, position)
    end

    def to_schema_capture_depending_on(context)
      if context.in_a?(:schema) && !schema_lookup?
        to_schema
      else
        self
      end
    end

    def captures
      []
    end

    def schema_lookup?
      return false if value[0] == "_"
      value[0].upcase == value[0]
    end
  end

  class ArgsSchema < Node
    attr_reader :args

    def to_h
      { args: args }
    end

    def from_schema
      self
    end

    def initialize(args)
      @args = args
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

  class SchemaCapture < Node
    attr_reader :name

    def to_h
      { name: name }
    end

    def to_schema
      self
    end

    def from_schema
      IdLookup.new(name, position)
    end

    def initialize(name, position)
      @name = name
      @position = position
    end

    def captures
      [name]
    end
  end

  class Import < Node
    attr_reader :pattern, :file_name

    def to_h
      { pattern: pattern.to_h, file_name: file_name }
    end

    def initialize(pattern, file_name, position)
      @pattern = pattern
      @file_name = file_name
      @position = position
    end
  end

  class Export < Node
    attr_reader :expr

    def to_h
      { expr: expr.to_h, file_name: file_name }
    end

    def initialize(expr, position)
      @expr = expr
      @position = position
    end
  end

  class Op < Node
    attr_reader :lhs, :rhs

    def to_h
      { lhs: lhs.to_h, rhs: rhs.to_h }
    end

    def initialize(lhs, rhs, position)
      @lhs = lhs
      @rhs = rhs
      @position = position
    end
  end

  class Add < Op
  end

  class Minus < Op
  end

  class Multiply < Op
  end

  class Divide < Op
  end

  class AndAnd < Op
  end

  class OrOr < Op
  end

  class EqEq < Op
  end

  class NotEq < Op
  end

  class Gt < Op
  end

  class Lt < Op
  end

  class GtEq < Op
  end

  class LtEq < Op
  end

  class CombineSchemas < Op
  end

  class EitherSchemas < Op
  end

  class In < Op
  end

  class MatchAssignment < Node
    attr_reader :schema, :pattern, :value

    def to_h
      { schema: schema.to_h, pattern: pattern.to_h, value: value.to_h }
    end

    def initialize(schema, pattern, value)
      @schema = schema
      @pattern = pattern
      @value = value
      @position = schema.position
    end

    def captures
      pattern.to_schema.captures
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

  class CustomTag < Node
    attr_reader :name, :attributes, :children

    def to_h
      { name: name, attributes: attributes.to_h, children: children.to_h }
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
