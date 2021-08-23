import parse, { STATEMENT_TYPE } from './parser.mjs';
import tokenize from './tokenizer.mjs';
import { eq } from './utils.mjs';
import assert from 'assert';
import interpret from './interpreter.mjs';

let passed = 0;
const it = (str, fn) => {
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

  const globals = interpret(ast);
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

  const globals = interpret(ast);
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
  const globals = interpret(ast);
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

  const globals = interpret(ast);
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
  const globals = interpret(ast);
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
  const global = interpret(ast);
  assert(global['var'].value === 3)
  assert(global['var'].mutable)
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
  const global = interpret(ast);
  // console.log(global)

  assert(global['var'].value === 3)
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
  const global = interpret(ast);
  // console.log(global);

  assert(global['var'].value === 12345);
});


it(`should eval function application with arguments`, () => {
  const ast = parse(tokenize(`
  let add = (a, b) => a + b;
  let four = add(1, 3);
  `));
  const global = interpret(ast);

  // console.log(global.four);

  assert(global.four.value === 4)
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
  const global = interpret(ast);
  // console.log(global);
  assert(global.yesa.value === 5);
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
  const global = interpret(ast);
  assert(global.b.value === 5);
});

it('should eval curried a + b', () => {
  const program = parse(tokenize(`
  let f = (a) => (b) => a + b;
  let h = f(1);
  let g = h(2);
  `));
  const global = interpret(program);

  assert(global.g.value === 3)
});


it('should eval directly curried a + b', () => {
  const program = parse(tokenize(`
  let f = (a) => (b) => a + b;
  let h = f(1)(2);
  `));
  const global = interpret(program);

  assert(global.h.value === 3)
});

it('should eval arr', () => {
  const program = parse(tokenize(`
  let arr = [1, 'str', {a: 3}];  
  `));
  const global = interpret(program);
  assert(eq(global.arr.value, [1, 'str', {a: 3}]))
})

it('should eval multi-statement functions', () => {
  const program = parse(tokenize( `
  let f = () => {
    let a = 3;
    return a + 3;
  };
  let c = f();
  `));
  const global = interpret(program);
  assert(eq(global.c.value, 6))
})

console.log('Passed', passed, 'tests!');
