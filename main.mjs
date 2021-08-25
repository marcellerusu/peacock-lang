import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";
import fs from 'fs/promises';

const path = process.argv[2];
const data = await fs.readFile(path, 'utf-8');
// console.log(data);

const global = interpret(parse(tokenize(data)));
// console.log(JSON.stringify(global, null, 2));
