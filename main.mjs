import compile from './compiler.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";
import fs from 'fs/promises';

const path = process.argv[2];
const data = await fs.readFile(path, 'utf-8');
// console.log(data);

const global = await compile(parse(tokenize(data)));
console.log(global);
// console.log(JSON.stringify(global.toJS(), null, 2));
