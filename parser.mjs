import { TOKEN_NAMES } from "./tokenizer.mjs";
import { match, any, eq } from './utils.mjs';
import assert from 'assert';

export const STATEMENT_TYPE = {
  DECLARATION: 'DECLARATION',
  ASSIGNMENT: 'ASSIGNMENT',
  FUNCTION: 'FUNCTION',
  RETURN: 'RETURN',
  PROGRAM: 'PROGRAM',
  NUMBER_LITERAL: 'NUMBER_LITERAL',
  STRING_LITERAL: 'STRING_LITERAL',
  OBJECT_LITERAL: 'OBJECT_LITERAL',
  ARRAY_LITERAL: 'ARRAY_LITERAL',
  FUNCTION_APPLICATION: 'FUNCTION_APPLICATION',
  SYMBOL_LOOKUP: 'SYMBOL_LOOKUP',
  PROPERTY_LOOKUP: 'PROPERTY_LOOKUP',
  CONDITIONAL: 'CONDITIONAL'
};

export const declaration = ({ symbol, expr, mutable }) => ({
  type: STATEMENT_TYPE.DECLARATION,
  mutable: !!mutable,
  symbol,
  expr
});

export const assignment = ({ symbol, expr }) => ({
  type: STATEMENT_TYPE.ASSIGNMENT,
  symbol,
  expr
});

export const objectLiteral = ({ value }) => ({
  type: STATEMENT_TYPE.OBJECT_LITERAL,
  value,
});

export const arrayLiteral = ({ elements }) => ({
  type: STATEMENT_TYPE.ARRAY_LITERAL,
  elements
});

export const numberLiteral = ({ value }) => ({
  type: STATEMENT_TYPE.NUMBER_LITERAL,
  value,
});

export const stringLiteral = ({ value }) => ({
  type: STATEMENT_TYPE.STRING_LITERAL,
  value,
});

export const fn = ({ paramNames = [], body }) => ({
  type: STATEMENT_TYPE.FUNCTION,
  paramNames,
  body,
});

export const fnCall = ({ expr, paramExprs = [] }) => ({
  type: STATEMENT_TYPE.FUNCTION_APPLICATION,
  expr,
  paramExprs
});

export const _return = ({ expr }) => ({
  type: STATEMENT_TYPE.RETURN,
  expr
});

export const symbolLookup = ({ symbol }) => ({
  type: STATEMENT_TYPE.SYMBOL_LOOKUP,
  symbol,
});

export const propertyLookup = ({ property, expr }) => ({
  type: STATEMENT_TYPE.PROPERTY_LOOKUP,
  property,
  expr,
});

export const conditional = ({ expr, passFn, failFn = null }) => ({
  type: STATEMENT_TYPE.CONDITIONAL,
  expr,
  passFn,
  failFn
});

export const makeConsumer = tokens => (i, tokensToConsume) => {
  const tokenValues = [];
  for (let consumable of tokensToConsume) {
    const token = tokens[i++];
    let tokenValue;

    if (!eq(token, consumable.token)) {
      if (consumable.optional) {
        tokenValue = null;
        i--;
      } else {
        throw `Token mismatch -- expected ${consumable.token}, got ${token}`;
      }
    } else {
      tokenValue = match(token, [
        [[TOKEN_NAMES.SYMBOL, any], ([_, sym]) => sym],
        [[TOKEN_NAMES.LITERAL, any], ([_, lit]) => lit],
        [[TOKEN_NAMES.OPERATOR, any], ([_, op]) => op],
        [TOKEN_NAMES.MUT, t => t],
        [any, () => undefined]
      ]);
    }
    if (typeof tokenValue !== 'undefined') tokenValues.push(tokenValue);
  }
  return [tokenValues, i];
};

const isExpression = context => [
  STATEMENT_TYPE.RETURN,
  STATEMENT_TYPE.FUNCTION_APPLICATION,
  STATEMENT_TYPE.ASSIGNMENT,
  STATEMENT_TYPE.DECLARATION,
  STATEMENT_TYPE.ARRAY_LITERAL,
  STATEMENT_TYPE.OBJECT_LITERAL,
  STATEMENT_TYPE.CONDITIONAL
].includes(context);

const parse = tokens => {
  const AST = { type: STATEMENT_TYPE.PROGRAM, body: [], };
  for (let i = 0; i < tokens.length; i++) {
    const consume = consumables => {
      const [arr, i2] = makeConsumer(tokens)(i, consumables);
      i = i2;
      return arr;
    };
    const consumeOne = token => consume([{token}])[0];
    const parseFunctionCall = expr => {
      consumeOne(TOKEN_NAMES.OPEN_PARAN);
      const paramExprs = [];
      while (tokens[i] !== TOKEN_NAMES.CLOSE_PARAN) {
        const expr = parseNode(tokens[i], STATEMENT_TYPE.FUNCTION_APPLICATION);
        paramExprs.push(expr);
        if (tokens[i] !== TOKEN_NAMES.COMMA) break;
        consumeOne(TOKEN_NAMES.COMMA);
      }
      consumeOne(TOKEN_NAMES.CLOSE_PARAN);
      return fnCall({ expr, paramExprs });
    };

    const parseDotNotation = expr => {
      const propertyList = [];
      while (tokens[i] === TOKEN_NAMES.PROPERTY_ACCESSOR) {
        consumeOne(TOKEN_NAMES.PROPERTY_ACCESSOR);
        propertyList.push(consumeOne([TOKEN_NAMES.SYMBOL, any]));
      }
      for (const prop of propertyList) {
        expr = propertyLookup({ property: prop, expr });
      }
      return expr;
    };

    const parseObjectLiteral = () => {
      consumeOne(TOKEN_NAMES.OPEN_BRACE);
      const value = {};
      while (tokens[i] !== TOKEN_NAMES.CLOSE_BRACE) {
        const varName = consumeOne([TOKEN_NAMES.SYMBOL, any]);
        consumeOne(TOKEN_NAMES.COLON);
        value[varName] = parseNode(tokens[i], STATEMENT_TYPE.OBJECT_LITERAL);
        if (tokens[i] !== TOKEN_NAMES.COMMA) break;
        consumeOne(TOKEN_NAMES.COMMA);
      }
      consumeOne(TOKEN_NAMES.CLOSE_BRACE);
      return value;
    };

    const parseArrayLiteral = () => {
      consumeOne(TOKEN_NAMES.OPEN_SQ_BRACE);
      const elements = [];
      while (tokens[i] !== TOKEN_NAMES.CLOSE_SQ_BRACE) {
        elements.push(parseNode(tokens[i], STATEMENT_TYPE.ARRAY_LITERAL));
        if (tokens[i] !== TOKEN_NAMES.COMMA) break;
        consumeOne(TOKEN_NAMES.COMMA);
      }
      consumeOne(TOKEN_NAMES.CLOSE_SQ_BRACE);
      return elements;
    };

    const parseFunctionDefinitionArgs = () => {
      const paramNames = [];
      while (tokens[i] !== TOKEN_NAMES.CLOSE_PARAN) {
        paramNames.push(consumeOne([TOKEN_NAMES.SYMBOL, any]));
        if (tokens[i] !== TOKEN_NAMES.COMMA) break;
        consumeOne(TOKEN_NAMES.COMMA);
      }
      return paramNames;
    };

    const parseStatements = () => {
      const body = [];
      while (tokens[i] !== TOKEN_NAMES.CLOSE_BRACE && i < tokens.length) {
        const expr = parseNode(tokens[i], STATEMENT_TYPE.FUNCTION)
        body.push(expr);
      }
      return body;
    };

    const parseFunctionBody = () => {
      if (tokens[i] !== TOKEN_NAMES.OPEN_BRACE) {
        // function expression
        const expr = parseNode(tokens[i], STATEMENT_TYPE.RETURN);
        return [_return({ expr })];
      } else {
        // function statement
        consumeOne(TOKEN_NAMES.OPEN_BRACE);
        const body = parseStatements();
        consumeOne(TOKEN_NAMES.CLOSE_BRACE);
        return body;
      }
    };

    const parseOperatorExpr = firstArg => {
      const op = consumeOne([TOKEN_NAMES.OPERATOR, any]);
      return fnCall({
        expr: symbolLookup({ symbol: op }),
        paramExprs: [
          firstArg,
          parseNode(tokens[i], STATEMENT_TYPE.FUNCTION_APPLICATION)
        ]
      });
    };

    const parseConditional = () => {
      consumeOne(TOKEN_NAMES.OPEN_PARAN);
      const expr = parseNode(tokens[i], STATEMENT_TYPE.CONDITIONAL);
      consumeOne(TOKEN_NAMES.CLOSE_PARAN);
      consumeOne(TOKEN_NAMES.OPEN_BRACE);
      const passBody = parseStatements();
      consumeOne(TOKEN_NAMES.CLOSE_BRACE);
      let failBody = [];
      if (tokens[i] === TOKEN_NAMES.ELSE) {
        consumeOne(TOKEN_NAMES.ELSE);
        consumeOne(TOKEN_NAMES.OPEN_BRACE);
        failBody = parseStatements();
        consumeOne(TOKEN_NAMES.CLOSE_BRACE);
      } else if (tokens[i] === TOKEN_NAMES.ELIF) {
        consumeOne(TOKEN_NAMES.ELIF);
        failBody = [parseConditional()];
      }
      return conditional({
        expr,
        passFn: fn({ body: passBody }),
        failFn: fn({ body: failBody })
      });
    };

    const parseNode = (token, context = undefined) => match(token, [
      [[TOKEN_NAMES.LITERAL, any], () => {
        const value = consumeOne(token);
        let literal;
        if (typeof value === 'number') {
          literal = numberLiteral({ value });
        } else if (typeof value === 'string') {
          literal = stringLiteral({ value });
        } else {
          throw 'should not reach';
        }
        if (eq(tokens[i], [TOKEN_NAMES.OPERATOR, any])) {
          return parseOperatorExpr(literal);
        }
        return literal;
      }],
      [TOKEN_NAMES.RETURN, () => {
        consumeOne(TOKEN_NAMES.RETURN);
        const expr = parseNode(tokens[i], STATEMENT_TYPE.RETURN);
        consumeOne(TOKEN_NAMES.END_STATEMENT);
        return _return({ expr });
      }],
      [TOKEN_NAMES.IF, () => {
        consumeOne(TOKEN_NAMES.IF);
        return parseConditional();
      }],
      [TOKEN_NAMES.LET, () => {
        assert(!isExpression(context));
        consumeOne(TOKEN_NAMES.LET);
        const [mutable, symbol] = consume([
          { token: TOKEN_NAMES.MUT, optional: true },
          { token: [TOKEN_NAMES.SYMBOL, any] },
          { token: TOKEN_NAMES.ASSIGNMENT },
        ]);
        const expr = parseNode(tokens[i], STATEMENT_TYPE.DECLARATION);

        consumeOne(TOKEN_NAMES.END_STATEMENT);
        return declaration({ mutable: !!mutable, symbol, expr });
      }],
      [[TOKEN_NAMES.SYMBOL, any], function parseSymbol(symToken, prevExpr) {
        let symbol
        if (!prevExpr) symbol = consumeOne(symToken);
        const isSymbol = typeof symbol !== 'undefined';
        return match(tokens[i], [
          [TOKEN_NAMES.ASSIGNMENT, () => {
            assert(isSymbol);
            consumeOne(TOKEN_NAMES.ASSIGNMENT);
            const expr = parseNode(tokens[i], STATEMENT_TYPE.ASSIGNMENT);
            return assignment({ symbol, expr });
          }],
          [TOKEN_NAMES.OPEN_PARAN, () => {
            const call = parseFunctionCall(prevExpr || symbolLookup({ symbol }));
            if (tokens[i] === TOKEN_NAMES.END_STATEMENT) {
              if (isExpression(context)) return call;
              consumeOne(TOKEN_NAMES.END_STATEMENT); // for top level function application
              return call;
            }
            return parseSymbol(tokens[i], call);
          }],
          [[TOKEN_NAMES.OPERATOR, any], () => {
            if (!prevExpr) assert(isSymbol);
            return parseOperatorExpr(prevExpr || symbolLookup({ symbol }));
          }],
          [TOKEN_NAMES.PROPERTY_ACCESSOR, () => {
            const expr = parseDotNotation(prevExpr || symbolLookup({ symbol }));
            // check if reached end of expression
            if (
              tokens[i] === TOKEN_NAMES.END_STATEMENT || tokens[i] === TOKEN_NAMES.CLOSE_PARAN
            ) return expr;
            return parseSymbol(tokens[i], expr);
          }],
          [any, () => {
            assert(isExpression(context));
            return prevExpr || symbolLookup({ symbol });
          }]
        ]);
      }],
      [TOKEN_NAMES.OPEN_PARAN, () => {
        // function definition
        consumeOne(TOKEN_NAMES.OPEN_PARAN);
        const paramNames = parseFunctionDefinitionArgs();
        consumeOne(TOKEN_NAMES.CLOSE_PARAN);
        consumeOne(TOKEN_NAMES.ARROW);
        return fn({ body: parseFunctionBody(), paramNames });
      }],
      [TOKEN_NAMES.OPEN_BRACE, () => {
        assert(isExpression(context));
        const value = parseObjectLiteral();
        if (tokens[i] === TOKEN_NAMES.PROPERTY_ACCESSOR) {
          return parseDotNotation(objectLiteral({ value }))
        }
        return objectLiteral({ value });
      }],
      [TOKEN_NAMES.OPEN_SQ_BRACE, () => {
        assert(isExpression(context));
        return arrayLiteral({ elements: parseArrayLiteral() });
      }],
      [any, () => { throw 'did not match any ' + token }],
    ]);
    // TODO: W T F
    if (i !== 0) --i;
    const astNode = parseNode(tokens[i]);
    AST.body.push(astNode);
  }
  return AST;
};

export default parse;