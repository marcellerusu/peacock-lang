class Range {
  #filter_function;
  constructor(from, to, filter = () => true) {
    this.from = from;
    this.to = to;
    this.#filter_function = filter;
  }
  contains(num) {
    return num <= this.to && num >= this.from;
  }
  map(fn) {
    return new Range(fn(this.from), fn(this.to));
  }
  filter(fn) {
    return new Range(this.from, this.to, fn);
  }
  *[Symbol.iterator]() {
    let val = this.from;
    while (val <= this.to) {
      if (this.#filter_function(val)) {
        yield val;
      }
      val = val[Symbol.peacock_next]();
    }
  }
  [Symbol.peacock_equals](other) {
    if (!(other instanceof Range)) return false;
    return this.from === other.from && this.to === other.to;
  }
  [Symbol.peacock_contains](value) {
    return this.contains(value);
  }
}
