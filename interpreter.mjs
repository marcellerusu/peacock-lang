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

const evalParamExprs = (paramExprs, context, closureContext) => {
  const args = [];
  for (const expr of paramExprs) {
    const val = evalExpr(expr, context, closureContext);
    assert(typeof val.value !== 'undefined');
    args.push(val.value);
  }
  return args;
};

const evalExpr = (expr, context, closureContext = {}) => match(expr.type, [
  [STATEMENT_TYPE.NUMBER_LITERAL, () => expr],
  [STATEMENT_TYPE.STRING_LITERAL, () => expr],
  [STATEMENT_TYPE.RETURN, () => evalExpr(expr.expr, context, closureContext)],
  [STATEMENT_TYPE.SYMBOL_LOOKUP, () => closureContext[expr.symbol] || context[expr.symbol]],
  [STATEMENT_TYPE.FUNCTION, () => ({ value: { ...expr, closureContext } })],
  [STATEMENT_TYPE.FUNCTION_APPLICATION, () => {
    const { paramExprs, expr: fnExpr } = expr;
    const fn = evalExpr(fnExpr, context, closureContext);
    if (typeof fn.native !== 'undefined') {
      const args = evalParamExprs(paramExprs, context, closureContext);
      return { value: fn.native(...args) };
    }
    assert(typeof fn.value !== 'undefined');
    const { paramNames, body, closureContext: oldClosureContext } = fn.value;
    // TODO: implement currying
    assert(paramNames.length === paramExprs.length);
    const fnContext = { ...oldClosureContext };
    for (let i = 0; i < paramExprs.length; i++) {
      // TODO: this should be in parsing phase + use evalParamExprs
      if (closureContext[paramNames[i]]) throw `no duplicate param names`;
      fnContext[paramNames[i]] = {
        mutable: false,
        ...evalExpr(paramExprs[i], context, closureContext)
      };
    }
    return interpret(
      { body, type: STATEMENT_TYPE.FUNCTION },
      context,
      fnContext
    );
  }],
  [STATEMENT_TYPE.OBJECT_LITERAL, () => {
    const obj = {};
    for (let key in expr.value) {
      obj[key] = evalExpr(expr.value[key], context, closureContext).value;
    }
    return { value: obj };
  }],
  [STATEMENT_TYPE.ARRAY_LITERAL, () => ({
    value: expr.elements.map(el => evalExpr(el, context, closureContext).value)
  })],
  [STATEMENT_TYPE.PROPERTY_LOOKUP, () => {
    const { property, expr: _expr } = expr;
    const object = evalExpr(_expr, context, closureContext).value;
    assert(typeof object === 'object');
    return { value: object[property] };
  }],
  [any, () => { console.log(expr); throw 'unimplemented -- evalExpr'; }]
]);

const interpret = (ast, context = {...globals}, closureContext = {}) => {
  const isFunction = ast.type === STATEMENT_TYPE.FUNCTION;
  assert(ast.type === STATEMENT_TYPE.PROGRAM || isFunction);
  const lookup = s => closureContext[s] || context[s];
  for (const statement of ast.body) {
    const value = match(statement.type, [
      [STATEMENT_TYPE.DECLARATION, () => {
        const { symbol, mutable, expr } = statement;
        if (lookup(symbol)) {
          console.log(lookup(symbol));
          throw `'${symbol}' has already been declared`;
        }
        const val = { mutable, ...evalExpr(expr, context, closureContext), };
        if (isFunction) {
          closureContext[symbol] = val;
        } else {
          context[symbol] = val;
        }
      }],
      [STATEMENT_TYPE.ASSIGNMENT, () => {
        const { symbol, expr } = statement;
        const variable = lookup(symbol);
        assert(variable.mutable);
        context[symbol].value = evalExpr(expr, context, closureContext).value;
      }],
      [any, () => evalExpr(statement, context, closureContext)]
    ]);
    if (isFunction && statement.type === STATEMENT_TYPE.RETURN)
      return value;
  }
  return context;
};

export default interpret;