class Schema {
  // static new_b(schema, value, path) {
  //   if (Schema.for(schema).valid(value)) {
  //     return value
  //   }
  // }
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

  static case(value, cases) {
    const fn = cases.first((list) => {
      const schema = list.__lookup__(new Int(0));
      const fn = list.__lookup__(new Int(1));
      if (schema.valid(value)) {
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
    return this.schema.every(([k, v]) =>
      v.valid(other.__lookup__(Str.create(k)))
    );
  }
}

class ArraySchema extends Schema {
  valid(other) {
    if (!(other instanceof List)) return false;
    return other.size.__val__() === this.schema.length;
  }
}

class FnSchema extends Schema {
  valid(other) {
    return this.schema(other).__val__();
  }
}

class AnySchema extends Schema {
  valid(other) {
    return true;
  }
}

class LiteralSchema extends Schema {
  valid(other) {
    return this.schema.__eq__(other);
  }
}

module.exports = { Schema };
