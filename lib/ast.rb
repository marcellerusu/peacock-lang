require "pry"

module AST
  class Node
    attr_reader :value, :pos

    def initialize(value, pos)
      @value = value
      @pos = pos
    end

    def to_h
      hash = {
        "klass" => self.class.to_s,
      }
      instance_variables.each do |var|
        node = instance_variable_get(var)
        value = if node.is_a? Node
            node.to_h
          elsif node.is_a?(Array) && node.all? { |n| n.is_a?(Node) }
            node.map(&:to_h)
          else
            node
          end
        hash[var.to_s.delete("@")] = value
      end
      hash
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

    def captures
      []
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

  class SimpleArg < Node
    attr_reader :name

    def initialize(name, pos)
      @name = name
      @pos = pos
    end
  end

  class SimpleSchemaArg < Node
    attr_reader :schema_name, :name

    def initialize(schema_name, name, pos)
      @schema_name = schema_name
      @name = name
      @pos = pos
    end
  end

  class SimpleFnArgs < Node
  end

  class SimpleString < Node
  end

  class ArrayLiteral < Node
    def captures
      list = []
      @value.each do |val|
        list.concat val.captures
      end
      list
    end
  end

  class ObjectLiteral < Node
  end

  class ObjectEntry < Node
    attr_reader :key_name

    def initialize(key_name, value, pos)
      @key_name = key_name
      @value = value
      @pos = pos
    end
  end

  class SimpleObjectEntry < ObjectEntry
  end

  class ArrowMethodObjectEntry < ObjectEntry
  end

  class FunctionObjectEntry < ObjectEntry
  end

  class SpreadObjectEntry < Node
  end

  class SchemaAny < Node
    def initialize(pos)
      @pos = pos
    end
  end

  class SchemaDefinition < Node
    attr_reader :name, :schema_expr

    def initialize(name, schema_expr, pos)
      @name = name
      @schema_expr = schema_expr
      @pos = pos
    end
  end

  class SchemaObjectLiteral < Node
    attr_reader :properties

    def to_h
      props = []
      for key, value in properties
        props.push [key, value.to_h]
      end
      props
    end

    def initialize(properties, pos)
      @properties = properties
      @pos = pos
    end
  end

  class Return < Node
    def initialize(value, pos = value.pos)
      @value = value
      @pos = pos
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

    def initialize(args, return_expr_n, pos)
      assert { args.is_a? Array }
      @args = args
      @expr = return_expr_n
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

  class SingleLineDefWithArgs < Node
    attr_reader :return_value, :name, :args

    def initialize(name, args, return_value, pos)
      @name = name
      @args = args
      @return_value = return_value
      @pos = pos
    end
  end

  class MultilineDefWithoutArgs < Node
    attr_reader :body, :name

    def initialize(name, body, pos)
      @name = name
      @body = body
      @pos = pos
    end
  end

  class MultilineDefWithArgs < Node
    attr_reader :body, :args, :name

    def initialize(name, args, body, pos)
      @name = name
      @args = args
      @body = body
      @pos = pos
    end
  end

  class ShortFn < Node
    attr_reader :return_expr, :pos

    def initialize(return_expr, pos)
      @return_expr = return_expr
      @pos = pos
    end
  end

  class MultiLineArrowFnWithArgs < Node
    attr_reader :args, :body, :pos

    def initialize(args, body, pos)
      @args = args
      @body = body
      @pos = pos
    end
  end

  class SingleLineArrowFnWithoutArgs < Node
    attr_reader :return_expr, :pos

    def initialize(return_expr, pos)
      @return_expr = return_expr
      @pos = pos
    end
  end

  class SingleLineArrowFnWithArgs < Node
    attr_reader :args, :return_expr, :pos

    def initialize(args, return_expr, pos)
      @args = args
      @return_expr = return_expr
      @pos = pos
    end
  end

  class SingleLineArrowFnWithOneArg < Node
    attr_reader :arg, :return_expr, :pos

    def initialize(arg, return_expr, pos)
      @arg = arg
      @return_expr = return_expr
      @pos = pos
    end
  end

  class AnonIdLookup < Node
    def initialize(pos)
      @pos = pos
    end
  end

  class IdLookup < Node
    def captures
      []
    end
  end

  class ArgsSchema < Node
    attr_reader :args

    def initialize(args)
      @args = args
    end
  end

  class Declare < Node
    attr_reader :name, :schema, :expr

    def initialize(name, schema, return_expr_n, pos)
      @name = name
      @schema = schema
      @expr = return_expr_n
      @pos = pos
    end

    def exportable?
      true
    end
  end

  class SchemaCapture < Node
    attr_reader :name

    def initialize(name, pos)
      @name = name
      @pos = pos
    end

    def captures
      [name]
    end
  end

  class SimpleForOfLoop < Node
    attr_reader :iter_name, :arr_expr, :body

    def initialize(iter_name, arr_expr, body, pos)
      @iter_name = iter_name
      @arr_expr = arr_expr
      @body = body
      @pos = pos
    end
  end

  class ForOfObjDeconstructLoop < Node
    attr_reader :iter_properties, :arr_expr, :body

    def initialize(iter_properties, arr_expr, body, pos)
      @iter_properties = iter_properties
      @arr_expr = arr_expr
      @body = body
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

  class Dot < Op
  end

  class SchemaUnion < Node
    attr_reader :schema_exprs

    def initialize(schema_exprs, pos)
      @schema_exprs = schema_exprs
      @pos = pos
    end
  end

  class SchemaIntersect < Node
    attr_reader :schema_exprs

    def initialize(schema_exprs, pos)
      @schema_exprs = schema_exprs
      @pos = pos
    end
  end

  class Assign < Node
    attr_reader :name, :expr

    def initialize(name, return_expr_n, pos = return_expr_n.pos)
      @name = name
      @expr = return_expr_n
      @pos = pos || return_expr_n.pos
    end

    def exportable?
      true
    end
  end

  class Await < Node
  end

  class SimpleSchemaAssignment < Assign
    attr_reader :schema_name

    def initialize(schema_name, name, expr, pos)
      @schema_name = schema_name
      @name = name
      @expr = expr
      @pos = pos
    end
  end

  class SimpleAssignment < Assign
    attr_reader :name, :expr

    def initialize(name, return_expr_n, pos = return_expr_n.pos)
      @name = name
      @expr = return_expr_n
      @pos = pos || return_expr_n.pos
    end

    def captures
      [name]
    end
  end
end
