class Range {
  #filter_function;
  constructor(from, to, filter = () => true) {
    console.assert(typeof from === "number", "From should be a number");
    console.assert(typeof to === "number", "To should be a number");
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
    let num = this.from;
    while (num <= this.to) {
      if (this.#filter_function(num)) {
        yield num;
      }
      num++;
    }
  }
  [Symbol.peacock_equals](other) {
    if (!(other instanceof Range)) return false;
    return this.from === other.from && this.to === other.to;
  }
  [Symbol.peacock_contains](other) {
    for (let value of this) {
      if (value[Symbol.peacock_equals](other)) {
        return true;
      }
    }
    return false;
  }
}
