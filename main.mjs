import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let f = () => {
  return { x: 1 + 3 };
};
let c = f();
print(f().x);
`;

const global = interpret(parse(tokenize(program)));