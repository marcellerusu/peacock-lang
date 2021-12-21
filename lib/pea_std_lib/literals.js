class TypeMismatchError extends Error {}

class Value {
  constructor(value) {
    this.__value = value;
  }
  static create(value) {
    return new this(value);
  }
  to_s() {
    return new Str(this.__value.toString());
  }
  __val__() {
    return this.__value;
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
  to_s() {
    return new Str(`"${this.__value}"`);
  }
  to_i() {
    return new Int(parseInt(this.__value));
  }
  to_f() {
    return new Float(Number(this.__value));
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
    this.__size = Object.keys(value).length;
  }
  __lookup__(index) {
    return this.__value[index.__val__()];
  }
  get size() {
    return new Int(this.__size);
  }
  to_s() {
    let s = new Str("{");
    for (const key in this.__value) {
      s = s.__plus__(
        new Str(` ${key}: ${this.__value[key].to_s().__val__()},`)
      );
    }
    return s.__plus__(new Str(" }"));
  }
}

class List extends Value {
  __lookup__(index) {
    return this.__value[index.__val__()];
  }
  get size() {
    return new Int(this.__value.length);
  }
  to_s() {
    // I'm aware, this is gross lol. It'll be much better once we write it in peacock
    let s = new Str("[");
    s = s.__plus__(
      new Str(this.__value.map((val) => val.to_s().__val__()).join(", "))
    );
    return s.__plus__(new Str("]"));
  }

  __eq__(other) {
    if (this === other) return new Bool(true);
    this.__check_type(other);
  }

  __plus__(other) {
    this.__check_type(other);
    return new List([...this.__value, ...other.__val__()]);
  }

  include__q(other) {
    return new Bool(this.__value.some((val) => val.__eq__(other)));
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
  to_s() {
    return new Str(`:${this.__value.toString().slice(7, -1)}`);
  }
}

module.exports = { Record, List, Str, Sym, Int, Float };
