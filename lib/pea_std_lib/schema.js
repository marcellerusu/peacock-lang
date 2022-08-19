class ArrayLengthMismatch extends Error {}
class MatchError extends Error {}

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

class Any {}

class Capture {
  constructor(key) {
    this.key = key;
  }
}

class Union {
  constructor(patterns) {
    this.patterns = patterns;
  }
}

function s(key) {
  return new Capture(key);
}

s.checkCapture = function checkCapture(captures, key, value) {
  if (captures.has(key)) {
    return captures.get(key) === value;
  }
  captures.set(key, value);
  return true;
};

s.checkObject = function checkObject(pattern, value, captures) {
  if (value.constructor !== Object) return false;
  for (let key in pattern) {
    if (typeof value[key] === "undefined") return false;
    if (!s.check(pattern[key], value[key], captures)) return false;
  }
  return true;
};

s.checkRegExp = function checkRegExp(pattern, value) {
  return pattern.test(value);
};

s.checkUnion = function checkUnion({ patterns }, value) {
  return patterns.some((p) => s.check(p, value));
};

s.checkFn = function checkFn(patternFn, value) {
  return patternFn(value);
};

s.checkInstance = function checkInstance(PatternClass, value) {
  return value.constructor === PatternClass;
};

function _zip(otherArray) {
  return this.map((x, i) => [x, otherArray[i]]);
}

s.checkArray = function checkArray(patternArr, valueArr, captures = new Map()) {
  if (patternArr.length !== valueArr.length) return false;
  for (let [pattern, value] of _zip.call(patternArr, valueArr)) {
    if (!s.check(pattern, value, captures)) return false;
  }
  return true;
};

s.any = new Any();

s.check = function check(pattern, value, captures = new Map()) {
  if (pattern instanceof Any) {
    return true;
  } else if (pattern === null) {
    return value === null;
  } else if (pattern instanceof Capture) {
    return s.checkCapture(captures, pattern.key, value);
  } else if (pattern instanceof Union) {
    return s.checkUnion(pattern, value);
  } else if (pattern instanceof RegExp) {
    return s.checkRegExp(pattern, value);
  } else if (pattern instanceof Array) {
    return s.checkArray(pattern, value, captures);
  } else if (pattern.constructor === Object) {
    return s.checkObject(pattern, value, captures);
  } else if (isPrimitivePattern(pattern) || isCustomClass(pattern)) {
    return s.checkInstance(pattern, value);
  } else if (typeof pattern === "function") {
    return s.checkFn(pattern, value);
  } else {
    return pattern === value;
  }
};

s.verify = function verify(pattern, value, pattern_name = "RIP") {
  if (s.check(pattern, value)) {
    return value;
  } else {
    throw new MatchError(
      `
  Match Error!
  > '${value}' could not conform to '${pattern_name}'
`
    );
  }
};

s.union = (...patterns) => new Union(patterns);
