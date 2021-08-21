import assert from 'assert';
import { STATEMENT_TYPE } from "./parser.mjs";
import { match, any } from './utils.mjs';

const globals = {
  print: {
    mutable: false,
    value: console.log
  }
};

const evalExpr = (expr, context) => match(expr.type, [
  [STATEMENT_TYPE.NUMBER_LITERAL, () => expr.value],
  [STATEMENT_TYPE.SYMBOL_LOOKUP, () => context[expr.symbol].value],
  [STATEMENT_TYPE.FUNCTION, () => expr],
  [STATEMENT_TYPE.FUNCTION_APPLICATION, () => {
    const {paramExprs, symbol} = expr;
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
      obj[key] = evalExpr(value[key]);
    }
    return obj;
  }],
  [any, () => { console.log(expr); throw 'unimplemented -- evalExpr'; }]
])

const interpret = (ast, context = {}, global = {...globals}) => {
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
        context[symbol].value = evalExpr(expr);
      }],
      [any, () => {throw 'unimplemented -- interpret'}]
    ]);
  }
  return context;
};

export default interpret;