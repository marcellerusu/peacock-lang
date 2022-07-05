class ArrayLengthMismatch extends Error {}
class MatchError extends Error {}

const fp = {
  zip(first, second) {
    first = Array.from(first);
    second = Array.from(second);
    if (first.length !== second.length) throw new ArrayLengthMismatch();
    return first.map((item, i) => [item, second[i]]);
  },
};

class Any {}

class Else {
  constructor(value) {
    this.value = value;
  }
}

class Case {
  constructor(patterns, value) {
    this.patterns = patterns;
    this.value = value;
  }
}

class Capture {
  constructor(key) {
    this.key = key;
  }
}

class OneOf {
  constructor(patterns) {
    this.patterns = patterns;
  }
}

function s(key) {
  return new Capture(key);
}

function matchCapture(captures, key, value) {
  if (captures.has(key)) {
    return captures.get(key) === value;
  }
  captures.set(key, value);
  return true;
}

function matchObject(pattern, value, captures) {
  if (value.constructor !== Object) return false;
  for (let key in pattern) {
    if (!value[key]) return false;
    if (!match(pattern[key], value[key], captures)) return false;
  }
  return true;
}

function matchRegExp(pattern, value) {
  return pattern.test(value);
}

function matchOneOf(pattern, value) {
  return pattern.patterns.some((p) => match(p, value));
}

function matchFn(patternFn, value) {
  return patternFn(value);
}

function matchInstance(PatternClass, value) {
  return value.constructor === PatternClass;
}

const BUILTIN_CONSTRUCTORS = [
  Boolean,
  String,
  RegExp,
  Symbol,
  Error,
  AggregateError,
  EvalError,
  RangeError,
  ReferenceError,
  URIError,
  SyntaxError,
  TypeError,
  Number,
  BigInt,
  Date,
  Function,
  Array,
  Map,
  Set,
  WeakMap,
  WeakSet,
  Promise,
];

function isPrimitivePattern(pattern) {
  return BUILTIN_CONSTRUCTORS.includes(pattern);
}

function isCustomClass(pattern) {
  return (
    pattern?.prototype?.constructor?.toString()?.substring(0, 5) === "class"
  );
}

function match(pattern, value, captures = new Map()) {
  if (pattern instanceof Any) {
    return true;
  } else if (pattern instanceof Capture) {
    return matchCapture(captures, pattern.key, value);
  } else if (pattern instanceof OneOf) {
    return matchOneOf(pattern, value);
  } else if (pattern instanceof RegExp) {
    return matchRegExp(pattern, value);
  } else if (pattern instanceof Array) {
    return matchArray(pattern, value, captures);
  } else if (pattern.constructor === Object) {
    return matchObject(pattern, value, captures);
  } else if (isPrimitivePattern(pattern) || isCustomClass(pattern)) {
    return matchInstance(pattern, value);
  } else if (typeof pattern === "function") {
    return matchFn(pattern, value);
  } else {
    return pattern === value;
  }
}

function matchArray(pattern, value, captures = new Map()) {
  if (pattern.length !== value.length) return false;
  return fp
    .zip(pattern, value)
    .every(([pattern, value]) => match(pattern, value, captures));
}

s.match =
  (...cases) =>
  (...values) => {
    let match = cases.find((expr) => {
      if (expr instanceof Else) {
        return true;
      } else if (expr instanceof Case) {
        let { patterns } = expr;
        return matchArray(patterns, values.slice(0, patterns.length));
      }
      throw new NotReached();
    });
    if (!match) return;
    return match.value;
  };

s.defn =
  (...cases) =>
  (...args) =>
    s.match(...cases)(...args)?.(...args);

s.any = new Any();

s.verify = (pattern, value) => {
  if (match(pattern, value)) {
    return value;
  } else {
    throw new MatchError();
  }
};

s.else = (value) => new Else(value);

s.oneOf = (...patterns) => new OneOf(patterns);

s.case = (...patterns) => {
  return {
    is: (value) => new Case(patterns, value),
  };
};
