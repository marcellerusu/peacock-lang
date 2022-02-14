if (!globalThis.document) {
  require("colors");
  const { JSDOM } = require("jsdom");
  const dom = new JSDOM();
  globalThis.document = dom.window.document;
  globalThis.Text = dom.window.Text;
}
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
Function.prototype.nil_q = () => Bool.new(false);

const assertType = (val, type) => {
  if (typeof val !== type && val.constructor !== type)
    throw new TypeMismatchError();
};

class Value {
  constructor(value) {
    this.__value = value;
  }
  static ["new"](...args) {
    return new this(...args);
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
  constructor(value, splats) {
    // TODO: remove assertTypes
    assertType(value, Array);
    assertType(splats, List);
    const size = value.length + splats.size().to_js();
    const index_to_splat = {};
    splats.each((val) => {
      const splat = val.__lookup__(Sym.new("splat"));
      const index = val.__lookup__(Sym.new("index"));
      index_to_splat[index.to_js()] = splat;
    });
    let record = [];
    let value_index = 0;
    const remove_existing = (key) => {
      for (let i = 0; i < record.length; i++) {
        if (record[i][0].__eq__(key).to_js()) {
          record.splice(i, 1);
        }
      }
    };
    for (let i = 0; i < size; i++) {
      if (index_to_splat[i]) {
        const splat = index_to_splat[i].to_js();
        for (const [key] of splat) {
          remove_existing(key);
        }
        record = record.concat(splat);
      } else {
        remove_existing(value[value_index][0]);
        record.push(value[value_index]);
        value_index++;
      }
    }
    super(record);
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
  __eq__(other) {
    if (this.size().__not_eq__(other.size()).to_js()) return Bool.new(false);
    return this.every((k, v) => other.__lookup__(k).__eq__(v));
  }
  has_q(key) {
    return Bool.new(
      !!this.to_js().find(([k, v]) => {
        if (k.__eq__(key).to_js()) {
          return v;
        }
      })
    );
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
    return Record.new(new_record, List.new([]));
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
    return Record.new(newRecord, List.new([]));
  }
  every(fn) {
    return Bool.new(
      this.to_js().every(([k, v]) => {
        return fn(k, v).to_b().to_js();
      })
    );
  }
  map(fn) {
    return Record.new(
      this.to_js().map(([k, v]) => {
        const k_v = fn(k, v);
        return [k_v.__lookup__(Int.new(0)), k_v.__lookup__(Int.new(1))];
      }),
      List.new([])
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
    return Record.new(record, List.new([]));
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

  push(val) {
    return List.new([...this.to_js(), val]);
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
    return this.filter((val) => other.has_q(val));
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

class Nil extends Value {
  nil_q() {
    return Bool.new(true);
  }

  to_s() {
    return Str.new("");
  }

  to_ps() {
    return Str.new("nil".blue);
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
    const bool_attrs = ["open", "disabled", "checked"];
    const elem = document.createElement(this.name.to_js());
    this.attributes.each((name, value) => {
      name = name.to_s().to_js();
      if (typeof value === "function") {
        elem[name] = value;
      } else if (bool_attrs.includes(name)) {
        if (value.to_b().to_js()) {
          elem.setAttribute(name, value.to_js());
        }
      } else {
        if (name == "class_name") {
          name = "class";
        }
        elem.setAttribute(name, value.to_js());
      }
    });
    this.children.each((expr) => {
      if (typeof expr === "function") expr = expr();
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

  inner_text() {
    return Str.new(this.to_dom().textContent);
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

function js_lookup(obj, ...path) {
  path = path.map((x) => x.to_js());
  let result = obj;
  for (const k of path) {
    result = result[k];
  }
  if (typeof result == "string") {
    return Str.new(result);
  }
  throw new NotReached();
}

class Element {
  init_state() {
    return Nil.new();
  }
  constructor(props) {
    this._props = props;
    this.use_context();
    this.set_state = this.set_state.bind(this);
    this.set_context = this.set_context.bind(this);
  }

  // test helpers

  inner_text() {
    return Str.new(this.to_dom().textContent);
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
  _class_name;
  __generate_element_id() {
    if (this._class_name) throw new NotReached();
    const id = Array.from({ length: 10 })
      .map((i) => parseInt(Math.random() * 10))
      .join("");
    this._class_name = "c" + id;
    return this._class_name;
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
  _state;
  state() {
    if (!this._state) {
      return (this._state = this.init_state());
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
    assert(this.class_name() === class_name);
    const elements = document.getElementsByClassName(class_name);
    assert(elements.length === 1);
    elements[0].replaceWith(node);
  }

  view() {
    return Nil.new();
  }
  class_name() {
    return this._class_name || this.__generate_element_id();
  }
  replace_styles() {
    // TODO: this has serious issues, needs to be made recursive
    // but it partially works..
    const { sheet } = this.create_style_sheet();
    const ast = parse_css(this._compute_style());

    const root_rules = ast.filter((node) => node.is(RuleNode));
    const this_elem_selector = `.${this.class_name()}`;

    for (const rule of sheet.cssRules) {
      if (!rule.selectorText.includes(this_elem_selector)) continue;
      const rest_of_selector = rule.selectorText
        .slice(
          rule.selectorText.indexOf(this_elem_selector) +
            this_elem_selector.length
        )
        .trim();
      const tokens = tokenizeCSS(rest_of_selector);
      assert(tokens.length <= 2);
      const [token, peek] = tokens;
      console.log(token, peek);
      if (tokens.length === 0) {
        root_rules.forEach(({ name, value }) => {
          rule.style[name] = value;
        });
      } else if (token.is(PseudoElement)) {
        const { rules } = ast.find(
          (node) =>
            node.is(PseudoElementNode) && node.pseudo_element === token.value
        );
        assert(rules.every((node) => node.is(RuleNode)));
        rules.forEach(({ name, value }) => {
          rule.style[name] = value;
        });
      } else if (token.is(PseudoClass)) {
        const { rules } = ast.find(
          (node) =>
            node.is(PseudoSelectorNode) && node.pseudo_class === token.value
        );
        assert(rules.every((node) => node.is(RuleNode)));
        rules.forEach(({ name, value }) => {
          rule.style[name] = value;
        });
      } else if (token.is(Dot) && peek?.is(IdentifierToken)) {
        const { rules } = ast.find(
          (node) => node.is(ClassSelectorNode) && node.value === peek.value
        );
        assert(rules.every((node) => node.is(RuleNode)));
        rules.forEach(({ name, value }) => {
          rule.style[name] = value;
        });
      } else if (token.is(IdentifierToken)) {
        const { rules } = ast.find(
          (node) => node.is(ChildSelectorNode) && node.tag_name == token.value
        );
        assert(rules.every((node) => node.is(RuleNode)));
        rules.forEach(({ name, value }) => {
          rule.style[name] = value;
        });
      } else {
        throw new NotReached();
      }
    }
  }
  create_styles() {
    const { sheet } = this.create_style_sheet();
    const styles = compile_css(this._compute_style(), `.${this.class_name()}`);
    for (let style of styles) {
      sheet.insertRule(style);
    }
  }
  _styles_created = false;
  create_or_replace_styles() {
    if (this._styles_created) {
      this.replace_styles();
    } else {
      this._styles_created = true;
      this.create_styles();
    }
  }
  _compute_style() {
    return this.style(this.props(), this.state(), this.context_value()).to_js();
  }
  has_class_name(elem) {
    return elem.attributes
      .__lookup__(Sym.new("class_name"))
      .nil_q()
      .bang()
      .to_js();
  }
  to_dom() {
    const elem = this.view(this.props(), this.state(), this.context_value());
    if (elem instanceof Element) throw new NotReached();
    if (this.has_class_name(elem)) throw new NotReached();
    this.prev_state = this.state();
    this.prev_props = this.props();
    this.prev_context = this.context_value();
    this.create_or_replace_styles();
    const new_attrs = elem.attributes.insert(
      Sym.new("class"),
      Str.new(this.class_name())
    );
    return DomNode.new(elem.name, new_attrs, elem.children).to_dom();
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
  const elem = ElementClass.new();
  if (elem.title) {
    document.title = elem.title().to_js();
  }
  if (elem.favicon) {
    document
      .getElementById("favicon")
      .setAttribute("href", elem.favicon().to_js());
  }
  node.append(elem.to_dom());
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

// TODO: at some point use this character for printing debug strs ‎
