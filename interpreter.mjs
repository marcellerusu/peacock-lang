import assert from 'assert';
import { STATEMENT_TYPE } from "./parser.mjs";
import { match, any, eq } from './utils.mjs';
import pkg from 'immutable';
const { fromJS, isMap, is, isList, Map } = pkg;

export const getGlobals = () => fromJS({
  print: {
    native: (...args) => {
      console.log(...args.map(v => isMap(v) || isList(v) ? v.toJS() : v));
    },
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
  },
  '==': {
    native: (a, b) => is(a, b),
  },
  '!=': {
    native: (a, b) => !is(a, b),
  },
  '>': {
    native: (a, b) => a > b,
  },
  '<': {
    native: (a, b) => a < b,
  },
});

export let globals = getGlobals();
export const refreshGlobals = () => globals = getGlobals();

const evalNativeCall = (fn, paramExprs, context, closureContext) => {
  const args = [];
  for (const expr of paramExprs) {
    const val = evalExpr(expr, context, closureContext);
    assert(typeof val.get('value') !== 'undefined');
    args.push(val.get('value'));
  }
  return Map({ value: fn.get('native')(...args) });
};

const evalExpr = (expr, context, closureContext = Map({})) => match(expr.get('type'), [
  [STATEMENT_TYPE.NUMBER_LITERAL, () => expr],
  [STATEMENT_TYPE.STRING_LITERAL, () => expr],
  [STATEMENT_TYPE.BOOLEAN_LITERAL, () => expr],
  [STATEMENT_TYPE.RETURN, () => evalExpr(expr.get('expr'), context, closureContext)],
  [STATEMENT_TYPE.SYMBOL_LOOKUP, () => closureContext.get(expr.get('symbol')) || context.get(expr.get('symbol'))],
  [STATEMENT_TYPE.ARRAY_LOOKUP, () => {
    const arrExpr = expr.get('expr');
    const index = expr.get('index');
    const arr = evalExpr(arrExpr, context, closureContext).get('value');
    return Map({ value: arr.get(index) });
  }],
  [STATEMENT_TYPE.FUNCTION, () => Map({ value: expr.merge(Map({ closureContext })) })],
  [STATEMENT_TYPE.CONDITIONAL, () => {
    const condExpr = expr.get('expr'), pass = expr.get('pass'), fail = expr.get('fail');
    const cond = evalExpr(condExpr, context, closureContext).get('value');
    if (cond) {
      return evalExpr(pass, context, closureContext);
    } else {
      return evalExpr(fail, context, closureContext);
    }
  }],
  [STATEMENT_TYPE.FUNCTION_APPLICATION, () => {
    const paramExprs = expr.get('paramExprs'), fnExpr = expr.get('expr');
    const fn = evalExpr(fnExpr, context, closureContext);
    if (typeof fn.get('native') !== 'undefined')
      return evalNativeCall(fn, paramExprs, context, closureContext);
    assert(typeof fn.get('value') !== 'undefined');
    const fnAST = fn.get('value');
    // TODO: implement auto currying
    const fnContext = paramExprs.reduce((prev, pExpr, i) =>
      prev.merge(Map({
        [fnAST.getIn(['paramNames', i])]: Map({
          mutable: false
        }).merge(evalExpr(pExpr, context, closureContext))
      }))
    , fnAST.get('closureContext'));
    return interpret(
      Map({ body: fnAST.get('body'), type: STATEMENT_TYPE.FUNCTION }),
      context,
      fnContext
    )[0];
  }],
  [STATEMENT_TYPE.BOUND_VARIABLE, () => fromJS({ value: any })],
  [STATEMENT_TYPE.OBJECT_LITERAL, () => Map({
    value: expr.get('value')
      .map(v => evalExpr(v, context, closureContext).get('value'))
  })],
  [STATEMENT_TYPE.ARRAY_LITERAL, () => Map({
    value: expr.get('elements')
      .map(el => evalExpr(el, context, closureContext).get('value'))
  })],
  [STATEMENT_TYPE.PROPERTY_LOOKUP, () => {
    const property = expr.get('property'), _expr = expr.get('expr');
    const map = evalExpr(_expr, context, closureContext).get('value');
    assert(isMap(map));
    const value = map.get(property);
    assert(typeof value !== 'undefined'); // not allow to lookup properties that don't exist
    return Map({ value });
  }],
  [STATEMENT_TYPE.MATCH_EXPRESSION, () => {
    const matchExpr = expr.get('expr'), cases = expr.get('cases');
    const value = evalExpr(matchExpr, context, closureContext).get('value');
    for (const c of cases) {
      const caseExpr = c.get('expr'), invoke = c.get('invoke');
      if (eq(evalExpr(caseExpr, context, closureContext).get('value'), value)) {
        return evalExpr(invoke, context, closureContext);
      }
    }
    return Map({ value: null });
  }],
  [any, () => { console.log(expr); assert(false); 'unimplemented -- evalExpr'; }]
]);

const interpret = (ast, context = globals, closureContext = fromJS({})) => {
  const isFunction = ast.get('type') === STATEMENT_TYPE.FUNCTION;
  assert(ast.get('type') === STATEMENT_TYPE.PROGRAM || isFunction);
  const lookup = s => closureContext.get(s) || context.get(s);
  let value, statement;
  for (statement of ast.get('body')) {
    [value, context, closureContext] = match(statement.get('type'), [
      [STATEMENT_TYPE.DECLARATION, () => {
        const symbol = statement.get('symbol'), mutable = statement.get('mutable'), expr = statement.get('expr');
        if (closureContext.get('symbol')) {
          console.log(closureContext.get('symbol'));
          throw `'${symbol}' has already been declared in this closure context`;
        }
        const val = fromJS({ mutable })
          .merge(evalExpr(expr, context, closureContext));
        if (isFunction) {
          return [, context, closureContext.set(symbol, val)];
        } else {
          return [, context.set(symbol, val), closureContext];
        }
      }],
      [STATEMENT_TYPE.ASSIGNMENT, () => {
        const symbol = statement.get('symbol'), expr = statement.get('expr');
        const variable = lookup(symbol);
        assert(variable.get('mutable'));
        if (isFunction) {
          return [, context, closureContext.setIn([symbol, 'value'], evalExpr(expr, context, closureContext).get('value'))];
        } else {
          return [, context.setIn([symbol, 'value'], evalExpr(expr, context, closureContext).get('value')), closureContext];
        }
      }],
      [any, () => [evalExpr(statement, context, closureContext), context, closureContext]]
    ]);
    if (isFunction && statement.get('type') === STATEMENT_TYPE.RETURN) {
      return [value, context, closureContext];
    }
  }
  // TODO: I don't fully understand why this is necessary
  if (statement?.get('type') === STATEMENT_TYPE.CONDITIONAL)
    return [value, context, closureContext];
  return [null, context, closureContext];
};

export default interpret;