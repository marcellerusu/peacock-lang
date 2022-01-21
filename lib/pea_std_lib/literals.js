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
    return new Str(this.to_js().toString());
  }
  bang() {
    if (this.to_b().to_js()) {
      return new Bool(false);
    } else {
      return new Bool(true);
    }
  }
  nil_q() {
    return new Bool(false);
  }
  is_a_q(constructor) {
    return new Bool(this.constructor === constructor);
  }
  __eq__(other) {
    try {
      this.__check_type(other);
      return new Bool(this.to_js() === other.to_js());
    } catch (e) {
      return new Bool(false);
    }
  }
  __not_eq__(other) {
    try {
      this.__check_type(other);
      return new Bool(this.to_js() !== other.to_js());
    } catch (e) {
      return new Bool(false);
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
    if (this.to_b().to_js() && other.to_b().to_js()) {
      return other;
    } else {
      return this;
    }
  }

  to_b() {
    return new Bool(!(this instanceof Nil));
  }
  __check_type(other, type = undefined) {
    if (!(other instanceof (type || this.constructor)))
      throw new TypeMismatchError();
  }
}

class Bool extends Value {
  to_ps() {
    return new Str(this.to_js().toString().yellow);
  }
  constructor(value) {
    assertType(value, Boolean);
    super(value);
  }
  to_b() {
    return this;
  }
  __eq__(other) {
    return new Bool(this.to_js() === other.to_js());
  }
}

class Int extends Value {
  to_ps() {
    return new Str(this.to_js().toString().yellow);
  }
  __gt__(other) {
    this.__check_type(other);
    return new Bool(this.to_js() > other.to_js());
  }
  __lt__(other) {
    this.__check_type(other);
    return new Bool(this.to_js() < other.to_js());
  }
  __gt_eq__(other) {
    this.__check_type(other);
    return new Bool(this.to_js() >= other.to_js());
  }
  __lt_eq__(other) {
    this.__check_type(other);
    return new Bool(this.to_js() <= other.to_js());
  }
  __mult__(other) {
    this.__check_type(other);
    return new Int(this.to_js() * other.to_js());
  }
  __div__(other) {
    this.__check_type(other);
    return new Int(this.to_js() / other.to_js());
  }
  __plus__(other) {
    this.__check_type(other);
    return new Int(this.to_js() + other.to_js());
  }
  __minus__(other) {
    this.__check_type(other);
    return new Int(this.to_js() - other.to_js());
  }
}

class Float extends Value {
  to_ps() {
    return new Str(this.to_js().toString().yellow);
  }

  to_i() {
    return new Int(Math.floor(this.to_js()));
  }
  __gt__(other) {
    this.__check_type(other);
    return new Float(this.to_js() > other.to_js());
  }
  __lt__(other) {
    this.__check_type(other);
    return new Float(this.to_js() < other.to_js());
  }
  __gt_eq__(other) {
    this.__check_type(other);
    return new Bool(this.to_js() >= other.to_js());
  }
  __lt_eq__(other) {
    this.__check_type(other);
    return new Bool(this.to_js() <= other.to_js());
  }
  __mult__(other) {
    this.__check_type(other);
    return new Float(this.to_js() * other.to_js());
  }
  __div__(other) {
    this.__check_type(other);
    return new Float(this.to_js() / other.to_js());
  }
  __plus__(other) {
    this.__check_type(other);
    return new Float(this.to_js() + other.to_js());
  }
  __minus__(other) {
    this.__check_type(other);
    return new Float(this.to_js() - other.to_js());
  }
}

class Str extends Value {
  to_ps() {
    return new Str(`"${this.to_js()}"`.green);
  }
  to_s() {
    return this;
  }
  to_i() {
    const val = parseInt(this.to_js());
    if (!isNaN(val)) {
      return new Int(val);
    } else {
      return new Nil();
    }
  }
  to_f() {
    const val = Number(this.to_js());
    if (!isNaN(val)) {
      return new Float(val);
    } else {
      return new Nil();
    }
  }
  trim() {
    return new Str(this.to_js().trim());
  }
  __gt__(other) {
    this.__check_type(other);
    return new Str(this.to_js() > other.to_js());
  }
  __lt__(other) {
    this.__check_type(other);
    return new Str(this.to_js() < other.to_js());
  }
  __mult__(other) {
    this.__check_type(other, Int);
    let str = this.to_js();
    for (let i = 0; i < other.to_js() - 1; i++) {
      str += this.to_js();
    }
    return new Str(str);
  }
  __plus__(other) {
    this.__check_type(other);
    return new Str(this.to_js() + other.to_js());
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
    return (value && value[1]) || new Nil();
  }
  __unsafe_insert__(key, value) {
    this.__value.push([key, value]);
  }
  size() {
    return new Int(this.to_js().length);
  }
  has_q(key) {
    return this.__lookup__(key).nil_q().bang();
  }
  to_l() {
    return new List(this.to_js().map((l) => new List(l)));
  }
  each(fn) {
    this.to_js().forEach(([key, value], i) => {
      fn(key, value, i);
    });
  }
  combine(record) {
    let newRecord = this.to_js().slice();

    record.each((k, v) => {
      newRecord = newRecord.filter(([k1]) => !k1.__eq__(k).to_js());
      newRecord.push([k, v]);
    });
    return Record.new(newRecord);
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
    let s = "{";
    this.each((key, value, i) => {
      let key_s;
      if (key instanceof Sym) {
        key_s = (key.to_js().toString().slice(7, -1) + ":").blue;
      } else {
        key_s = `[${key.to_ps().to_js()}]:`;
      }
      s += ` ${key_s} ${value.to_ps().to_js()}`;
      if (i < this.size().to_js() - 1) s += ",";
    });
    return new Str(s + " }");
  }
}

class List extends Value {
  __lookup__(index) {
    return this.to_js()[index.to_js()];
  }
  get size() {
    return new Int(this.to_js().length);
  }
  to_r() {
    const record = [];
    for (let item of this.to_js()) {
      const [k, v] = [item.__lookup__(Int.new(0)), item.__lookup__(Int.new(1))];
      record.push([k, v]);
    }
    return new Record(record);
  }

  to_ps() {
    // I'm aware, this is gross lol. It'll be much better once we write it in peacock
    let s = "[";
    s += this.to_js()
      .map((val) => val.to_ps().to_js())
      .join(", ");
    s += "]";
    return new Str(s);
  }

  __eq__(other) {
    this.__check_type(other);
    if (this === other) return new Bool(true);
    return this.every((item, i) => item.__eq__(other.__lookup__(i)));
  }

  __plus__(other) {
    this.__check_type(other);
    return new List([...this.to_js(), ...other.to_js()]);
  }

  has_q(other) {
    return new Bool(this.to_js().some((val) => val.__eq__(other).to_js()));
  }

  every(fn) {
    for (let i = 0; i < this.to_js().length; i++) {
      const result = fn(this.to_js()[i], Int.new(i));
      if (!result.to_js()) {
        return new Bool(false);
      }
    }
    return new Bool(true);
  }

  any_q(fn) {
    for (let i = 0; i < this.to_js().length; i++) {
      const result = fn(this.to_js()[i], Int.new(i));
      if (result.to_js()) {
        return new Bool(true);
      }
    }
    return new Bool(false);
  }

  size() {
    return new Int(this.to_js().length);
  }

  first(fn) {
    for (let item of this.to_js()) {
      const result = fn(item);
      // This is definitely wrong
      if (result) return result;
    }
    return new Nil();
  }

  map(fn) {
    return new List(this.to_js().map((item, i) => fn(item, Int.new(i), this)));
  }

  last_index() {
    return Int.new(this.size().to_js() - 1);
  }

  each(fn) {
    this.to_js().forEach(fn);
  }

  filter(fn) {
    return new List(
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
    return new Str(`${this.to_js().toString().slice(7, -1)}`);
  }

  to_ps() {
    return new Str(`:${this.to_js().toString().slice(7, -1)}`.blue);
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
        elem.append(new DomTextNode(child.to_s()).to_dom());
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
      } else {
        elem.setAttribute(name.to_s().to_js(), value.to_js());
      }
    });
    this.children.each((expr) => {
      if (expr instanceof List) {
        this.render_list(expr, elem);
      } else if (this._can_render(expr)) {
        elem.append(expr.to_dom());
      } else if (expr instanceof Nil) {
        // do nothing
      } else {
        const node = new DomTextNode(expr.to_s()).to_dom();
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
    return new Bool(true);
  }

  to_ps() {
    return new Str("nil".blue);
  }
}

class DomTextNode extends Value {
  to_dom() {
    // TODO: find way to not have __value double nested like this
    return document.createTextNode(this.__value.to_js());
  }
}

class Context extends Value {
  _value = Nil.new();
  listeners = [];
  _register_listener(fn) {
    this.listeners.push(fn);
  }
  value() {
    return this._value;
  }
  set_value(v) {
    this._value = v;
    this.listeners.forEach((fn) => fn(v));
  }
}

class Element {
  _state = Nil.new();
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
  dom_id;
  style_sheet;
  static ["new"](props) {
    return new this(props);
  }
  __generate_class_id() {
    if (this.dom_id) throw new NotReached();
    const id = Array.from({ length: 10 })
      .map((i) => parseInt(Math.random() * 10))
      .join("");
    this.dom_id = "c" + id;
    return this.dom_id;
  }
  create_style_sheet() {
    if (this.style_sheet) return this.style_sheet;
    this.style_sheet = document.createElement("style");
    document.body.append(this.style_sheet);
    return this.style_sheet;
  }
  style() {
    return new Str("");
  }
  state() {
    if (this._state.nil_q().to_js()) {
      return this.init_state();
    } else {
      return this._state;
    }
  }
  props() {
    return this._props || Nil.new();
  }
  set_state(value) {
    this._state = value;
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
    assert(this.dom_id === class_name);
    const elements = document.getElementsByClassName(class_name);
    assert(elements.length === 1);
    elements[0].replaceWith(node);
  }

  view() {
    return Nil.new();
  }
  class_name() {
    return this.dom_id || this.__generate_class_id();
  }
  replace_styles() {
    const { sheet } = this.create_style_sheet();
    for (let i = 0; i < sheet.cssRules.length; i++) {
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
    return new DomNode(elem.name, new_attrs, elem.children).to_dom();
  }
}

class Div extends Element {
  view(props) {
    return new DomNode(
      Str.new("div"),
      props,
      List.new([props.__lookup__(Sym.new("children"))])
    );
  }
}

class Article extends Element {
  view(props) {
    return new DomNode(
      Str.new("article"),
      props,
      List.new([props.__lookup__(Sym.new("children"))])
    );
  }
}

class A extends Element {
  view(props) {
    return new DomNode(
      Str.new("a"),
      props,
      List.new([props.__lookup__(Sym.new("children"))])
    );
  }
}

const mount_element = (ElementClass, node) => {
  node.append(new ElementClass().to_dom());
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
