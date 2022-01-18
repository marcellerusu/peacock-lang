require("colors");

class TypeMismatchError extends Error {}

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
  __and__(other) {
    return new Bool(this.to_js() && other.to_b().to_js());
  }
  __or__(other) {
    return new Bool(this.to_js() || other.to_b().to_js());
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
    return value[1] || new Nil();
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

  include__q(other) {
    return new Bool(this.to_js().some((val) => val.__eq__(other)));
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
    return new List(this.to_js().map(fn));
  }

  each(fn) {
    this.to_js().forEach(fn);
  }

  filter(fn) {
    return new List(
      this.to_js().filter((v) => {
        const result = fn(v);
        // this.__check_type(result, Bool);
        return result.to_js();
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
        expr.each((child) => {
          elem.append(child.to_dom());
        });
      } else if (expr instanceof DomTextNode || expr instanceof DomNode) {
        elem.append(expr.to_dom());
      } else {
        const node = new DomTextNode(expr.to_s()).to_dom();
        if (node instanceof Text) {
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

class Element {
  _state = new Nil();
  constructor(props) {
    this._props = props;
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
    const style_sheet = document.createElement("style");
    document.body.append(style_sheet);
    return style_sheet;
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
  prev_dom_result = Nil.new();
  render_to_dom() {
    if (
      this.prev_state.__eq__(this.state()).to_js() &&
      this.prev_props.__eq__(this.props()).to_js()
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
    let elem = this.view(this.props(), this.state());
    this.prev_state = this.state();
    this.prev_props = this.props();
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
