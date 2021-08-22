import assert from 'assert';
import { STATEMENT_TYPE } from "./parser.mjs";
import { match, any } from './utils.mjs';

const globals = {
  print: {
    native: console.log
  },
  '+': {
    native: (a, b) => a + b,
  },
  '-': {
    native: (a, b) => a - b,
  },
  '*': {
    native: (a, b) => a * b,
  },
  '/': {
    native: (a, b) => a / b,
  }
};

const evalExpr = (expr, context) => match(expr.type, [
  [STATEMENT_TYPE.NUMBER_LITERAL, () => expr.value],
  [STATEMENT_TYPE.STRING_LITERAL, () => expr.value],
  [STATEMENT_TYPE.SYMBOL_LOOKUP, () => context[expr.symbol].value],
  [STATEMENT_TYPE.FUNCTION, () => expr],
  [STATEMENT_TYPE.FUNCTION_APPLICATION, () => {
    const {paramExprs, symbol} = expr;
    if (context[symbol].native) {
      const nativeFn = context[symbol].native
      const args = [];
      for (const expr of paramExprs) {
        args.push(evalExpr(expr, context));
      }
      return nativeFn(...args);
    }
    const {value: {paramNames, body}} = context[symbol];
    // TODO: implement currying
    assert(paramNames.length === paramExprs.length);
    // TODO: function statements
    assert(body.length === 1);
    const fnContext = {};
    for (let i = 0; i < paramExprs.length; i++) {
      // does this make the language lazy??
      fnContext[paramNames[i]] = paramExprs[i];
    }
    return evalExpr(body[0].expr, {...context, ...fnContext});
  }],
  [STATEMENT_TYPE.OBJECT_LITERAL, () => {
    const {value} = expr;
    const obj = {};
    for (let key in value) {
      obj[key] = evalExpr(value[key], context);
    }
    return obj;
  }],
  [STATEMENT_TYPE.PROPERTY_LOOKUP, () => {
    const {property, expr: _expr} = expr;
    const object = evalExpr(_expr, context);
    return object[property];
  }],
  [any, () => { console.log(expr); throw 'unimplemented -- evalExpr'; }]
])

const interpret = (ast, context = {}, global = {...globals}) => {
  context = {...global};
  assert(ast.type === STATEMENT_TYPE.PROGRAM);
  const lookup = sym => context[sym] || global[sym];
  for (const statement of ast.body) {
    match(statement.type, [
      [STATEMENT_TYPE.DECLARATION, () => {
        const {symbol, mutable, expr} = statement;
        if (lookup(symbol)) {
          console.log(lookup(symbol));
          throw `'${symbol}' has already been declared`;
        }
        context[symbol] = { mutable, value: evalExpr(expr, context), };
      }],
      [STATEMENT_TYPE.ASSIGNMENT, () => {
        const {symbol, expr} = statement;
        const variable = lookup(symbol);
        assert(variable.mutable);
        context[symbol].value = evalExpr(expr, context);
      }],
      [STATEMENT_TYPE.FUNCTION_APPLICATION, () => evalExpr(statement, context)],
      [any, () => {throw 'unimplemented -- interpret ' + statement.type}]
    ]);
  }
  return context;
};

export default interpret;