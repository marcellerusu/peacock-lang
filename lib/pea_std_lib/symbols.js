Symbol.peacock_contains = Symbol("peacock_contains");
Symbol.peacock_equals = Symbol("peacock_equals");

Object.prototype[Symbol.peacock_equals] = function (other) {
  return this === other;
};
