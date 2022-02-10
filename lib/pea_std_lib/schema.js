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
    const literals = [Bool, Int, Float, Str, Sym, Nil];
    if (literals.includes(schema.constructor)) return new LiteralSchema(schema);
    if (typeof schema === "object") return new RecordSchema(schema);
  }

  static case(value, cases) {
    const fn = cases.first((list) => {
      const schema = list.__lookup__(new Int(0));
      const fn = list.__lookup__(new Int(1));
      if (schema.valid_q(value).to_js()) {
        return fn;
      } else {
        return Nil.new();
      }
    });
    if (fn.nil_q().to_js()) throw new MatchError();
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
    if (other instanceof Nil) {
      return Bool.new(false);
    }
    return this.schema_.every((k, v) =>
      other.has_q(k).__and__(v.valid_q(other.__lookup__(k)))
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
