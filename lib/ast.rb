require "pry"

module AST
  class Node
    attr_reader :value, :pos

    def to_h
      hash = {
        "klass" => self.class.to_s,
      }
      instance_variables.each do |var|
        node = instance_variable_get(var)
        value = if node.is_a? Node
            node.to_h
          elsif node.is_a? Array
            node.map(&:to_h)
          else
            node
          end
        hash[var.to_s.delete("@")] = value
      end
      hash
    end

    def is_not_one_of?(*klasses)
      klasses.none? { |klass| self.is_a? klass }
    end

    def is_not_a?(klass)
      !is_a?(klass)
    end

    def pos=(val)
      @pos = val
    end

    def sub_symbols
      sym
        .sub("?", "_q")
        .sub("!", "_b")
    end
  end

  class Int < Node
    def self.from_token(token)
      Int.new(token.value, token.pos)
    end

    def initialize(value, pos)
      @value = value
      @pos = pos
    end
  end

  class Float < Node
    def self.from_token(token)
      Float.new(token.value, token.pos)
    end

    def initialize(value, pos)
      @value = value
      @pos = pos
    end
  end

  class Bool < Node
    def initialize(value, pos)
      @value = value
      @pos = pos
    end
  end

  class SimpleFnArgs < Node
    def to_h
      value
    end

    def initialize(value, pos)
      @value = value
      @pos = pos
    end
  end

  class Str < Node
    def initialize(value, pos)
      @value = value
      @pos = pos
    end

    def alpha_numeric?
      !!(value =~ /^[a-zA-Z_]+$/)
    end

    def captures
      []
    end
  end

  class SimpleString < Node
    def initialize(value, pos)
      @value = value
      @pos = pos
    end
  end

  class ArrayLiteral < Node
    def from_schema
      ArrayLiteral.new(value.map(&:from_schema), pos)
    end

    def to_schema
      # Maybe we should create ArraySchema?
      ArrayLiteral.new(value.map(&:to_schema), pos)
    end

    def initialize(value = [], pos = nil)
      assert { value.is_a? Array }
      @value = value
      @pos = pos
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

  class SimpleObjectLiteral < Node
    def initialize(value, pos)
      @value = value
      @pos = pos
    end

    def to_h
      value.map do |key, value|
        [key, value.to_h]
      end
    end
  end

  class ObjectLiteral < Node
    attr_reader :splats

    def initialize(value, spreads, pos)
      @value = value
      @splats = spreads
      @pos = pos
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
      end, splats, pos)
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

  class Return < Node
    def initialize(value, pos = value.pos)
      @value = value
      @pos = pos
    end

    def to_return
      self
    end
  end

  class If < Node
    attr_reader :pass, :fail, :value
    attr_writer :pass, :fail

    def initialize(value, pass, _fail, pos)
      @value = value
      @pass = pass
      @fail = _fail
      @pos = pos
    end

    def has_return?
      (self.pass + self.fail)
        .any? { |node| node.is_a? AST::Return }
    end
  end

  class FnCall < Node
    attr_reader :args, :expr

    def initialize(args, expr_n, pos)
      assert { args.is_a? Array }
      @args = args
      @expr = expr_n
      @pos = pos
    end

    def as_op
      OpCall.new(args, expr, pos)
    end
  end

  class OpCall < FnCall
  end

  class Fn < Node
    attr_reader :args, :body

    def initialize(args, body, pos)
      @args = args
      @body = body
      @pos = pos
    end

    def declare_with(name, schema)
      Declare.new(name, schema, self, pos)
    end
  end

  class SingleLineFnWithNoArgs < Node
    attr_reader :return_value, :name

    def initialize(name, return_value, pos)
      @name = name
      @return_value = return_value
      @pos = pos
    end
  end

  class SingleLineFnWithArgs < Node
    attr_reader :return_value, :name, :args

    def initialize(name, args, return_value, pos)
      @name = name
      @args = args
      @return_value = return_value
      @pos = pos
    end
  end

  class ShortFn < Fn
  end

  class ArrowFn < Fn
  end

  class IdLookup < Node
    def initialize(value, pos)
      @value = value
      @pos = pos
    end

    def to_schema
      SchemaCapture.new(value, pos)
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

    def from_schema
      self
    end

    def initialize(args)
      @args = args
    end
  end

  class Declare < Node
    attr_reader :name, :schema, :expr

    def initialize(name, schema, expr_n, pos)
      @name = name
      @schema = schema
      @expr = expr_n
      @pos = pos
    end

    def exportable?
      true
    end
  end

  class SchemaCapture < Node
    attr_reader :name

    def to_schema
      self
    end

    def from_schema
      IdLookup.new(name, pos)
    end

    def initialize(name, pos)
      @name = name
      @pos = pos
    end

    def captures
      [name]
    end
  end

  class Import < Node
    attr_reader :pattern, :file_name

    def initialize(pattern, file_name, pos)
      @pattern = pattern
      @file_name = file_name
      @pos = pos
    end
  end

  class Export < Node
    attr_reader :expr

    def initialize(expr_n, pos)
      @expr = expr_n
      @pos = pos
    end
  end

  class Op < Node
    attr_reader :lhs, :type, :rhs

    def initialize(lhs, type, rhs, pos)
      @lhs = lhs
      @type = type
      @rhs = rhs
      @pos = pos
    end
  end

  class MatchAssignment < Node
    attr_reader :schema, :pattern, :value

    def initialize(schema, pattern, value)
      @schema = schema
      @pattern = pattern
      @value = value
      @pos = schema.pos
    end

    def captures
      pattern.to_schema.captures
    end
  end

  class Assign < Node
    attr_reader :name, :expr

    def initialize(name, expr_n, pos = expr_n.pos)
      @name = name
      @expr = expr_n
      @pos = pos || expr_n.pos
    end

    def exportable?
      true
    end
  end

  class SimpleAssignment < Assign
    attr_reader :name, :expr

    def initialize(name, expr_n, pos = expr_n.pos)
      @name = name
      @expr = expr_n
      @pos = pos || expr_n.pos
    end

    def exportable?
      true
    end
  end

  class PropertyLookup < Node
    attr_reader :lhs_expr, :property

    def initialize(lhs_expr, property, pos)
      @lhs_expr = lhs_expr
      @property = property
      @pos = pos
    end

    def lookup?
      true
    end
  end

  class Throw < Node
    attr_reader :expr

    def initialize(expr_n, pos)
      @expr = expr_n
      @pos = pos
    end
  end

  class Case < Node
    attr_reader :expr, :cases

    def initialize(expr_n, cases, pos)
      @expr = expr_n
      @cases = cases
      @pos = pos
    end
  end
end
