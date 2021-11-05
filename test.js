const Peacock = {
  plus: (a, b) => a + b,
};
const print = (...params) => console.log(...params);
const add = (...params) => {
  const functions = [
    (a, b) => {
      return Peacock.plus(a, b);
    },
    (a) => {
      return add(a, 3);
    },
  ];
  const f_by_length = functions.find((f) => f.length === params.length);
  if (f_by_length) return f_by_length(...params);
};
