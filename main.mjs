import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let arr = [1, 2, 3];
let three = arr[2];
print(three);
`;

interpret(parse(tokenize(program)));
// console.log(JSON.stringify(global, null, 2));
