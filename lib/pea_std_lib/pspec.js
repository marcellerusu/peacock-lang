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
  xit(test_name, test_fn) {
    this.tests.push({ ignored: true, test_name, test_fn });
  }
  run_tests() {
    for (const { test_name, test_fn, ignored } of this.tests) {
      if (ignored) {
        process.stdout.write(".".yellow);
        continue;
      }
      const test_str = this.parent_name
        .__plus__(Str.new(" "))
        .__plus__(test_name)
        .to_js();
      let result;
      try {
        result = test_fn();
        if (result.nil_q().to_js()) result = Bool.new(true);
      } catch (e) {
        console.error(e);
        result = Bool.new(false);
      }
      if (result.to_js()) {
        process.stdout.write(".".green);
      } else {
        console.log(test_str.red);
      }
    }
  }
}

class Spec {
  constructor(name, context_fn) {
    if (typeof name === "function") name = Str.new(name.name);
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
