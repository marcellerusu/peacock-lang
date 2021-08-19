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
  [STATEMENT_TYPE.FUNCTION, () => {
    const {paramNames, body} = expr;
    assert(paramNames.length === 0);
    assert(body.length === 1);
    const [ret] = body;
    assert(ret.type === STATEMENT_TYPE.RETURN);
    const val = evalExpr(ret.expr, context);
    return () => val;
  }],
  [STATEMENT_TYPE.FUNCTION_APPLICATION, () => {
    const {paramNames, symbol} = expr;
    assert(paramNames.length === 0);
    return context[symbol].value();
  }],
  [STATEMENT_TYPE.OBJECT_LITERAL, () => {
    const {value} = expr;
    const obj = {};
    for (let key in value) {
      obj[key] = evalExpr(value[key]);
    }
    return obj;
  }],
  [any, () => { throw 'unimplemented -- evalExpr'; }]
])

const interpret = (ast, context = {...globals}) => {
  assert(ast.type === STATEMENT_TYPE.PROGRAM);
  for (const statement of ast.body) {
    switch (statement.type) {
      case STATEMENT_TYPE.DECLARATION:
        const {symbol, mutable, expr} = statement;
        if (context[symbol]) {
          console.log(context);
          throw `'${symbol}' has already been declared`;
        }
        context[symbol] = { mutable, value: evalExpr(expr, context), };
        break;
      default:
        throw 'unimplemented -- interpret'
    }
  }
  return context;
};

export default interpret;