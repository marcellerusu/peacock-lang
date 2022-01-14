require("colors");

class TypeMismatchError extends Error {}

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
    return new Str(this.__value.toString());
  }
  __val__() {
    return this.__value;
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
      return new Bool(this.__value === other.__val__());
    } catch (e) {
      return new Bool(false);
    }
  }
  __not_eq__(other) {
    try {
      this.__check_type(other);
      return new Bool(this.__value !== other.__val__());
    } catch (e) {
      return new Bool(false);
    }
  }
  to_b() {
    const val = this.__value;
    return new Bool(val !== null && val !== undefined);
  }
  __check_type(other, type = undefined) {
    if (!(other instanceof (type || this.constructor)))
      throw new TypeMismatchError();
  }
}

class Bool extends Value {
  to_ps() {
    return new Str(this.__value.toString().yellow);
  }
  constructor(value) {
    if (value instanceof Bool) {
      super(value.__val__());
    } else {
      super(value);
    }
  }
  to_b() {
    return this;
  }
  __and__(other) {
    return new Bool(this.__value && other.to_b().__val__());
  }
  __or__(other) {
    return new Bool(this.__value || other.to_b().__val__());
  }
}

class Int extends Value {
  to_ps() {
    return new Str(this.__value.toString().yellow);
  }
  __gt__(other) {
    this.__check_type(other);
    return new Bool(this.__value > other.__val__());
  }
  __lt__(other) {
    this.__check_type(other);
    return new Bool(this.__value < other.__val__());
  }
  __gt_eq__(other) {
    this.__check_type(other);
    return new Bool(this.__value >= other.__val__());
  }
  __lt_eq__(other) {
    this.__check_type(other);
    return new Bool(this.__value <= other.__val__());
  }
  __mult__(other) {
    this.__check_type(other);
    return new Int(this.__value * other.__val__());
  }
  __div__(other) {
    this.__check_type(other);
    return new Int(this.__value / other.__val__());
  }
  __plus__(other) {
    this.__check_type(other);
    return new Int(this.__value + other.__val__());
  }
  __minus__(other) {
    this.__check_type(other);
    return new Int(this.__value - other.__val__());
  }
}

class Float extends Value {
  to_ps() {
    return new Str(this.__value.toString().yellow);
  }

  to_i() {
    return new Int(Math.floor(this.__value));
  }
  __gt__(other) {
    this.__check_type(other);
    return new Float(this.__value > other.__val__());
  }
  __lt__(other) {
    this.__check_type(other);
    return new Float(this.__value < other.__val__());
  }
  __gt_eq__(other) {
    this.__check_type(other);
    return new Bool(this.__value >= other.__val__());
  }
  __lt_eq__(other) {
    this.__check_type(other);
    return new Bool(this.__value <= other.__val__());
  }
  __mult__(other) {
    this.__check_type(other);
    return new Float(this.__value * other.__val__());
  }
  __div__(other) {
    this.__check_type(other);
    return new Float(this.__value / other.__val__());
  }
  __plus__(other) {
    this.__check_type(other);
    return new Float(this.__value + other.__val__());
  }
  __minus__(other) {
    this.__check_type(other);
    return new Float(this.__value - other.__val__());
  }
}

class Str extends Value {
  to_ps() {
    return new Str(`"${this.__value}"`.green);
  }
  to_s() {
    return this;
  }
  to_i() {
    const val = parseInt(this.__value);
    if (!isNaN(val)) {
      return new Int(val);
    } else {
      return new Nil();
    }
  }
  to_f() {
    const val = Number(this.__value);
    if (!isNaN(val)) {
      return new Float(val);
    } else {
      return new Nil();
    }
  }
  trim() {
    return new Str(this.__value.trim());
  }
  __gt__(other) {
    this.__check_type(other);
    return new Str(this.__value > other.__val__());
  }
  __lt__(other) {
    this.__check_type(other);
    return new Str(this.__value < other.__val__());
  }
  __mult__(other) {
    this.__check_type(other, Int);
    let str = this.__value;
    for (let i = 0; i < other.__val__() - 1; i++) {
      str += this.__value;
    }
    return new Str(str);
  }
  __plus__(other) {
    this.__check_type(other);
    return new Str(this.__value + other.__val__());
  }
}

class Record extends Value {
  __size = 0;
  constructor(value) {
    super(value);
    this.__size = allEntries(value).length;
  }
  __lookup__(index) {
    return this.__value[index.__val__()];
  }
  size() {
    return new Int(this.__size);
  }
  has_q(key) {
    return new Bool(typeof this.__value[key.__val__()] !== "undefined");
  }
  to_l() {
    return new List(allEntries(this.__value).map((l) => new List(l)));
  }
  each(fn) {
    for (let [key, value] of allEntries(this.__value)) {
      fn(key, value);
    }
  }

  to_ps() {
    let s = "{";
    const keys = Reflect.ownKeys(this.__value);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const sym_key = key.toString().slice(7, -1);
      s += ` ${sym_key}: ${this.__value[key].to_ps().__val__()}`;
      if (i < keys.length - 1) s += ",";
    }
    return new Str(s + " }");
  }
}

class List extends Value {
  __lookup__(index) {
    return this.__value[index.__val__()];
  }
  get size() {
    return new Int(this.__value.length);
  }
  to_r() {
    const record = {};
    for (let item of this.__value) {
      const [k, v] = [item.__lookup__(Int.new(0)), item.__lookup__(Int.new(1))];
      record[k.__val__()] = v;
    }
    return new Record(record);
  }

  to_ps() {
    // I'm aware, this is gross lol. It'll be much better once we write it in peacock
    let s = "[";
    s += this.__value.map((val) => val.to_ps().__val__()).join(", ");
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
    return new List([...this.__value, ...other.__val__()]);
  }

  include__q(other) {
    return new Bool(this.__value.some((val) => val.__eq__(other)));
  }

  every(fn) {
    for (let i = 0; i < this.__value.length; i++) {
      const result = fn(this.__value[i], Int.new(i));
      if (!result.__val__()) {
        return new Bool(false);
      }
    }
    return new Bool(true);
  }

  first(fn) {
    for (let item of this.__value) {
      const result = fn(item);
      // This is definitely wrong
      if (result) return result;
    }
  }

  map(fn) {
    return new List(this.__value.map(fn));
  }

  each(fn) {
    this.__value.forEach(fn);
  }

  filter(fn) {
    return new List(
      this.__value.filter((v) => {
        const result = fn(v);
        // this.__check_type(result, Bool);
        return result.__val__();
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
      super(Peacock.symbol(sym.__val__()));
    } else if (typeof sym === "string") {
      super(Peacock.symbol(sym));
    } else {
      throw new NotReached();
    }
  }

  to_s() {
    return new Str(`${this.__value.toString().slice(7, -1)}`);
  }

  to_ps() {
    return new Str(`:${this.__value.toString().slice(7, -1)}`.blue);
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
    const elem = document.createElement(this.name.__val__());
    this.attributes.each((name, value) => {
      if (typeof value === "function") {
        elem[name.to_s().to_js()] = value;
      } else {
        elem.setAttribute(name.to_s().__val__(), value.to_js());
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
    return document.createTextNode(this.__value.__val__());
  }
}

class Element {
  _state = new Nil();
  constructor(props) {
    this.props = props;
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
  set_state(value) {
    this._state = value;
    document.getElementsByClassName(this.dom_id)[0].replaceWith(this.to_dom());
  }

  view() {
    return new Nil();
  }
  to_dom() {
    let elem = this.view(this.props, this.state());
    if (elem instanceof Element) {
      return elem.to_dom();
    }
    const class_name = this.dom_id || this.__generate_class_id();
    const styles = compile_css(this.style().__val__(), `.${class_name}`);
    for (let style of styles) {
      this.create_style_sheet().sheet.insertRule(style);
    }
    const attrs = elem.attributes.__val__();
    attrs[Peacock.symbol("class")] = new Str(class_name);
    return new DomNode(elem.name, new Record(attrs), elem.children).to_dom();
  }
}

const mount_element = (ElementClass, node) => {
  node.append(new ElementClass().to_dom());
};

const print = (...params) => {
  console.log(...params.map((p) => p.to_ps().__val__()));
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
