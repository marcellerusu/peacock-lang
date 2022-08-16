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
    return new Range(fn(from), fn(to));
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
}
