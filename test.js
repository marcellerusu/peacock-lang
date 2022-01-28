const __Symbols = {}
class MatchError extends Error {}

const allEntries = (obj) =>
  Reflect.ownKeys(obj).map((k) => [Sym.new(k), obj[k]]);

class Schema {
  nil_q() {
    return new Bool(false);
  }
  static for(schema) {
    if (schema instanceof Schema) return schema;
    if (schema instanceof List) return new ListSchema(schema);
    if (schema instanceof Array) return new ListSchema(schema);
    if (schema instanceof Function) return new FnSchema(schema);
    if (schema instanceof Record) return new RecordSchema(schema);
    if (schema === undefined) return new AnySchema();
    // TODO: this should be more specific, why?
    const literals = [Bool, Int, Float, Str, Sym];
    if (literals.includes(schema.constructor)) return new LiteralSchema(schema);
    if (typeof schema === "object") return new RecordSchema(schema);
  }

  static case(value, cases) {
    const fn = cases.first((list) => {
      const schema = list.__lookup__(new Int(0));
      const fn = list.__lookup__(new Int(1));
      if (schema.valid_q(value).to_js()) {
        return fn;
      }
    });
    if (!fn) throw new MatchError();
    return fn(value);
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

  static any(name) {
    return new AnySchema(name.to_js());
  }

  static literal(value) {
    return new LiteralSchema(value);
  }

  constructor(schema) {
    this.schema_ = schema;
  }

  valid_q(other) {
    throw null;
  }

  valid_b(other) {
    if (!this.valid_q(other).to_js()) {
      throw new MatchError();
    }
    return other;
  }
}

class OrSchema extends Schema {
  constructor(...schema) {
    super(schema.map(Schema.for));
  }
  valid_q(other) {
    return Bool.new(this.schema_.some((s) => s.valid_q(other).to_js()));
  }
}

class AndSchema extends Schema {
  constructor(...schema) {
    super(schema.map(Schema.for));
  }
  valid_q(other) {
    return Bool.new(this.schema_.every((s) => s.valid_q(other).to_js()));
  }
}

class RecordSchema extends Schema {
  constructor(schema) {
    schema = schema.map((k, v) => {
      return List.new([k, Schema.for(v)]);
    });
    super(schema);
  }

  combine(other) {
    if (!(other instanceof RecordSchema)) throw new NotReached();
    let newSchema = this.schema_.combine(other.schema_);
    return new RecordSchema(newSchema);
  }

  valid_q(other) {
    return this.schema_.every((k, v) =>
      Bool.new(other.has_q(k).to_js() && v.valid_q(other.__lookup__(k)).to_js())
    );
  }
}

class ListSchema extends Schema {
  constructor(value) {
    if (value instanceof Array) {
      value = List.new(value);
    }
    value = value.map(Schema.for);
    super(value);
  }
  valid_q(other) {
    if (!(other instanceof List)) return new Bool(false);
    const otherSize = other.size().to_js();
    return new Bool(
      otherSize === this.schema_.size().to_js() &&
        this.schema_.every((s, i) => s.valid_q(other.__lookup__(i))).to_js()
    );
  }
  // _find_bound_variables(paths = []) {
  //   // for (let )
  // }
  // _eval_path_on(path, list) {
  //   let value = list;
  //   for (let key of path) {
  //     value = value.__lookup__(key);
  //   }
  //   return value;
  // }
}

class FnSchema extends Schema {
  valid_q(other) {
    return this.schema_(other);
  }
}

class AnySchema extends Schema {
  valid_q(other) {
    return Bool.new(true);
  }
}

class LiteralSchema extends Schema {
  valid_q(other) {
    return this.schema_.__eq__(other);
  }
}

module.exports = { Schema };
class NotReached extends Error {
  constructor(...artifacts) {
    console.log(...artifacts);
    super();
  }
}

class StringScanner {
  index = 0;
  matched = null;
  groups = [];
  constructor(str) {
    this.str = str;
  }

  scan(regex) {
    const result = this.rest_of_str().match(regex);
    if (result === null || result.index !== 0) return false;
    const [matched, ...groups] = Array.from(result);
    this.index += matched.length;
    this.matched = matched;
    this.groups = groups;
    return true;
  }

  rest_of_str() {
    return this.str.slice(this.index);
  }

  is_end_of_str() {
    return this.index >= this.str.length;
  }
}

class Token {
  constructor(value) {
    this.value = value;
  }
  is(TokenType) {
    return this instanceof TokenType;
  }
}
class ValueToken extends Token {}
class IdentifierToken extends Token {}
class OpenBrace extends Token {}
class CloseBrace extends Token {}
class Ampersand extends Token {}
class PseudoClass extends Token {}
class Dot extends Token {}

const tokenize = (str) => {
  const tokens = [];
  const scanner = new StringScanner(str);
  while (!scanner.is_end_of_str()) {
    if (scanner.scan(/\s+/)) {
      continue;
    } else if (scanner.scan(/&/)) {
      tokens.push(new Ampersand());
    } else if (scanner.scan(/\./)) {
      tokens.push(new Dot());
    } else if (scanner.scan(/:([a-z]+)/)) {
      tokens.push(new PseudoClass(scanner.groups[0]));
    } else if (scanner.scan(/:(\s)*(.*);/)) {
      tokens.push(new ValueToken(scanner.groups[1]));
    } else if (scanner.scan(/([a-z][a-z1-9\-]*|\*)/)) {
      tokens.push(new IdentifierToken(scanner.matched));
    } else if (scanner.scan(/\{/)) {
      tokens.push(new OpenBrace());
    } else if (scanner.scan(/\}/)) {
      tokens.push(new CloseBrace());
    } else {
      throw new NotReached([scanner.index, scanner.rest_of_str()]);
    }
  }
  return tokens;
};

class TokenMismatch extends Error {
  constructor(expected, got) {
    super(`expected - ${expected.name}, got - ${got.constructor.name}`);
  }
}

class AstNode {}
class RuleNode extends AstNode {
  constructor(name, value) {
    super();
    this.name = name;
    this.value = value;
  }
}
class ChildSelectorNode extends AstNode {
  constructor(tag_name, rules) {
    super();
    this.tag_name = tag_name;
    this.rules = rules;
  }
}

class PseudoSelectorNode extends AstNode {
  constructor(selector, rules) {
    super();
    this.selector = selector;
    this.rules = rules;
  }
}

class ClassSelectorNode extends AstNode {
  constructor(class_name, rules) {
    super();
    this.class_name = class_name;
    this.rules = rules;
  }
}

class Parser {
  constructor(tokens, index = 0, end_token = null) {
    this.tokens = tokens;
    this.index = index;
    this.end_token = end_token;
  }

  get current() {
    return this.tokens[this.index];
  }

  get peek() {
    return this.tokens[this.index + 1];
  }

  clone(end_token = null) {
    return new Parser(this.tokens, this.index, end_token || this.end_token);
  }

  consume_clone(parser) {
    this.index = parser.index;
  }

  consume(TokenClass) {
    if (!(this.current instanceof TokenClass))
      throw new TokenMismatch(TokenClass, this.current);
    const token = this.current;
    this.index += 1;
    return token;
  }

  can_parse() {
    if (this.index >= this.tokens.length) return false;
    if (!this.end_token) return true;
    return !this.current.is(this.end_token);
  }

  parse() {
    const ast = [];
    while (this.can_parse()) {
      if (this.current.is(Dot) && this.peek?.is(IdentifierToken)) {
        ast.push(this.parse_class_selector());
      } else if (this.current.is(Ampersand) && this.peek?.is(PseudoClass)) {
        ast.push(this.parse_child_pseudo_selector());
      } else if (this.current.is(IdentifierToken) && this.peek?.is(OpenBrace)) {
        ast.push(this.parse_child_selector());
      } else if (this.current.is(IdentifierToken)) {
        ast.push(this.parse_rule());
      } else {
        throw new NotReached(this.current);
      }
    }
    return ast;
  }

  parse_class_selector() {
    this.consume(Dot);
    const { value: class_name } = this.consume(IdentifierToken);
    this.consume(OpenBrace);
    const cloned_parser = this.clone(CloseBrace);
    const rules = cloned_parser.parse();
    this.consume_clone(cloned_parser);
    this.consume(CloseBrace);
    return new ClassSelectorNode(class_name, rules);
  }

  parse_child_pseudo_selector() {
    this.consume(Ampersand);
    const { value: selector } = this.consume(PseudoClass);
    this.consume(OpenBrace);
    const cloned_parser = this.clone(CloseBrace);
    const rules = cloned_parser.parse();
    this.consume_clone(cloned_parser);
    this.consume(CloseBrace);
    return new PseudoSelectorNode(selector, rules);
  }

  parse_child_selector() {
    const { value: tag_name } = this.consume(IdentifierToken);
    this.consume(OpenBrace);
    const cloned_parser = this.clone(CloseBrace);
    const rules = cloned_parser.parse();
    this.consume_clone(cloned_parser);
    this.consume(CloseBrace);
    return new ChildSelectorNode(tag_name, rules);
  }

  parse_rule() {
    const { value: name } = this.consume(IdentifierToken);
    const { value } = this.consume(ValueToken);
    return new RuleNode(name, value);
  }
}

class Compiler {
  constructor(ast, tag_names = [], top_level = true) {
    this.ast = ast;
    this.tag_names = tag_names;
    this.top_level = top_level;
  }

  base_rules_start() {
    if (this.top_level) {
      if (this.tag_names.length !== 1) throw new NotReached();
      return `${this.tag_names[0]} {\n`;
    } else {
      return "";
    }
  }

  base_rules_end() {
    if (this.top_level) {
      return "}\n";
    } else {
      return "";
    }
  }

  eval() {
    const [rules, sub_rules] = this.eval_rules_and_sub_rules();
    return [rules, ...sub_rules];
  }

  eval_rules_and_sub_rules() {
    let rules = this.base_rules_start();
    const rule_nodes = this.ast.filter((node) => node instanceof RuleNode);
    for (let node of rule_nodes) {
      rules += "  " + this.eval_rule(node) + "\n";
    }
    rules += this.base_rules_end();

    let sub_rules = [];
    const sub_rule_nodes = this.ast.filter(
      (node) => !rule_nodes.includes(node)
    );
    for (let node of sub_rule_nodes) {
      switch (node.constructor) {
        case ClassSelectorNode:
          sub_rules = sub_rules.concat(this.eval_class_selector(node));
          break;
        case PseudoSelectorNode:
          sub_rules = sub_rules.concat(this.eval_pseudo_selector(node));
          break;
        case ChildSelectorNode:
          sub_rules = sub_rules.concat(this.eval_child_selector(node));
          break;
        default:
          throw new NotReached();
      }
    }
    return [rules, sub_rules];
  }

  eval_rule({ name, value }) {
    return `${name}: ${value};`;
  }

  eval_class_selector({ class_name, rules: ast }) {
    if (!class_name) throw new NotReached();
    let output = `${this.tag_names.join(" ")} .${class_name} {\n`;
    const [rules, sub_rules] = new Compiler(
      ast,
      [...this.tag_names, class_name],
      false
    ).eval_rules_and_sub_rules();
    output += rules;
    output += "}\n";

    return [output, ...sub_rules];
  }

  eval_pseudo_selector({ selector, rules: ast }) {
    if (!selector) throw new NotReached();
    let output = `${this.tag_names.join(" ")}:${selector} {\n`;
    const [rules, sub_rules] = new Compiler(
      ast,
      [...this.tag_names, selector],
      false
    ).eval_rules_and_sub_rules();
    output += rules;
    output += "}\n";

    return [output, ...sub_rules];
  }

  eval_child_selector({ tag_name, rules: ast }) {
    let output = `${this.tag_names.join(" ")} ${tag_name} {\n`;
    const [rules, sub_rules] = new Compiler(
      ast,
      [...this.tag_names, tag_name],
      false
    ).eval_rules_and_sub_rules();
    output += rules;
    output += "}\n";

    return [output, ...sub_rules];
  }
}

const compile_css = (style, tag_name) => {
  const tokens = tokenize(style);
  const ast = new Parser(tokens).parse();
  return new Compiler(ast, [tag_name]).eval();
};
require("colors");

class TypeMismatchError extends Error {}

// for classes to behave properly
Object.prototype.to_ps = function () {
  return Str.new(this.name);
};
Object.prototype.nil_q = function () {
  assert(this.constructor !== Nil);
  return Bool.new(false);
};
const assert = (bool) => {
  if (!bool) throw new NotReached();
};

Function.prototype.to_b = () => Bool.new(true);

const assertType = (val, type) => {
  if (typeof val !== type && val.constructor !== type)
    throw new TypeMismatchError();
};

class Value {
  constructor(value) {
    this.__value = value;
  }
  static ["new"](value) {
    return new this(value);
  }
  to_js() {
    return this.__value;
  }
  to_s() {
    return Str.new(this.to_js().toString());
  }
  bang() {
    if (this.to_b().to_js()) {
      return Bool.new(false);
    } else {
      return Bool.new(true);
    }
  }
  nil_q() {
    return Bool.new(false);
  }
  is_a_q(constructor) {
    return Bool.new(this.constructor === constructor);
  }
  __eq__(other) {
    try {
      this.__check_type(other);
      return Bool.new(this.to_js() === other.to_js());
    } catch (e) {
      return Bool.new(false);
    }
  }
  __not_eq__(other) {
    try {
      this.__check_type(other);
      return Bool.new(this.to_js() !== other.to_js());
    } catch (e) {
      return Bool.new(false);
    }
  }
  __or__(other) {
    if (this.to_b().to_js()) {
      return this;
    } else {
      return other;
    }
  }
  __and__(other) {
    if (!this.to_b().to_js()) {
      return this;
    }
    if (typeof other === "function") {
      other = other();
    }
    return other;
  }

  to_b() {
    return Bool.new(!(this instanceof Nil));
  }
  __check_type(other, type = undefined) {
    if (!(other instanceof (type || this.constructor)))
      throw new TypeMismatchError();
  }
}

class Bool extends Value {
  to_ps() {
    return Str.new(this.to_js().toString().yellow);
  }
  constructor(value) {
    assertType(value, Boolean);
    super(value);
  }
  to_b() {
    return this;
  }
  __eq__(other) {
    return Bool.new(this.to_js() === other.to_js());
  }
}

class Int extends Value {
  to_ps() {
    return Str.new(this.to_js().toString().yellow);
  }
  __gt__(other) {
    this.__check_type(other);
    return Bool.new(this.to_js() > other.to_js());
  }
  __lt__(other) {
    this.__check_type(other);
    return Bool.new(this.to_js() < other.to_js());
  }
  __gt_eq__(other) {
    this.__check_type(other);
    return Bool.new(this.to_js() >= other.to_js());
  }
  __lt_eq__(other) {
    this.__check_type(other);
    return Bool.new(this.to_js() <= other.to_js());
  }
  __mult__(other) {
    this.__check_type(other);
    return Int.new(this.to_js() * other.to_js());
  }
  __div__(other) {
    this.__check_type(other);
    return Int.new(this.to_js() / other.to_js());
  }
  __plus__(other) {
    this.__check_type(other);
    return Int.new(this.to_js() + other.to_js());
  }
  __minus__(other) {
    this.__check_type(other);
    return Int.new(this.to_js() - other.to_js());
  }
}

class Float extends Value {
  to_ps() {
    return Str.new(this.to_js().toString().yellow);
  }

  to_i() {
    return Int.new(Math.floor(this.to_js()));
  }
  __gt__(other) {
    this.__check_type(other);
    return Float.new(this.to_js() > other.to_js());
  }
  __lt__(other) {
    this.__check_type(other);
    return Float.new(this.to_js() < other.to_js());
  }
  __gt_eq__(other) {
    this.__check_type(other);
    return Bool.new(this.to_js() >= other.to_js());
  }
  __lt_eq__(other) {
    this.__check_type(other);
    return Bool.new(this.to_js() <= other.to_js());
  }
  __mult__(other) {
    this.__check_type(other);
    return Float.new(this.to_js() * other.to_js());
  }
  __div__(other) {
    this.__check_type(other);
    return Float.new(this.to_js() / other.to_js());
  }
  __plus__(other) {
    this.__check_type(other);
    return Float.new(this.to_js() + other.to_js());
  }
  __minus__(other) {
    this.__check_type(other);
    return Float.new(this.to_js() - other.to_js());
  }
}

class Str extends Value {
  to_ps() {
    return Str.new(`"${this.to_js()}"`.green);
  }
  to_s() {
    return this;
  }
  to_i() {
    const val = parseInt(this.to_js());
    if (!isNaN(val)) {
      return Int.new(val);
    } else {
      return Nil.new();
    }
  }
  to_f() {
    const val = Number(this.to_js());
    if (!isNaN(val)) {
      return Float.new(val);
    } else {
      return Nil.new();
    }
  }
  trim() {
    return Str.new(this.to_js().trim());
  }
  __gt__(other) {
    this.__check_type(other);
    return Str.new(this.to_js() > other.to_js());
  }
  __lt__(other) {
    this.__check_type(other);
    return Str.new(this.to_js() < other.to_js());
  }
  __mult__(other) {
    this.__check_type(other, Int);
    let str = this.to_js();
    for (let i = 0; i < other.to_js() - 1; i++) {
      str += this.to_js();
    }
    return Str.new(str);
  }
  __plus__(other) {
    this.__check_type(other);
    return Str.new(this.to_js() + other.to_js());
  }
}

class Record extends Value {
  __size = 0;
  constructor(value) {
    assertType(value, Array);
    super(value);
    this.__size = allEntries(value).length;
  }
  __lookup__(key) {
    const value = this.to_js().find(([k, v]) => {
      if (k.__eq__(key).to_js()) {
        return v;
      }
    });
    return (value && value[1]) || Nil.new();
  }
  __unsafe_insert__(key, value) {
    this.__value.push([key, value]);
  }
  size() {
    return Int.new(this.to_js().length);
  }
  has_q(key) {
    return this.__lookup__(key).nil_q().bang();
  }
  to_l() {
    return List.new(this.to_js().map((l) => List.new(l)));
  }
  each(fn) {
    this.to_js().forEach(([key, value], i) => {
      fn(key, value, Int.new(i));
    });
  }
  remove(key) {
    let new_record = this.to_js().slice();
    new_record = new_record.filter(([k]) => !k.__eq__(key).to_js());
    return Record.new(new_record);
  }
  combine(record) {
    let new_record = this;
    record.each((k, v) => {
      new_record = new_record.remove(k);
      new_record = new_record.insert(k, v);
    });
    return new_record;
  }
  __plus__(other) {
    return this.combine(other);
  }
  __minus__(other) {
    if (!(other instanceof List)) other = List.new([other]);
    let new_record = this;
    other.each((key) => {
      new_record = new_record.remove(key);
    });
    return new_record;
  }
  insert(key, value) {
    let newRecord = this.to_js().slice();
    newRecord = newRecord.filter(([k]) => !k.__eq__(key).to_js());
    newRecord.push([key, value]);
    return Record.new(newRecord);
  }
  every(fn) {
    return Bool.new(
      this.to_js().every(([k, v]) => {
        return fn(k, v).to_js();
      })
    );
  }
  map(fn) {
    return Record.new(
      this.to_js().map(([k, v]) => {
        const k_v = fn(k, v);
        return [k_v.__lookup__(Int.new(0)), k_v.__lookup__(Int.new(1))];
      })
    );
  }
  to_ps() {
    if (this.size().to_js() == 0) return Str.new("{}");
    let s = "{";
    this.each((key, value, i) => {
      i = i.to_js();
      let key_s;
      if (key instanceof Sym) {
        key_s = (key.to_js().toString().slice(7, -1) + ":").blue;
      } else {
        key_s = `[${key.to_ps().to_js()}]:`;
      }
      s += ` ${key_s} ${value.to_ps().to_js()}`;
      if (i < this.size().to_js() - 1) s += ",";
    });
    return Str.new(s + " }");
  }
}

class List extends Value {
  __lookup__(index) {
    return this.to_js()[index.to_js()];
  }
  get size() {
    return Int.new(this.to_js().length);
  }
  to_r() {
    const record = [];
    for (let item of this.to_js()) {
      const [k, v] = [item.__lookup__(Int.new(0)), item.__lookup__(Int.new(1))];
      record.push([k, v]);
    }
    return Record.new(record);
  }

  to_ps() {
    // I'm aware, this is gross lol. It'll be much better once we write it in peacock
    let s = "[";
    s += this.to_js()
      .map((val) => val.to_ps().to_js())
      .join(", ");
    s += "]";
    return Str.new(s);
  }

  __eq__(other) {
    this.__check_type(other);
    if (this === other) return Bool.new(true);
    return this.every((item, i) => item.__eq__(other.__lookup__(i)));
  }

  __plus__(other) {
    this.__check_type(other);
    return List.new([...this.to_js(), ...other.to_js()]);
  }

  has_q(other) {
    return Bool.new(this.to_js().some((val) => val.__eq__(other).to_js()));
  }

  every(fn) {
    for (let i = 0; i < this.to_js().length; i++) {
      const result = fn(this.to_js()[i], Int.new(i));
      if (!result.to_js()) {
        return Bool.new(false);
      }
    }
    return Bool.new(true);
  }

  any_q(fn) {
    for (let i = 0; i < this.to_js().length; i++) {
      const result = fn(this.to_js()[i], Int.new(i));
      if (result.to_js()) {
        return Bool.new(true);
      }
    }
    return Bool.new(false);
  }

  flat() {
    let new_list = [];
    for (let list of this.to_js()) {
      assertType(list, List);
      new_list = new_list.concat(list.to_js());
    }
    return List.new(new_list);
  }

  size() {
    return Int.new(this.to_js().length);
  }

  find(fn) {
    for (let item of this.to_js()) {
      const result = fn(item);
      // This is definitely wrong
      if (result.to_b().to_js()) return item;
    }
    return Nil.new();
  }

  first(fn) {
    for (let item of this.to_js()) {
      const result = fn(item);
      // This is definitely wrong
      if (result.to_b().to_js()) return result;
    }
    return Nil.new();
  }

  map(fn) {
    return List.new(this.to_js().map((item, i) => fn(item, Int.new(i), this)));
  }

  last_index() {
    return Int.new(this.size().to_js() - 1);
  }

  each(fn) {
    this.to_js().forEach((val, i) => fn(val, Int.new(i)));
  }

  filter(fn) {
    return List.new(
      this.to_js().filter((v) => {
        const result = fn(v);
        // this.__check_type(result, Bool);
        return result.to_b().to_js();
      })
    );
  }

  __minus__(other) {
    this.__check_type(other);
    return this.filter((val) => other.include__q(val));
  }
}

class Sym extends Value {
  constructor(sym) {
    if (typeof sym === "symbol") {
      super(sym);
    } else if (sym instanceof Str) {
      super(Peacock.symbol(sym.to_js()));
    } else if (typeof sym === "string") {
      super(Peacock.symbol(sym));
    } else {
      throw new NotReached();
    }
  }

  to_s() {
    return Str.new(`${this.to_js().toString().slice(7, -1)}`);
  }

  to_ps() {
    return Str.new(`:${this.to_js().toString().slice(7, -1)}`.blue);
  }
}

class DomNode {
  constructor(name, attributes, children) {
    assertType(name, Str);
    assertType(attributes, Record);
    assertType(children, List);
    this.name = name;
    this.attributes = attributes;
    this.children = children;
  }
  static ["new"](name, attributes, children) {
    return new DomNode(name, attributes, children);
  }
  _can_render(elem) {
    return (
      elem instanceof DomTextNode ||
      elem instanceof DomNode ||
      elem instanceof Element
    );
  }
  render_list(list, elem) {
    list.each((child) => {
      if (child instanceof Nil) {
        // nothing
      } else if (this._can_render(child)) {
        elem.append(child.to_dom());
      } else if (child instanceof Str) {
        elem.append(DomTextNode.new(child.to_s()).to_dom());
      } else if (child instanceof List) {
        this.render_list(child, elem);
      } else {
        debugger;
        throw new NotReached();
      }
    });
  }
  to_dom() {
    const elem = document.createElement(this.name.to_js());
    this.attributes.each((name, value) => {
      if (typeof value === "function") {
        elem[name.to_s().to_js()] = value;
      } else if (value instanceof Bool) {
        if (value.to_js()) {
          elem.setAttribute(name.to_s().to_js(), value.to_js());
        }
      } else {
        if (name.to_s().to_js() == "class_name") {
          name = Str.new("class");
        }
        elem.setAttribute(name.to_s().to_js(), value.to_js());
      }
    });
    this.children.each((expr) => {
      if (expr instanceof List) {
        this.render_list(expr, elem);
      } else if (this._can_render(expr)) {
        const dom = expr.to_dom();
        if (!(dom instanceof NilNode)) elem.append(dom);
      } else if (expr instanceof Nil) {
        // do nothing
      } else {
        const node = DomTextNode.new(expr.to_s()).to_dom();
        if (node instanceof Text && node.nodeValue.match(/[a-zA-Z]+/)) {
          node.nodeValue += " ";
        }
        elem.append(node);
      }
    });
    return elem;
  }
}

class Nil extends Value {
  nil_q() {
    return Bool.new(true);
  }

  to_ps() {
    return Str.new("nil".blue);
  }
}

class DomTextNode extends Value {
  to_dom() {
    // TODO: find way to not have __value double nested like this
    return document.createTextNode(this.__value.to_js());
  }
}

class NilNode extends Value {
  to_dom() {
    return Nil.new();
  }
}

class Context extends Value {
  constructor(val = Nil.new()) {
    super(val);
  }
  listeners = [];
  _register_listener(fn) {
    this.listeners.push(fn);
  }
  value() {
    return this.__value;
  }
  set_value(v) {
    this.__value = v;
    this.listeners.forEach((fn) => fn(v));
  }
}

class Element {
  static __STATES = {};
  init_state() {
    return Nil.new();
  }
  constructor(props) {
    this._props = props;
    this.use_context();
  }
  context() {
    return Nil.new();
  }
  context_value() {
    return (this.context().value && this.context().value()) || Nil.new();
  }
  set_context(value) {
    if (!(this.context() instanceof Context)) throw new NotReached();
    this.context().set_value(value);
  }
  use_context() {
    if (this.context() instanceof Context) {
      this.context()._register_listener(() => this.render_to_dom());
    }
  }
  set_timeout(fn, delay) {
    setTimeout(fn, delay.to_js());
  }
  static style_sheet;
  static ["new"](props) {
    return new this(props);
  }
  __generate_element_id() {
    if (Element.__STATES[this.constructor]?.class_name) throw new NotReached();
    const id = Array.from({ length: 10 })
      .map((i) => parseInt(Math.random() * 10))
      .join("");
    Element.__STATES[this.constructor].class_name = "c" + id;
    return Element.__STATES[this.constructor].class_name;
  }
  create_style_sheet() {
    if (Element.style_sheet) return Element.style_sheet;
    Element.style_sheet = document.createElement("style");
    document.body.append(Element.style_sheet);
    return Element.style_sheet;
  }
  style() {
    return Str.new("");
  }
  state() {
    if (!Element.__STATES[this.constructor]) {
      return (Element.__STATES[this.constructor] = {
        state: this.init_state(),
      }).state;
    } else if (!Element.__STATES[this.constructor].state) {
      return (Element.__STATES[this.constructor].state = this.init_state());
    } else {
      return Element.__STATES[this.constructor].state;
    }
  }
  props() {
    return this._props || Nil.new();
  }
  set_state(value) {
    Element.__STATES[this.constructor].state = value;
    this.render_to_dom();
  }

  prev_props = Nil.new();
  prev_state = Nil.new();
  prev_context = Nil.new();
  render_to_dom() {
    if (
      this.prev_state.__eq__(this.state()).to_js() &&
      this.prev_props.__eq__(this.props()).to_js() &&
      this.prev_context.__eq__(this.context_value()).to_js()
    ) {
      return;
    }
    const node = this.to_dom();
    const [class_name] = node.classList;
    assert(this.class_name() === class_name);
    const elements = document.getElementsByClassName(class_name);
    assert(elements.length === 1);
    elements[0].replaceWith(node);
  }

  view() {
    return Nil.new();
  }
  class_name() {
    return (
      Element.__STATES[this.constructor].class_name ||
      this.__generate_element_id()
    );
  }
  replace_styles() {
    const { sheet } = this.create_style_sheet();
    for (let i = 0; i < sheet.cssRules.length; i++) {
      if (sheet.cssRules[i].selectorText.includes(this.class_name()))
        sheet.deleteRule(i);
    }
    const styles = compile_css(
      this.style(this.props(), this.state()).to_js(),
      `.${this.class_name()}`
    );
    for (let style of styles) {
      sheet.insertRule(style);
    }
  }

  to_dom() {
    try {
      let elem = this.view(this.props(), this.state(), this.context_value());
      this.prev_state = this.state();
      this.prev_props = this.props();
      this.prev_context = this.context_value();
      if (elem instanceof Element) {
        return elem.to_dom();
      }
      this.replace_styles();
      const new_attrs = elem.attributes.insert(
        Sym.new("class"),
        Str.new(this.class_name())
      );
      return DomNode.new(elem.name, new_attrs, elem.children).to_dom();
    } catch (e) {
      console.error(e, this.name);
    }
  }
}

class Div extends Element {
  view(props) {
    return DomNode.new(
      Str.new("div"),
      props,
      List.new([props.__lookup__(Sym.new("children"))])
    );
  }
}

class Article extends Element {
  view(props) {
    return DomNode.new(
      Str.new("article"),
      props,
      List.new([props.__lookup__(Sym.new("children"))])
    );
  }
}

class Details extends Element {
  view(props) {
    return DomNode.new(
      Str.new("details"),
      props,
      List.new([props.__lookup__(Sym.new("children"))])
    );
  }
}

class A extends Element {
  view(props) {
    return DomNode.new(
      Str.new("a"),
      props,
      List.new([props.__lookup__(Sym.new("children"))])
    );
  }
}

const mount_element = (ElementClass, node) => {
  node.append(ElementClass.new().to_dom());
};

const print = (...params) => {
  console.log(...params.map((p) => p.to_ps().to_js()));
};
const inspect = { print };

const document_body = globalThis.document && document.body;

const __try = (fn) => {
  try {
    return fn();
  } catch (e) {
    return undefined;
  }
};
const Peacock = {
  symbol: symName => __Symbols[symName] || (__Symbols[symName] = Symbol(symName)),
};
let pea_module;

const f = (...params) => 
  Schema.case(List.new(params),
    List.new([
      List.new([Schema.for(List.new([Schema.for(Int.new(3))])), ((__VALUE) => {
    return Int.new(5);; return Nil.new();
  })])
    ])
  );
pea_module = Record.new([

]);
print(f(Int.new(3)));
__try(() => eval('Main')) && mount_element(Main, document.getElementById('main'))
