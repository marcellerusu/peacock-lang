require "utils"
require "pry"

class Compiler
  # TODO: do something better for tests
  @@use_std_lib = true
  def self.use_std_lib=(other)
    @@use_std_lib = other
  end

  def initialize(ast, indent = 0)
    @ast = ast
    @indent = indent
  end

  def eval
    program = ""
    program += std_lib if first_run?
    program += eval_assignment_declarations
    program += collapse_function_overloading
    @ast.each do |statement|
      program += " " * @indent
      program += eval_expr(statement)
      program += ";" << "\n"
    end
    program.rstrip
  end

  def eval_without_variable_declarations
    program = ""
    program += collapse_function_overloading
    @ast.each do |statement|
      program += " " * @indent
      program += eval_expr(statement)
      program += ";" << "\n"
    end
    program.rstrip
  end

  private

  def first_run?
    # TODO: I don't think this is correct
    @@use_std_lib && @indent == 0
  end

  def std_lib
    code = "const __Symbols = {}\n"
    code += schema_lib
    code += "const Peacock = {\n"
    indent!
    code += padding + "plus: (a, b) => a + b,\n"
    code += padding + "minus: (a, b) => a - b,\n"
    code += padding + "mult: (a, b) => a * b,\n"
    code += padding + "div: (a, b) => a / b,\n"
    code += padding + "gt: (a, b) => a > b,\n"
    code += padding + "ls: (a, b) => a < b,\n"
    code += padding + "gt_eq: (a, b) => a >= b,\n"
    code += padding + "ls_eq: (a, b) => a <= b,\n"
    code += padding + "symbol: symName => __Symbols[symName] || (__Symbols[symName] = Symbol(symName)),\n"
    code += padding + "eq: (a, b) => a === b,\n"
    code += padding + "Schema,\n"
    dedent!
    code += "};\n"
    code += "const print = (...params) => console.log(...params);\n"
  end

  def schema_lib
    <<-EOS
class Schema {
  static for(schema) {
    if (schema instanceof Schema) return schema;
    if (schema instanceof Array) return new ArraySchema(schema);
    if (schema instanceof Function) return new FnSchema(schema);
    if (schema === undefined) return new AnySchema();
    // TODO: this should be more specific
    if (typeof schema === "object") return new RecordSchema(schema);
    const literals = ["boolean", "number", "string", "symbol"];
    if (literals.includes(typeof schema)) return new LiteralSchema(schema);
  }

  static or(...schema) {
    return new OrSchema(...schema);
  }

  static and(a, b) {
    [a, b] = [Schema.for(a), Schema.for(b)];
    if (a instanceof RecordSchema && b instanceof RecordSchema) {
      return a.combine(b);
    }
    return new AndSchema(a, b);
  }

  static any() {
    return new AnySchema();
  }

  constructor(schema) {
    this.schema = schema;
  }

  valid(other) {
    throw null;
  }
}

class OrSchema extends Schema {
  constructor(...schema) {
    super(schema.map(Schema.for));
  }
  valid(other) {
    return this.schema.some((s) => s.valid(other));
  }
}

class AndSchema extends Schema {
  constructor(...schema) {
    super(schema.map(Schema.for));
  }
  valid(other) {
    return this.schema.every((s) => s.valid(other));
  }
}

class RecordSchema extends Schema {
  constructor(schema) {
    super(Object.entries(schema).map(([k, v]) => [k, Schema.for(v)]));
  }

  combine(other) {
    let newSchema = Object.fromEntries(this.schema);
    for (let [k, v] of other.schema) {
      newSchema[k] = v;
    }
    return new RecordSchema(newSchema);
  }

  valid(other) {
    return this.schema.every(
      ([k, v]) => typeof other[k] !== "undefined" && v.valid(other[k])
    );
  }
}

class ArraySchema extends Schema {
  valid(other) {
    if (!(other instanceof Array)) return false;
    return other.length === this.schema.length;
  }
}

class FnSchema extends Schema {
  valid(other) {
    return this.schema(other);
  }
}

class AnySchema extends Schema {
  valid(other) {
    return true;
  }
}

class LiteralSchema extends Schema {
  valid(other) {
    return this.schema === other;
  }
}
    EOS
  end

  def indent!
    @indent += 2
  end

  def dedent!
    @indent -= 2
  end

  def padding(by = 0)
    assert { @indent + by >= 0 }
    " " * (@indent + by)
  end

  def collapse_function_overloading
    functions = @ast
      .filter { |node| node[:node_type] == :declare }
      .group_by { |node| node[:sym] }
      .filter { |group| group.length > 1 }

    # binding.pry
    function = ""
    functions.each do |sym, function_group|
      indent!
      function += "const " + sym + " = "
      function += "(...params)" + " => "
      function += "{" << "\n" + padding
      function += "const functions = ["
      function += function_group.map { |f| eval_function(f[:expr]) }.join(", ")
      function += "];" << "\n" + padding
      function += "const f_by_length = functions.find(f => f.length === params.length);\n" << padding
      function += "if (f_by_length) return f_by_length(...params);\n"
      # TODO: function by shape -- schemas will take care of this
      # function << "const f_by_shape = functions.find(([_, shape]) => shape_eq(shape_of(params), shape));\n" << padding
      # function << "assert("
      function += "};\n"
      dedent!
      @ast = @ast.filter { |node| node[:sym] != sym }
    end
    function
  end

  def eval_assignment_declarations
    nodes = find_assignments
    if nodes.any?
      vars = padding
      vars += "let "
      vars += nodes.map { |node| node[:sym] }.join(", ")
      vars += ";" << "\n"
    end
    vars || ""
  end

  def find_assignments
    @ast
      .flat_map { |node|
      if node[:node_type] == :if
        node[:pass] + node[:fail]
      else
        [node]
      end
    }
      .filter { |node| node[:node_type] == :assign }
      .uniq { |node| node[:sym] }
  end

  def eval_expr(node)
    case node[:node_type]
    when :declare
      eval_declaration node
    when :assign
      eval_assignment node
    when :property_lookup
      eval_property_lookup node
    when :array_lit
      eval_array node
    when :record_lit
      eval_record node
    when :bool_lit
      eval_bool node
    when :int_lit
      eval_int node
    when :float_lit
      eval_float node
    when :str_lit
      eval_str node
    when :function
      eval_function node
    when :return
      eval_return node
    when :function_call
      eval_function_call node
    when :identifier_lookup
      eval_identifier_lookup node
    when :if
      eval_if_expression node
    when :symbol
      eval_symbol node
    when :throw
      eval_throw node
    else
      puts "no case matched node_type: #{node[:node_type]}"
      assert { false }
    end
  end

  def eval_if_expression(node)
    cond = eval_expr(node[:expr])
    pass_body = Compiler.new(node[:pass], @indent + 2).eval_without_variable_declarations
    fail_body = Compiler.new(node[:fail], @indent + 2).eval_without_variable_declarations

    "#{padding}if (#{cond}) {\n" \
    "#{pass_body}\n" \
    "#{padding}} else {\n" \
    "#{fail_body}\n" \
    "#{padding}}"
  end

  def eval_throw(node)
    "throw #{eval_expr(node[:expr])}"
  end

  def eval_symbol(node)
    "Peacock.symbol('#{node[:value]}')"
  end

  def eval_str(node)
    "\"#{node[:value]}\""
  end

  def eval_int(node)
    "#{node[:value]}"
  end

  def eval_float(node)
    "#{node[:value]}"
  end

  def eval_bool(node)
    "#{node[:value]}"
  end

  def eval_array(node)
    elements = node[:value].map { |n| eval_expr n }.join(", ")
    "[#{elements}]"
  end

  def eval_record(node)
    indent!
    record = "{\n"
    record += node[:value].map do |key, value|
      "#{padding}\"#{key}\": #{eval_expr(value)}"
    end.join(",\n")
    dedent!
    record += "\n#{padding}}"
  end

  def eval_property_lookup(node)
    lhs, key = eval_expr(node[:lhs_expr]), eval_expr(node[:property])
    "#{lhs}[#{key}]"
  end

  def eval_declaration(node)
    "const #{node[:sym]} = #{eval_expr(node[:expr])}"
  end

  def eval_assignment(node)
    "#{node[:sym]} = #{eval_expr(node[:expr])}"
  end

  def eval_function(node)
    body = Compiler.new(node[:body], @indent + 2).eval
    args = node[:args].map { |arg| arg[:sym] }.join(", ")
    "(#{args}) => {\n#{body}\n#{padding}}"
  end

  def eval_return(node)
    "return #{eval_expr node[:expr]}"
  end

  def eval_function_call(node)
    args = node[:args].map { |arg| eval_expr arg }.join ", "
    fn = eval_expr node[:expr]
    "#{fn}(#{args})"
  end

  def eval_identifier_lookup(node)
    node[:sym]
  end
end
