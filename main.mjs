import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let str = if (3 != 3) {
  return 5;
} else {
  return 'strrr';
};
print(str);
`;

interpret(parse(tokenize(program)));
// console.log(JSON.stringify(global, null, 2));
