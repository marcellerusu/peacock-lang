import {
  STATEMENT_TYPE
} from './parser.mjs';
import { match, any } from './utils.mjs';

const operatorToFunction = {
  '>': 'M.gt',
  '<': 'M.ls',
  '==': 'M.is',
  '!=': 'M.isNot',
  '+': 'M.plus',
  '-': 'M.minus',
  '*': 'M.times',
  '/': 'M.divides',
}

const convertObjectProperty = str =>
  str.includes(' ') ? `'${str}'` : str;
const quoteIfString = str => typeof str === 'string' ? `'${str}'` : str;

const compileNumberLiteral = expr => `${expr.get('value')}`;
const compileStringLiteral = expr => `'${expr.get('value')}'`;
const compileBoundVariable = expr => 'any';
const compileArrayLiteral = expr => 
  `List([${expr.get('elements').reduce((expr, elem, i) => 
    `${expr}${i !== 0 ? ', ' : ''}${compileExpr(elem)}`
  , '')}])`;
const compileObjectLiteral = expr =>
  `Map({ ${
    expr.get('value')
      .reduce((props, v, k) =>
        `${props}${convertObjectProperty(k)}: ${compileExpr(v)}, `
      , '')
  }})`;
const compilePropertyLookup = expr =>
  `${compileExpr(expr.get('expr'))}.get('${expr.get('property')}')`;
const compileDynamicLookup = expr =>
  `${compileExpr(expr.get('expr'))}.get(${quoteIfString(expr.get('lookupKey'))})`;
const compileSymbolLookup = expr => expr.get('symbol');
const compileFunction = expr =>
  `((${
    expr.get('paramNames').reduce((args, arg, i) =>
     `${args}${i === 0 ? '' : ', '}${arg}`
    , '')
  }) => {\n${compile(expr)}\n})`;
const compileFunctionApplication = expr => {
  let f = compileExpr(expr.get('expr'));
  if (operatorToFunction[f]) f = operatorToFunction[f];
  return `${f}(${
    expr.get('paramExprs').reduce((paramExprs, pExpr, i) =>
    `${paramExprs}${i === 0 ? '' : ', '}${compileExpr(pExpr)}`
    , '')
  })`;
};
const compileConditional = expr =>
  `(() => {if (${compileExpr(expr.get('expr'))}) {${compileExpr(expr.get('pass'))}} else {${compileExpr(expr.get('fail'))}}})()`;

// TODO: use matchExpr in the case invoke paramExprs
const compileMatchExpression = expr =>
  `(() => {\nconst matchExpr = ${compileExpr(expr.get('expr'))};
    ${expr.get('cases').reduce((s, c) => 
      `${s}\nif (M.matchEq(${compileExpr(c.get('expr'))}, matchExpr)) {return ${
        compileFunctionApplication(c.get('invoke'))
      };}`
    , '')
    }
  })()`

  
const compileExpr = expr => match(expr.get('type'), [
  [STATEMENT_TYPE.NUMBER_LITERAL, () => compileNumberLiteral(expr)],
  [STATEMENT_TYPE.STRING_LITERAL, () => compileStringLiteral(expr)],
  [STATEMENT_TYPE.SYMBOL_LOOKUP, () => compileSymbolLookup(expr)],
  [STATEMENT_TYPE.BOUND_VARIABLE, () => compileBoundVariable(expr)],
  [STATEMENT_TYPE.ARRAY_LITERAL, () => compileArrayLiteral(expr)],
  [STATEMENT_TYPE.OBJECT_LITERAL, () => compileObjectLiteral(expr)],
  [STATEMENT_TYPE.PROPERTY_LOOKUP, () => compilePropertyLookup(expr)],
  [STATEMENT_TYPE.DYNAMIC_LOOKUP, () => compileDynamicLookup(expr)],
  [STATEMENT_TYPE.FUNCTION, () => compileFunction(expr)],
  [STATEMENT_TYPE.FUNCTION_APPLICATION, () => compileFunctionApplication(expr)],
  [STATEMENT_TYPE.CONDITIONAL, () => compileConditional(expr)],
  [STATEMENT_TYPE.MATCH_EXPRESSION, () => compileMatchExpression(expr)],
]);

const compile = ast => {
  const body = ast.get('body');
  return body.reduce((program, statement, i) => match(statement.get('type'), [
    [STATEMENT_TYPE.RETURN, () => `${program}${i === 0 ? '' : '\n'}return ${compileExpr(statement.get('expr'))};`],
    [STATEMENT_TYPE.DECLARATION, () => {
      const symbol = statement.get('symbol'), mutable = statement.get('mutable'), expr = statement.get('expr');
      const dec = mutable ? 'let' : 'const';
      return `${program}${i === 0 ? '' : '\n'}
      ${dec} ${symbol} = ${compileExpr(statement.get('expr'))};
      `.trim()
    }],
    [STATEMENT_TYPE.ASSIGNMENT, () => {
      const symbol = statement.get('symbol'), expr = statement.get('expr');
      return `${program}${i === 0 ? '' : '\n'}${symbol} = ${compileExpr(statement.get('expr'))};`
    }],
    [any, () => `${program}${i === 0 ? '' : '\n'}${compileExpr(statement)}`]
  ]), '');
};

export default compile;