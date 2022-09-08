require "pry"

module AST
  class Node
    attr_reader :value, :start_pos, :end_pos

    def initialize(value, start_pos, end_pos)
      @value = value
      @start_pos = start_pos
      @end_pos = end_pos
    end

    def declare?
      false
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

    def is_not_one_of?(*klasses)
      !klasses.any? { |klass| is_a? klass }
    end

    def is_not_a?(klass)
      !is_a?(klass)
    end

    def start_pos=(val)
      @start_pos = val
    end

    def end_pos=(val)
      @end_pos = val
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
    def initialize(value, start_pos, end_pos)
      @value = value
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Float < Node
    def initialize(value, start_pos, end_pos)
      @value = value
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Bool < Node
    def initialize(value, start_pos, end_pos)
      @value = value
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SimpleArg < Node
    attr_reader :name

    def initialize(name, start_pos, end_pos)
      @name = name
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class ThisSchemaArg < Node
    attr_reader :schema

    def initialize(schema, start_pos, end_pos)
      @schema = schema
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SimpleSchemaArg < Node
    attr_reader :schema_name, :name

    def initialize(schema_name, name, start_pos, end_pos)
      @schema_name = schema_name
      @name = name
      @start_pos = start_pos
      @end_pos = end_pos
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

    def initialize(key_name, value, start_pos, end_pos)
      @key_name = key_name
      @value = value
      @start_pos = start_pos
      @end_pos = end_pos
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

  class Not < Node
    attr_reader :expr

    def initialize(expr, start_pos, end_pos)
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SchemaDefinition < Node
    attr_reader :name, :schema_expr

    def initialize(name, schema_expr, start_pos, end_pos)
      @name = name
      @schema_expr = schema_expr
      @start_pos = start_pos
      @end_pos = end_pos
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

    def initialize(properties, start_pos, end_pos)
      @properties = properties
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class New < Node
    attr_reader :class_expr, :args

    def initialize(class_expr, args, start_pos, end_pos)
      @class_expr = class_expr
      @args = args
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class CaseFnPattern < Node
    attr_reader :this_pattern, :patterns, :body

    def initialize(this_pattern, patterns, body, start_pos, end_pos)
      @this_pattern = this_pattern
      @patterns = patterns
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class ArrayComprehension < Node
    attr_reader :expr, :variable, :array_expr, :if_expr

    def initialize(expr, variable, array_expr, if_expr, start_pos, end_pos)
      @expr = expr
      @variable = variable
      @array_expr = array_expr
      @if_expr = if_expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SingleLineBindFunctionDefinition < Node
    attr_reader :object_name, :function_name, :args, :return_expr

    def initialize(object_name, function_name, args, return_expr, start_pos, end_pos)
      @object_name = object_name
      @function_name = function_name
      @args = args
      @return_expr = return_expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class DefaultAssignment < Node
    attr_reader :lhs, :expr

    def initialize(lhs, expr, start_pos, end_pos)
      @lhs = lhs
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class PlusAssignment < Node
    attr_reader :lhs, :expr

    def initialize(lhs, expr, start_pos, end_pos)
      @lhs = lhs
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SimpleWhen < Node
    attr_reader :expr, :body

    def initialize(expr, body, start_pos, end_pos)
      @expr = expr
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class CaseElse < Node
    attr_reader :body

    def initialize(body, start_pos, end_pos)
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class EmptyCaseExpr < Node
    attr_reader :cases

    def initialize(cases, start_pos, end_pos)
      @cases = cases
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class MultiLineBindFunctionDefinition < Node
    attr_reader :object_name, :function_name, :args, :body

    def initialize(object_name, function_name, args, body, start_pos, end_pos)
      @object_name = object_name
      @function_name = function_name
      @args = args
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class CaseFunctionDefinition < Node
    attr_reader :name, :patterns

    def initialize(name, patterns, start_pos, end_pos)
      @name = name
      @patterns = patterns
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class InstanceProperty < Node
    attr_reader :name, :expr

    def initialize(name, expr, start_pos, end_pos)
      @name = name
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SpreadExpr < Node
  end

  class OneLineGetter < Node
    attr_reader :name, :expr

    def initialize(name, expr, start_pos, end_pos)
      @name = name
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class DynamicLookup < Node
    attr_reader :lhs, :expr

    def initialize(lhs, expr, start_pos, end_pos)
      @lhs = lhs
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Return < Node
    def initialize(value, start_pos, end_pos)
      @value = value
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class If < Node
    attr_reader :cond, :pass, :branches

    def initialize(cond, pass, branches, start_pos, end_pos)
      @cond = cond
      @pass = pass
      @branches = branches
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class ElseIf < Node
    attr_reader :cond, :body

    def initialize(cond, body, start_pos, end_pos)
      @cond = cond
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Else < Node
    attr_reader :body

    def initialize(body, start_pos, end_pos)
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class FnCall < Node
    attr_reader :args, :expr

    def initialize(args, return_expr_n, start_pos, end_pos)
      assert { args.is_a? Array }
      @args = args
      @expr = return_expr_n
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SingleLineDefWithArgs < Node
    attr_reader :return_value, :name, :args

    def initialize(name, args, return_value, start_pos, end_pos)
      @name = name
      @args = args
      @return_value = return_value
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SingleLineDefWithoutArgs < Node
    attr_reader :return_value, :name

    def initialize(name, return_value, start_pos, end_pos)
      @name = name
      @return_value = return_value
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Null < Node
    def initialize(start_pos, end_pos)
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class NullSchema < Node
    def initialize(start_pos, end_pos)
      @start_pos = start_pos
      @end_pos = end_pos
    end

    def name
      nil
    end
  end

  class MultilineDefWithoutArgs < Node
    attr_reader :body, :name

    def initialize(name, body, start_pos, end_pos)
      @name = name
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class ConstructorWithoutArgs < MultilineDefWithoutArgs
  end

  class ShortHandConstructor < Node
    attr_reader :args

    def initialize(args, start_pos, end_pos)
      @args = args
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SimpleConstructorArg < Node
    attr_reader :name

    def initialize(name, start_pos, end_pos)
      @name = name
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class DefaultConstructorArg < Node
    attr_reader :name, :expr

    def initialize(name, expr, start_pos, end_pos)
      @name = name
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class MultilineDefWithArgs < Node
    attr_reader :body, :args, :name

    def initialize(name, args, body, start_pos, end_pos)
      @name = name
      @args = args
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class StaticMethod < MultilineDefWithArgs
  end

  class ConstructorWithArgs < MultilineDefWithArgs
  end

  class ShortFnWithArgs < Node
    attr_reader :return_expr, :args

    def initialize(args, return_expr, start_pos, end_pos)
      @args = args
      @return_expr = return_expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class ShortFn < Node
    attr_reader :return_expr

    def initialize(return_expr, start_pos, end_pos)
      @return_expr = return_expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class MultiLineArrowFnWithArgs < Node
    attr_reader :args, :body

    def initialize(args, body, start_pos, end_pos)
      @args = args
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class This < Node
  end

  class Bind < Node
    attr_reader :lhs, :function, :args

    def initialize(lhs, function, args)
      @lhs = lhs
      @function = function
      @args = args
    end
  end

  class OptionalChain < Node
    attr_reader :lhs, :property

    def initialize(lhs, property, start_pos, end_pos)
      @lhs = lhs
      @property = property
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class DotAssignment < Node
    attr_reader :lhs, :expr

    def initialize(lhs, expr, start_pos, end_pos)
      @lhs = lhs
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Class < Node
    attr_reader :name, :parent_class, :entries

    def initialize(name, parent_class, entries, start_pos, end_pos)
      @name = name
      @parent_class = parent_class
      @entries = entries
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SingleLineArrowFnWithoutArgs < Node
    attr_reader :return_expr

    def initialize(return_expr, start_pos, end_pos)
      @return_expr = return_expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class EscapedElementExpr < Node
  end

  class SimpleElement < Node
    attr_reader :name, :children

    def initialize(name, children, start_pos, end_pos)
      @name = name
      @children = children
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class BodyComponentWithoutAttrs < Node
    attr_reader :name, :constructor_body, :expr

    def initialize(name, constructor_body, expr, start_pos, end_pos)
      @name = name
      @constructor_body = constructor_body
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class ExprComponentWithAttributes < Node
    attr_reader :name, :attributes, :expr

    def initialize(name, attributes, expr, start_pos, end_pos)
      @name = name
      @attributes = attributes
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class ExprComponent < Node
    attr_reader :name, :expr

    def initialize(name, expr, start_pos, end_pos)
      @name = name
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SingleLineArrowFnWithArgs < Node
    attr_reader :args, :return_expr

    def initialize(args, return_expr, start_pos, end_pos)
      @args = args
      @return_expr = return_expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class SingleLineArrowFnWithOneArg < Node
    attr_reader :arg, :return_expr

    def initialize(arg, return_expr, start_pos, end_pos)
      @arg = arg
      @return_expr = return_expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class AnonIdLookup < Node
    def initialize(start_pos, end_pos)
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class IdLookup < Node
    def captures
      []
    end
  end

  class SchemaCapture < Node
    attr_reader :name

    def initialize(name, start_pos, end_pos)
      @name = name
      @start_pos = start_pos
      @end_pos = end_pos
    end

    def captures
      [name]
    end
  end

  class SimpleForOfLoop < Node
    attr_reader :iter_name, :arr_expr, :body

    def initialize(iter_name, arr_expr, body, start_pos, end_pos)
      @iter_name = iter_name
      @arr_expr = arr_expr
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class ForOfObjDeconstructLoop < Node
    attr_reader :iter_properties, :arr_expr, :body

    def initialize(iter_properties, arr_expr, body, start_pos, end_pos)
      @iter_properties = iter_properties
      @arr_expr = arr_expr
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Op < Node
    attr_reader :lhs, :type, :rhs

    def initialize(lhs, type, rhs, start_pos, end_pos)
      @lhs = lhs
      @type = type
      @rhs = rhs
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Range < Node
    attr_reader :lhs, :rhs

    def initialize(lhs, rhs, start_pos, end_pos)
      @lhs = lhs
      @rhs = rhs
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Dot < Op
  end

  class SchemaUnion < Node
    attr_reader :schema_exprs

    def initialize(schema_exprs, start_pos, end_pos)
      @schema_exprs = schema_exprs
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Empty < Node
    def initialize
    end
  end

  class SchemaIntersect < Node
    attr_reader :schema_exprs

    def initialize(schema_exprs, start_pos, end_pos)
      @schema_exprs = schema_exprs
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class Assign < Node
    attr_reader :name, :expr

    def initialize(name, return_expr_n, start_pos, end_pos)
      @name = name
      @expr = return_expr_n
      @start_pos = start_pos
      @end_pos = end_pos
    end

    def declare?
      true
    end
  end

  class Await < Node
  end

  # Schema(a) := b
  class SimpleSchemaAssignment < Assign
    attr_reader :schema_name

    def initialize(schema_name, name, expr, start_pos, end_pos)
      @schema_name = schema_name
      @name = name
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  # a := 1
  class SimpleAssignment < Assign
    attr_reader :name, :expr

    def initialize(name, return_expr_n, start_pos, end_pos)
      @name = name
      @expr = return_expr_n
      @start_pos = start_pos
      @end_pos = end_pos
    end

    def captures
      [name]
    end
  end

  # a = 1
  class SimpleReassignment < Node
    attr_reader :name, :expr

    def initialize(name, return_expr_n, start_pos, end_pos)
      @name = name
      @expr = return_expr_n
      @start_pos = start_pos
      @end_pos = end_pos
    end

    def declare?
      false
    end

    def captures
      [name]
    end
  end

  # a :=
  class ImcompleteSimpleAssignment < Assign
    attr_reader :name

    def initialize(name, start_pos, end_pos)
      @name = name
      @start_pos = start_pos
      @end_pos = end_pos
    end

    def captures
      [name]
    end
  end

  class SimpleForInLoop < Node
    attr_reader :variable, :object_expr, :body

    def initialize(variable, object_expr, body, start_pos, end_pos)
      @variable = variable
      @object_expr = object_expr
      @body = body
      @start_pos = start_pos
      @end_pos = end_pos
    end
  end

  class ArrayAssignment < Node
    attr_reader :variables, :expr

    def initialize(variables, expr, start_pos, end_pos)
      @variables = variables
      @expr = expr
      @start_pos = start_pos
      @end_pos = end_pos
    end

    def captures
      @variables
    end
  end
end
