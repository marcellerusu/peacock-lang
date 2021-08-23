import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let f = () => {
  let a = 3;
  return a + 3;
};
let c = f();
`;

const global = interpret(parse(tokenize(program)));
// console.log(JSON.stringify(global, null, 2));
