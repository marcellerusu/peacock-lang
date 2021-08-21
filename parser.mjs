import {TOKEN_NAMES} from "./tokenizer.mjs";
import {match, any, eq} from './utils.mjs';
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
};

const declaration = ({symbol, expr, mutable}) => ({
  type: STATEMENT_TYPE.DECLARATION,
  mutable: !!mutable,
  symbol,
  expr
});

const assignment = ({symbol, expr}) => ({
  type: STATEMENT_TYPE.ASSIGNMENT,
  symbol,
  expr
});

const objectLiteral = ({ value }) => ({
  type: STATEMENT_TYPE.OBJECT_LITERAL,
  value,
});

const arrayLiteral = ({ elements }) => ({
  type: STATEMENT_TYPE.ARRAY_LITERAL,
  elements
})

const numberLiteral = ({ value }) => ({
  type: STATEMENT_TYPE.NUMBER_LITERAL,
  value,
});

const stringLiteral = ({ value }) => ({
  type: STATEMENT_TYPE.STRING_LITERAL,
  value,
});

const fn = ({paramNames = [], body}) => ({
  type: STATEMENT_TYPE.FUNCTION,
  paramNames,
  body,
});

const fnCall = ({symbol, paramExprs = []}) => ({
  type: STATEMENT_TYPE.FUNCTION_APPLICATION,
  symbol,
  paramExprs
});

const _return = ({expr}) => ({
  type: STATEMENT_TYPE.RETURN,
  expr
});

const symbolLookup = ({symbol}) => ({
  type: STATEMENT_TYPE.SYMBOL_LOOKUP,
  symbol,
});

const makeConsumer = tokens => (i, tokensToConsume) => {
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
}

const isExpression = context => [
  STATEMENT_TYPE.RETURN,
  STATEMENT_TYPE.FUNCTION_APPLICATION,
  STATEMENT_TYPE.ASSIGNMENT,
  STATEMENT_TYPE.DECLARATION,
  STATEMENT_TYPE.ARRAY_LITERAL,
  STATEMENT_TYPE.OBJECT_LITERAL
].includes(context);

const parse = tokens => {
  const consume = makeConsumer(tokens);
  const consumeOne = (i, token) => {
    const [[val], i2] = consume(i, [{token}]);
    return [val, i2];
  };
  const AST = { type: STATEMENT_TYPE.PROGRAM, body: [], };
  for (let i = 0; i < tokens.length; i++) {
    const parseNode = (token, context = undefined) => match(token, [
      [[TOKEN_NAMES.LITERAL, any], () => {
        let value;
        [value, i] = consumeOne(i, token);
        if (typeof value === 'number') {
          return numberLiteral({value});
        } else if (typeof value === 'string') {
          return stringLiteral({value});
        } else {
          throw 'should not reach';
        }
      }],
      [TOKEN_NAMES.RETURN, () => {
        [, i] = consumeOne(i, TOKEN_NAMES.RETURN);
        const expr = parseNode(tokens[i], STATEMENT_TYPE.RETURN);
        [, i] = consumeOne(i, TOKEN_NAMES.END_STATEMENT);
        return _return({expr});
      }],
      [TOKEN_NAMES.LET, () => {
        assert(!isExpression(context));
        let mutable, symbol;
        [, i] = consumeOne(i, TOKEN_NAMES.LET);
        [[mutable, symbol], i] = consume(i, [
          {token: TOKEN_NAMES.MUT, optional: true},
          {token: [TOKEN_NAMES.SYMBOL, any]},
          {token: TOKEN_NAMES.ASSIGNMENT},
        ]);
        const expr = parseNode(tokens[i], STATEMENT_TYPE.DECLARATION);
        [, i] = consumeOne(i, TOKEN_NAMES.END_STATEMENT);
        return declaration({mutable, symbol, expr});
      }],
      [[TOKEN_NAMES.SYMBOL, any], () => {
        let symbol;
        [symbol, i] = consumeOne(i, token);
        return match(tokens[i], [
          [TOKEN_NAMES.ASSIGNMENT, () => {
            [, i] = consumeOne(i, TOKEN_NAMES.ASSIGNMENT);
            const expr = parseNode(tokens[i], STATEMENT_TYPE.ASSIGNMENT);
            return assignment({symbol, expr});
          }],
          [TOKEN_NAMES.OPEN_PARAN, () => {
            // function application
            [, i] = consumeOne(i, TOKEN_NAMES.OPEN_PARAN);
            const paramExprs = [];
            while (tokens[i] !== TOKEN_NAMES.CLOSE_PARAN) {
              const expr = parseNode(tokens[i], STATEMENT_TYPE.FUNCTION_APPLICATION);
              paramExprs.push(expr);
              if (tokens[i] !== TOKEN_NAMES.COMMA) break;
              [, i] = consumeOne(i, TOKEN_NAMES.COMMA);
            }
            [, i] = consume(i, [
              {token: TOKEN_NAMES.CLOSE_PARAN},
              {token: TOKEN_NAMES.END_STATEMENT},
            ]);
            return fnCall({symbol, paramExprs});
          }],
          [[TOKEN_NAMES.OPERATOR, any], () => {
            let op, sym2;
            [op, i] = consumeOne(i, [TOKEN_NAMES.OPERATOR, any]);
            [sym2, i] = consumeOne(i, [TOKEN_NAMES.SYMBOL, any]);
            return fnCall({
              symbol: op,
              paramExprs: [
                symbolLookup({symbol}),
                symbolLookup({symbol: sym2})
              ]
            });
          }],
          [any, () => {
            assert(isExpression(context));
            return symbolLookup({symbol});
          }]
        ]);
      }],
      [TOKEN_NAMES.OPEN_PARAN, () => {
        // function definition
        [, i] = consumeOne(i, TOKEN_NAMES.OPEN_PARAN);
        let sym;
        const paramNames = [];
        while (tokens[i] !== TOKEN_NAMES.CLOSE_PARAN) {
          [sym, i] = consumeOne(i, [TOKEN_NAMES.SYMBOL, any]);
          paramNames.push(sym);
          if (tokens[i] !== TOKEN_NAMES.COMMA) break;
          [, i] = consumeOne(i, TOKEN_NAMES.COMMA);
        }
        [, i] = consume(i, [
          {token:TOKEN_NAMES.CLOSE_PARAN},
          {token:TOKEN_NAMES.ARROW},
        ]);
        if (tokens[i] !== TOKEN_NAMES.OPEN_BRACE) {
          const expr = parseNode(tokens[i], STATEMENT_TYPE.RETURN);
          return fn({body: [_return({expr})], paramNames});
        } else {
          [, i] = consumeOne(i, TOKEN_NAMES.OPEN_BRACE);
          let expr = {}, body = [];
          while (expr.type !== STATEMENT_TYPE.RETURN && i < tokens.length) {
            expr = parseNode(tokens[i], STATEMENT_TYPE.FUNCTION);
            body.push(expr);
          }
          if (i >= tokens.length || expr.type !== STATEMENT_TYPE.RETURN)
            throw `function statement does not have return statement!`;
          [, i] = consumeOne(i, TOKEN_NAMES.CLOSE_BRACE);
          return fn({body, paramNames});
        }

      }],
      [TOKEN_NAMES.OPEN_BRACE, () => {
        // parsing an object literal
        assert(isExpression(context));
        [, i] = consumeOne(i, TOKEN_NAMES.OPEN_BRACE);
        const value = {};
        while (true) {
          let varName;
          // TODO: don't use try, implement peek
          try {
            [[varName], i] = consume(i, [
              {token: [TOKEN_NAMES.SYMBOL, any]},
              {token: TOKEN_NAMES.COLON},
            ]);
          } catch (e) {
            break;
          }
          value[varName] = parseNode(tokens[i], STATEMENT_TYPE.OBJECT_LITERAL);
          if (tokens[i] !== TOKEN_NAMES.COMMA) break;
          [, i] = consumeOne(i, TOKEN_NAMES.COMMA);
        }
        [, i] = consumeOne(i, TOKEN_NAMES.CLOSE_BRACE);
        return objectLiteral({value});
      }],
      [TOKEN_NAMES.OPEN_SQ_BRACE, () => {
        // parsing an array literal
        assert(isExpression(context));
        [, i] = consumeOne(i, TOKEN_NAMES.OPEN_SQ_BRACE);
        const elements = [];
        while (tokens[i] !== TOKEN_NAMES.CLOSE_BRACE) {
          elements.push(parseNode(tokens[i], STATEMENT_TYPE.ARRAY_LITERAL));
          if (tokens[i] !== TOKEN_NAMES.COMMA) break;
          [, i] = consumeOne(i, TOKEN_NAMES.COMMA);
        }
        [, i] = consumeOne(i, TOKEN_NAMES.CLOSE_SQ_BRACE);
        return arrayLiteral({elements});
      }],
      [any, () => { throw 'did not match any ' + token}],
    ]);
    const astNode = parseNode(tokens[i]);
    AST.body.push(astNode);
  }
  return AST;
};

export default parse;