import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let expr = match ([1, 2]) {
  [] => 'Congrats... sorta',
  [1] => 'Oh no',
  [1, a] => 'YES! ' + a
};
print(expr);
`;

const global = interpret(parse(tokenize(program)));
// console.log(JSON.stringify(global, null, 2));
