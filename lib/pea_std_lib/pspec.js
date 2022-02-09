class Expect {
  constructor(test_value) {
    this.test_value = test_value;
  }
  static ["new"](...params) {
    return new this(...params);
  }
  to(result) {
    return result.test(this.test_value);
  }
}
class ExpectResult {
  constructor(test_value) {
    this.test_value = test_value;
  }
  static ["new"](...params) {
    return new this(...params);
  }
  test(value) {
    return this.test_value.__eq__(value);
  }
}

const eq = (val) => {
  return ExpectResult.new(val);
};

const expect = (val) => {
  return Expect.new(val);
};

class SpecContext {
  tests = [];
  test_fn;
  constructor(parent_name) {
    this.parent_name = parent_name;
  }
  static ["new"](...params) {
    return new this(...params);
  }
  it(test_name, test_fn) {
    this.tests.push({ test_name, test_fn });
  }
  run_tests() {
    for (const { test_name, test_fn } of this.tests) {
      const test_str = this.parent_name
        .__plus__(Str.new(" "))
        .__plus__(test_name)
        .to_js();
      const result = test_fn();
      if (result.to_js()) {
        console.log(".".green);
      } else {
        console.log(test_str.red);
      }
    }
  }
}

class Spec {
  constructor(name, context_fn) {
    this.name = name;
    this.context_fn = context_fn;
    this.run();
  }
  static ["new"](...params) {
    return new this(...params);
  }

  run() {
    let context = SpecContext.new(this.name);
    this.context_fn(context);
    context.run_tests();
  }
}
