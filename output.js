const Immutable = require("immutable");
const M = {
  gt: (a, b) => a > b,
  ls: (a, b) => a < b,
  is: Immutable.is,
  plus: (a, b) => a + b,
  minus: (a, b) => a - b,
  times: (a, b) => a * b,
  divides: (a, b) => a / b,
  isNot: (a, b) => !Immutable.is(a, b),
  List: Immutable.List,
  Map: Immutable.Map,
  any: Symbol("any"),
  matchEq: (a, b) => {
    if (M.is(a, b)) return true;
    if (a === M.any || b === M.any) {
      return true;
    }
    if (typeof a !== typeof b) return false;
    if (Immutable.isList(a) && Immutable.isList(b)) {
      return a.every((x, i) => M.matchEq(x, b.get(i)));
    } else if (Immutable.isMap(a) && Immutable.isMap(b)) {
      return a.every((v, k) => M.matchEq(b.get(k), v));
    } else {
      return false;
    }
  },
};
const print = (...args) => {
  args = args.map((arg) => (arg?.toJS ? arg.toJS() : arg));
  console.log(...args);
};
const obj = M.Map({ a: 1, b: M.Map({ c: "three" }) });

print(
  (() => {
    const matchExpr = obj;

    print(M.matchEq(M.Map({ a: M.any, b: M.any }), matchExpr))
    if (M.matchEq(M.Map({ a: M.any, b: M.any }), matchExpr)) {
      return ((a, b) => {
        return a;
      })(
        ((arg) => {
          return arg.get("a");
        })(obj),
        ((arg) => {
          return arg.get("b");
        })(obj)
      );
    }
  })()
);
