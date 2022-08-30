Symbol.peacock_contains = Symbol("peacock_contains");
Symbol.peacock_equals = Symbol("peacock_equals");
Symbol.peacock_next = Symbol("peacock_next");

Number.prototype[Symbol.peacock_next] = function () {
  return this + 1;
};

String.prototype[Symbol.peacock_next] = function () {
  return String.fromCharCode(this.charCodeAt(0) + 1);
};

BigInt.prototype[Symbol.peacock_next] = function () {
  return this + 1;
};

Number.prototype[Symbol.peacock_equals] = function (other) {
  return this === other;
};

String.prototype[Symbol.peacock_equals] = function (other) {
  return this === other;
};

BigInt.prototype[Symbol.peacock_equals] = function (other) {
  return this === other;
};

Boolean.prototype[Symbol.peacock_equals] = function (other) {
  return this === other;
};

Date.prototype[Symbol.peacock_equals] = function (other) {
  if (!(other instanceof Date)) return false;
  return this.valueOf() === other.valueOf();
};

RegExp.prototype[Symbol.peacock_equals] = function (other) {
  return this.source === other.source;
};

Set.prototype[Symbol.peacock_contains] = function (val) {
  if (this.has(val)) return true;
  return Array.from(this).some((v) => v[Symbol.peacock_equals](val));
};

Set.prototype[Symbol.peacock_equals] = function (other) {
  if (!(other instanceof Set)) return false;
  if (other.size !== this.size) return false;
  let entries;

  for (let val of this) {
    if (other.has(val)) continue;
    entries ||= Array.from(other);
    if (!entries.some((v) => v === val || v[Symbol.peacock_equals](val)))
      return false;
  }
  return true;
};

Array.prototype[Symbol.peacock_equals] = function (other) {
  if (!(other instanceof Array)) return false;
  if (this.length !== other.length) return false;
  for (let i = 0; i < this.length; i++) {
    if (this[i] === other[i]) continue;
    if (!this[i][Symbol.peacock_equals](other[i])) return false;
  }
  return true;
};

Array.prototype[Symbol.peacock_contains] = function (value) {
  if (this.includes(value)) return true;
  for (let _value of this) {
    if (_value === value) return true;
    if (_value[Symbol.peacock_equals](value)) return true;
  }
  return false;
};

Map.prototype[Symbol.peacock_equals] = function (other) {
  if (!(other instanceof Map)) return false;
  if (this.size !== other.size) return false;
  for (let [key, value] of this) {
    if (!other.has(key)) return false;
    let _value = other.get(key);
    if (_value === value) continue;
    if (!_value[Symbol.peacock_equals](value)) return false;
  }
  return true;
};

Map.prototype[Symbol.peacock_contains] = function ([key, value]) {
  if (!this.has(key)) return false;
  let _value = this.get(key);
  return _value === value || _value[Symbol.peacock_equals](value);
};

Object.prototype[Symbol.peacock_equals] = function (other) {
  if (Object.keys(this).length !== Object.keys(other).length) return false;
  for (let [key, value] of Object.entries(this)) {
    if (!other[key]) return false;
    if (other[key] === value) continue;
    if (!other[key][Symbol.peacock_equals](value)) return false;
  }
  return true;
};
