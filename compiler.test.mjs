import parse from './parser.mjs';
import tokenize from './tokenizer.mjs';
import { eq } from './utils.mjs';
import assert from 'assert';
import compile from './compiler.mjs';

let passed = 0;
const it = (str, fn) => {
  console.log(`it - ${str}`);
  fn();
  passed++;
}

it('should compile number declaration', () => {
  const program = parse(tokenize(`
  let a = 3;
  `))
  const js = compile(program);
  assert(eq(js.trim(), `const a = 3;`))
});

it('should compile string declaration', () => {
  const program = parse(tokenize(`
  let a = 'string';
  `))
  const js = compile(program);
  assert(eq(js.trim(), `const a = 'string';`))
});

it('should compile mutable', () => {
  const program = parse(tokenize(`
  let mut a = 'string';
  `))
  const js = compile(program);
  assert(eq(js.trim(), `let a = 'string';`))
});

it('should compile array declaration', () => {
  const program = parse(tokenize(`
  let a = [1, 2, 3];
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(js.trim(), `const a = List([1, 2, 3]);`))
});

it('should compile object declaration', () => {
  const program = parse(tokenize(`
  let a = {
    obj: 3,
  };
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const a = Map({ obj: 3, });`))
});

it('should compile property lookup', () => {
  const program = parse(tokenize(`
  let a = obj.name;
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const a = obj.get('name');`))
});

it('should compile dynamic property lookup', () => {
  const program = parse(tokenize(`
  let a = obj['name oh'];
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const a = obj.get('name oh');`))
});

it('should compile dynamic property lookup number', () => {
  const program = parse(tokenize(`
  let a = obj[3];
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const a = obj.get(3);`))
});

it('should compile property lookup on object', () => {
  const program = parse(tokenize(`
  let a = { name: 'Marcelle' }.name;
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const a = Map({ name: 'Marcelle', }).get('name');`))
});

it('should compile function no params return number', () => {
  const program = parse(tokenize(`
  let f = () => 3;
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const f = (() => {\nreturn 3;\n});`))
});

it('should compile function no params return string', () => {
  const program = parse(tokenize(`
  let f = () => 'string';
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const f = (() => {\nreturn 'string';\n});`))
});

it('should compile function no params return array', () => {
  const program = parse(tokenize(`
  let f = () => ['string', 1];
  `))
  const js = compile(program);
  // console.log(js);
  assert(eq(
    js.trim(),
    `const f = (() => {\nreturn List(['string', 1]);\n});`))
});

it('should compile function no params return object', () => {
  const program = parse(tokenize(`
  let f = () => {
    return { 'string oh': 3 };
  };
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const f = (() => {\nreturn Map({ 'string oh': 3, });\n});`))
});

it('should compile identity function', () => {
  const program = parse(tokenize(`
  let f = (x) => x;
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const f = ((x) => {\nreturn x;\n});`))
});

it('should compile multi-statement function', () => {
  const program = parse(tokenize(`
  let f = (x) => {
    let b = 3;
    return b;
  };
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const f = ((x) => {\nconst b = 3;\nreturn b;\n});`))
});

it('should compile function call', () => {
  const program = parse(tokenize(`
  let a = f(10);
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const a = f(10);`))
});

it('should compile function call with string', () => {
  const program = parse(tokenize(`
  let a = f('string');
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const a = f('string');`))
});

it('should compile function call with object', () => {
  const program = parse(tokenize(`
  let a = f({ a: 3 });
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.trim(),
    `const a = f(Map({ a: 3, }));`))
});

it('should compile if expressions', () => {
  const program = parse(tokenize(`
  let a = if (2 > 1) 3;
  `))
  const js = compile(program);
  // console.log(js)
  // TODO: if expressions don't need to have lambdas for each clause anymore
  assert(eq(
    js.replace(/ +?|\n/g, ''),
    `const a = (() => {
      if (M.gt(2, 1)) {
        (() => { return 3; })()
      } else {
        (() => { })()
      }
    })();`.replace(/ +?|\n/g, '')))
});


it('should compile match expressions', () => {
  const program = parse(tokenize(`
  let a = match (['hello']) {
    [a] => a + ' world!'
  };
  `))
  const js = compile(program);
  // console.log(js)
  assert(eq(
    js.replace(/ +?|\n/g, ''),
    `const a = (() => {
      const matchExpr = List(['hello']);
      if (M.matchEq(List([any]), matchExpr)) {
        return ((a) => {
          return M.plus(a, ' world!');
        })(((arg) => {
          return arg.get(0);
        })(List(['hello'])));
      }
    })();`.replace(/ +?|\n/g, '')))
});

console.log('Passed', passed, 'tests!');
