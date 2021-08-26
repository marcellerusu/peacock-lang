import assert from 'assert';
import { STATEMENT_TYPE } from "./parser.mjs";
import { match, any, eq } from './utils.mjs';

export const getGlobals = () => ({
  print: {
    native: console.log,
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
    native: (a, b) => eq(a, b),
  },
  '!=': {
    native: (a, b) => !eq(a, b),
  },
  '>': {
    native: (a, b) => a > b,
  },
  '<': {
    native: (a, b) => a > b,
  },
});

export let globals = getGlobals();
export const refreshGlobals = () => globals = getGlobals();

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
  [STATEMENT_TYPE.BOOLEAN_LITERAL, () => expr],
  [STATEMENT_TYPE.RETURN, () => evalExpr(expr.expr, context, closureContext)],
  [STATEMENT_TYPE.SYMBOL_LOOKUP, () => closureContext[expr.symbol] || context[expr.symbol]],
  [STATEMENT_TYPE.ARRAY_LOOKUP, () => {
    const {expr: arrExpr, index} = expr;
    const { value: arr } = evalExpr(arrExpr, context, closureContext);
    return { value: arr[index] };
  }],
  [STATEMENT_TYPE.FUNCTION, () => ({ value: { ...expr, closureContext } })],
  [STATEMENT_TYPE.CONDITIONAL, () => {
    const { expr: condExpr, pass, fail } = expr;
    const { value: cond } = evalExpr(condExpr, context, closureContext);
    if (cond) {
      return evalExpr(pass, context, closureContext);
    } else {
      return evalExpr(fail, context, closureContext);
    }
  }],
  [STATEMENT_TYPE.FUNCTION_APPLICATION, () => {
    const { paramExprs, expr: fnExpr } = expr;
    const fn = evalExpr(fnExpr, context, closureContext);
    if (typeof fn.native !== 'undefined') {
      const args = evalParamExprs(paramExprs, context, closureContext);
      return { value: fn.native(...args) };
    }
    assert(typeof fn.value !== 'undefined');
    const { paramNames, body, closureContext: oldClosureContext } = fn.value;
    // TODO: implement auto currying
    assert(paramNames.length === paramExprs.length);
    const fnContext = { ...oldClosureContext };
    for (let i = 0; i < paramExprs.length; i++) {
      // TODO: this should be in parsing phase + use evalParamExprs
      // if (closureContext[paramNames[i]]) {
      //   console.log(fn.value.body[0]);
      //   throw `no duplicate param names`;
      // }
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
  [STATEMENT_TYPE.BOUND_VARIABLE, () => ({ value: any })],
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
  [STATEMENT_TYPE.MATCH_EXPRESSION, () => {
    const { expr: matchExpr, cases } = expr;
    const { value } = evalExpr(matchExpr, context, closureContext);
    for (const { expr: caseExpr, invoke } of cases) {
      if (eq(evalExpr(caseExpr, context, closureContext).value, value)) {
        return evalExpr(invoke, context, closureContext);
      }
    }
    return { value: null };
  }],
  [any, () => { console.log(expr); throw 'unimplemented -- evalExpr'; }]
]);

const interpret = (ast, context = globals, closureContext = {}) => {
  const isFunction = ast.type === STATEMENT_TYPE.FUNCTION;
  // console.log(isFunction);
  assert(ast.type === STATEMENT_TYPE.PROGRAM || isFunction);
  const lookup = s => closureContext[s] || context[s];
  let value, statement;
  for (statement of ast.body) {
    value = match(statement.type, [
      [STATEMENT_TYPE.DECLARATION, () => {
        const { symbol, mutable, expr } = statement;
        if (closureContext[symbol]) {
          console.log(closureContext[symbol]);
          throw `'${symbol}' has already been declared in this closure context`;
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
  // TODO: I don't fully understand why this is necessary
  if (statement.type === STATEMENT_TYPE.CONDITIONAL)
    return value;
  return null;
};

export default interpret;