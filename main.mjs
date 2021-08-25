import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `

let mult = (x) => match(x) {
  [x] => x,
  [a, b] => a * b,
  [a, b, c] => a * b * c
};

let arr = [1, 2, 3];
let expr = match (arr) {
  [] => 'Congrats... sorta',
  [1] => 'Oh no',
  [1, a] => 'YES! ' + a
};
print(mult(arr));
`;

const global = interpret(parse(tokenize(program)));
// console.log(JSON.stringify(global, null, 2));
