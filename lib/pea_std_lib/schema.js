const allEntries = (obj) => Reflect.ownKeys(obj).map((k) => [k, obj[k]]);

class Schema {
  static for(schema) {
    if (schema instanceof Schema) return schema;
    if (schema instanceof List) return new ListSchema(schema);
    if (schema instanceof Array) return new ListSchema(schema);
    if (schema instanceof Function) return new FnSchema(schema);
    if (schema instanceof Record) return new RecordSchema(schema.__val__());
    if (schema === undefined) return new AnySchema();
    // TODO: this should be more specific
    const literals = [Bool, Int, Float, Str, Sym];
    if (literals.includes(schema.constructor)) return new LiteralSchema(schema);
    if (typeof schema === "object") return new RecordSchema(schema);
  }

  static create_with_constructor(schema, construct) {
    schema = Schema.for(schema);
    schema.construct = construct;
    return schema;
  }

  static case(value, cases) {
    const fn = cases.first((list) => {
      const schema = list.__lookup__(new Int(0));
      const fn = list.__lookup__(new Int(1));
      if (schema.valid_q(value)) {
        return fn;
      }
    });
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
    return new AnySchema(name.__val__());
  }

  static literal(value) {
    return new LiteralSchema(value);
  }

  constructor(schema) {
    this.schema_ = schema;
    this.construct = (x) => x;
  }

  valid_q(other) {
    throw null;
  }
}

class OrSchema extends Schema {
  constructor(...schema) {
    super(schema.map(Schema.for));
  }
  valid_q(other) {
    other = this.construct(other);
    return this.schema_.some((s) => s.valid_q(other));
  }
}

class AndSchema extends Schema {
  constructor(...schema) {
    super(schema.map(Schema.for));
  }
  valid_q(other) {
    other = this.construct(other);
    return this.schema_.every((s) => s.valid_q(other));
  }
}

class RecordSchema extends Schema {
  constructor(schema) {
    super(allEntries(schema).map(([k, v]) => [k, Schema.for(v)]));
  }

  combine(other) {
    let newSchema = Object.fromEntries(this.schema_);
    for (let [k, v] of other.schema_) {
      newSchema[k] = v;
    }
    return new RecordSchema(newSchema);
  }

  valid_q(other) {
    other = this.construct(other);
    return this.schema_.every(
      ([k, v]) =>
        other.has_q(Sym.create(k)).__val__() &&
        v.valid_q(other.__lookup__(Sym.create(k)))
    );
  }
}

class ListSchema extends Schema {
  constructor(value) {
    if (value instanceof Array) {
      value = List.create(value);
    }
    value = value.map(Schema.for);
    super(value);
  }
  valid_q(other) {
    other = this.construct(other);
    if (!(other instanceof List)) return false;
    const otherSize = other.size.__val__();
    if (this.schema_ instanceof List) {
      return (
        otherSize === this.schema_.size.__val__() &&
        this.schema_
          .every((s, i) => Bool.create(s.valid_q(other.__lookup__(new Int(i)))))
          .__val__()
      );
    } else if (this.schema_ instanceof Array) {
      return otherSize === this.schema_.length;
    }
    throw "ASSERT_NOT_REACHED";
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
    other = this.construct(other);
    return this.schema_(other).__val__();
  }
}

class AnySchema extends Schema {
  valid_q(other) {
    return true;
  }
}

class LiteralSchema extends Schema {
  valid_q(other) {
    other = this.construct(other);
    return this.schema_.__eq__(other).__val__();
  }
}

module.exports = { Schema };
