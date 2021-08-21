import { STATEMENT_TYPE } from './parser.mjs';
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

  assert(eq(globals['var'], {
    mutable: false,
    value: 3
  }));
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

  assert(typeof globals['function'].value === 'function');
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
          paramNames: [],
          symbol: 'function'
        }
      },
    ]
  };
  const globals = interpret(ast);

  assert(typeof globals['function'].value === 'function');
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

  assert(eq(globals['obj'].value, {
    a: 3,
    yesa: 5
  }));
})


it('should eval function application with variable lookup', () => {
  const ast = {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'x',
        expr: {
          type: STATEMENT_TYPE.NUMBER_LITERAL,
          value: 5
        }
      },
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
        symbol: 'a',
        expr: {
          type: STATEMENT_TYPE.FUNCTION_APPLICATION,
          paramNames: [],
          symbol: 'function'
        }
      },
    ]
  };
  const globals = interpret(ast);

  assert(typeof globals['function'].value === 'function');
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

console.log('Passed', passed, 'tests!');
