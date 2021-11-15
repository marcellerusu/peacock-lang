class Schema {
  static for(schema) {
    if (schema instanceof Schema) return schema;
    if (schema instanceof Array) return new OrSchema(...schema);
    if (schema === undefined) return new AnySchema();
    // TODO: this should be more specific
    if (typeof schema === "object") return new RecordSchema(schema);
    const literals = ["boolean", "number", "string", "symbol"];
    if (literals.includes(typeof schema)) return new LiteralSchema(schema);
  }

  constructor(schema) {
    this.schema = schema;
  }

  valid(other) {}
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

  valid(other) {
    return this.schema.every(
      ([k, v]) => typeof other[k] !== "undefined" && v.valid(other[k])
    );
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

// const Bool = Schema.for([true, false]);

// const S = Schema.for({ id: Schema.for(), email: Schema.for() });

// console.log(S.valid({ id: 23, email: "email@.com" }));

// module.exports = Schema;
