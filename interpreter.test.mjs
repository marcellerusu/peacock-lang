import parse, { STATEMENT_TYPE } from './parser.mjs';
import tokenize from './tokenizer.mjs';
import { eq } from './utils.mjs';
import assert from 'assert';
import interpret, { globals, refreshGlobals } from './interpreter.mjs';

let passed = 0;
const it = (str, fn) => {
  refreshGlobals();
  console.log(`it - ${str}`);
  fn();
  passed++;
}

it('should eval `let var = 3;`', () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        symbol: 'var',
        mutable: false,
        expr: {
          type: STATEMENT_TYPE.NUMBER_LITERAL,
          value: 3
        }
      },
    ]
  }

  interpret(ast);
  // console.log(globals);

  assert(globals['var'].value === 3);
});

it('should eval function', () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'function',
        expr: {
          type: STATEMENT_TYPE.FUNCTION,
          paramNames: [],
          body: [
            {
              type: STATEMENT_TYPE.RETURN,
              expr: {
                type: STATEMENT_TYPE.NUMBER_LITERAL,
                value: 3
              }
            }
          ]
        }
      },
    ]
  };

  interpret(ast);
  // console.log(globals['function'])
  assert(eq(globals['function'], {
    mutable: false,
    value: {
      type: STATEMENT_TYPE.FUNCTION,
      paramNames: [],
      closureContext: {},
      body: [
        {
          type: STATEMENT_TYPE.RETURN,
          expr: {
            type: STATEMENT_TYPE.NUMBER_LITERAL,
            value: 3
          }
        }
      ]
    }
  }));
})

it('should eval function application', () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'function',
        expr: {
          type: STATEMENT_TYPE.FUNCTION,
          paramNames: [],
          body: [
            {
              type: STATEMENT_TYPE.RETURN,
              expr: {
                type: STATEMENT_TYPE.NUMBER_LITERAL,
                value: 3
              }
            }
          ]
        }
      },
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'a',
        expr: {
          type: STATEMENT_TYPE.FUNCTION_APPLICATION,
          paramExprs: [],
          expr: {
            type: STATEMENT_TYPE.SYMBOL_LOOKUP,  
            symbol: 'function'
          }
        }
      },
    ]
  };
  interpret(ast);
  // console.log(globals);

  assert(globals['a'].value === 3);
})


it('should eval object literals', () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'obj',
        expr: {
          type: STATEMENT_TYPE.OBJECT_LITERAL,
          value: {
            a: {
              type: STATEMENT_TYPE.NUMBER_LITERAL,
              value: 3
            },
            yesa: {
              type: STATEMENT_TYPE.NUMBER_LITERAL,
              value: 5
            }
          }
        }
      }
    ]
  };

  interpret(ast);
  // console.log(globals.obj);


  assert(eq(globals['obj'].value, {
    a: 3,
    yesa: 5
  }));
})


it('should eval function application with variable lookup', () => {
  const ast = parse(tokenize(`
  let x = 5;
  let function = () => x;
  let a = function();
  `));
  interpret(ast);
  // console.log(globals);

  // assert(typeof globals['function'].value === 'function');
  assert(globals['a'].value === 5);
});

it(`should eval mutable variable`, () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: true,
        symbol: 'var',
        expr: {
          type: STATEMENT_TYPE.NUMBER_LITERAL,
          value: 3
        }
      },
    ]
  };
  interpret(ast);
  assert(globals['var'].value === 3)
  assert(globals['var'].mutable)
});

it(`should eval variable assignment`, () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: true,
        symbol: 'var',
        expr: {
          type: STATEMENT_TYPE.NUMBER_LITERAL,
          value: 5
        }
      },
      {
        type: STATEMENT_TYPE.ASSIGNMENT,
        symbol: 'var',
        expr: {
          type: STATEMENT_TYPE.NUMBER_LITERAL,
          value: 3
        }
      },
    ]
  };
  interpret(ast);
  // console.log(global)

  assert(globals['var'].value === 3)
});

it(`should eval identity function`, () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'id',
        expr: {
          type: STATEMENT_TYPE.FUNCTION,
          paramNames: ['x'],
          body: [ 
            {
              type: STATEMENT_TYPE.RETURN,
              expr: {
                type: STATEMENT_TYPE.SYMBOL_LOOKUP,
                symbol: 'x'
              }
            }
          ]
        }
      },
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'var',
        expr: {
          type: STATEMENT_TYPE.FUNCTION_APPLICATION,
          expr: {
            type: STATEMENT_TYPE.SYMBOL_LOOKUP,  
            symbol: 'id'
          },
          paramExprs: [
            {
              type: STATEMENT_TYPE.NUMBER_LITERAL,
              value: 12345
            }
          ]
        }
      }
    ]
  };
  interpret(ast);
  // console.log(global);

  assert(globals['var'].value === 12345);
});


it(`should eval function application with arguments`, () => {
  const ast = parse(tokenize(`
  let add = (a, b) => a + b;
  let four = add(1, 3);
  `));
  interpret(ast);

  // console.log(global.four);

  assert(globals.four.value === 4)
});

it(`should eval object dot notation on object`, () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'yesa',
        expr: {
          type: STATEMENT_TYPE.PROPERTY_LOOKUP,
          property: 'yesa',
          expr: {
            type: STATEMENT_TYPE.OBJECT_LITERAL,
            value: {
              a: {
                type: STATEMENT_TYPE.NUMBER_LITERAL,
                value: 3
              },
              yesa: {
                type: STATEMENT_TYPE.NUMBER_LITERAL,
                value: 5
              }
            }
          },
        }
      }
    ]
  };
  interpret(ast);
  // console.log(global);
  assert(globals.yesa.value === 5);
});

it(`should eval nested object dot notation on variable`, () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'obj',
        expr: {
          type: STATEMENT_TYPE.OBJECT_LITERAL,
          value: {
            a: {
              type: STATEMENT_TYPE.OBJECT_LITERAL,
              value: {
                b: {
                  type: STATEMENT_TYPE.NUMBER_LITERAL,
                  value: 5
                }
              }
            }
          }
        }
      },
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,  
        symbol: 'b',
        expr: {
          type: STATEMENT_TYPE.PROPERTY_LOOKUP,
          expr: {
            type: STATEMENT_TYPE.PROPERTY_LOOKUP,
            expr: {
              type: STATEMENT_TYPE.SYMBOL_LOOKUP,
              symbol: 'obj',
            },
            property: 'a',
          },
          property: 'b',
        }
      }
    ]
  };
  interpret(ast);
  assert(globals.b.value === 5);
});

it('should eval curried a + b', () => {
  const program = parse(tokenize(`
  let f = (a) => (b) => a + b;
  let h = f(1);
  let g = h(2);
  `));
  interpret(program);

  assert(globals.g.value === 3)
});


it('should eval directly curried a + b', () => {
  const program = parse(tokenize(`
  let f = (a) => (b) => a + b;
  let h = f(1)(2);
  `));
  interpret(program);

  assert(globals.h.value === 3)
});

it('should eval arr', () => {
  const program = parse(tokenize(`
  let arr = [1, 'str', {a: 3}];  
  `));
  interpret(program);
  assert(eq(globals.arr.value, [1, 'str', {a: 3}]))
})

it('should eval multi-statement functions', () => {
  const program = parse(tokenize( `
  let f = () => {
    let a = 3;
    return a + 3;
  };
  let c = f();
  `));
  interpret(program);
  assert(eq(globals.c.value, 6))
});

it('should eval if cond', () => {
  const program = parse(tokenize(`
  let five = if (3 == 3) {
    return 5;
  };
  `));
  interpret(program);
  // console.log(global.five);
  assert(globals.five.value === 5);
});

it('should eval if else cond', () => {
  const program = parse(tokenize(`
  let str = if (3 != 3) {
    return 5;
  } else {
    return 'str';
  };
  `));
  interpret(program);
  // console.log(global.five);
  assert(globals.str.value === 'str');
});

it('should eval if elif else cond', () => {
  const program = parse(tokenize(`
  let a = '3';
  let f = if (a == 3) {
    return 5;
  } elif (a == '3') {
    return 'str';
  };
  `));
  interpret(program);
  // console.log(globals);
  assert(globals.f.value === 'str');
});

it('should eval array lookup on symbol', () => {
  const program = parse(tokenize(`
  let arr = [1, 2, 3];
  let three = arr[2];
  `));
  interpret(program);
  assert(globals.three.value === 3);
});

it('should eval pattern matching', () => {
  const program = parse(tokenize(`
  let wtf = match ([1, 2]) {
    [a] => a,
    [a, 2] => 'wtf'
  };
  `));
  interpret(program);
  assert(globals.wtf.value === 'wtf');
})


it('should eval pattern matching w bound variable not first', () => {
  const program = parse(tokenize(`
  let wtf = match ([1, 2]) {
    [a] => a,
    [1, a] => 'wtf'
  };
  `));
  interpret(program);
  assert(globals.wtf.value === 'wtf');
})

it('should eval pattern matching w bound variable not first 2', () => {
  const program = parse(tokenize(`
  let wtf = match ([1, 2]) {
    [1, a] => 'wtf'
  };
  `));
  interpret(program);
  assert(globals.wtf.value === 'wtf');
})


it('should eval pattern matching w bound variable not first 3', () => {
  const program = parse(tokenize(`
  let wtf = match ([1, 2]) {
    [1, a] => a
  };
  `));
  interpret(program);
  // console.log(JSON.stringify(program, null, 2));
  assert(globals.wtf.value === 2);
})

console.log('Passed', passed, 'tests!');
