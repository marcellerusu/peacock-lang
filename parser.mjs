import {TOKEN_NAMES} from "./tokenizer.mjs";
import {match, any, eq} from './utils.mjs';

export const STATEMENT_TYPE = {
  DECLARATION: 'DECLARATION',
  ASSIGNMENT: 'ASSIGNMENT',
  FUNCTION: 'FUNCTION',
  RETURN: 'RETURN',
  PROGRAM: 'PROGRAM',
  NUMBER_LITERAL: 'NUMBER_LITERAL',
  OBJECT_LITERAL: 'OBJECT_LITERAL',
};

export const declaration = ({symbol, expr, mutable}) => ({
  type: STATEMENT_TYPE.DECLARATION,
  mutable: !!mutable,
  symbol,
  expr
});

export const assignment = ({symbol, expr}) => ({
  type: STATEMENT_TYPE.ASSIGNMENT,
  symbol,
  expr
});

export const objectLiteral = ({ value }) => ({
  type: STATEMENT_TYPE.OBJECT_LITERAL,
  value,
})

export const numberLiteral = ({ value }) => ({
  type: STATEMENT_TYPE.NUMBER_LITERAL,
  value,
})

export const _function = ({paramNames = [], body}) => ({
  type: STATEMENT_TYPE.FUNCTION,
  paramNames,
  body,
});

export const _return = ({expr}) => ({
  type: STATEMENT_TYPE.RETURN,
  expr
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
      } else throw `Token mismatch -- expected ${consumable.token}, got ${token}`;
    } else {
      tokenValue = match(token, [
        [[TOKEN_NAMES.SYMBOL, any], ([_, sym]) => sym],
        [[TOKEN_NAMES.LITERAL, any], ([_, lit]) => lit],
        [TOKEN_NAMES.MUT, t => t],
        [any, () => undefined]
      ]);
    }
    if (typeof tokenValue !== 'undefined') tokenValues.push(tokenValue);
  }
  return [tokenValues, i];
}

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
        const [value, i2] = consumeOne(i, token);
        return [numberLiteral({value}), i2];
      }],
      [TOKEN_NAMES.LET, () => {
        const [[mutable, symbol], i2] = consume(i + 1, [
          {token: TOKEN_NAMES.MUT, optional: true},
          {token: [TOKEN_NAMES.SYMBOL, any]},
          {token: TOKEN_NAMES.ASSIGNMENT},
        ]);
        i = i2;
        const [expr, i3] = parseNode(tokens[i2], STATEMENT_TYPE.DECLARATION);
        i = i3;
        const [_, i4] = consumeOne(i3, TOKEN_NAMES.END_STATEMENT);
        return [declaration({mutable, symbol, expr}), i4];
      }],
      [[TOKEN_NAMES.SYMBOL, any], () => {
        const [symbol, i2] = consumeOne(i, token);
        i = i2;
        // expect to be assignment 
        const [_, i3] = consumeOne(i2, TOKEN_NAMES.ASSIGNMENT);
        i = i3;
        const [expr, i4] = parseNode(tokens[i3], STATEMENT_TYPE.ASSIGNMENT);
        return [assignment({symbol, expr}), i4]
      }],
      [TOKEN_NAMES.OPEN_PARAN, () => {
        // TODO: implement func args
        const [_, i2] = consume(i, [
          {token: TOKEN_NAMES.OPEN_PARAN},
          {token: TOKEN_NAMES.CLOSE_PARAN},
          {token: TOKEN_NAMES.ARROW},
        ]);
        i = i2;
        const [expr, i3] = parseNode(tokens[i2], STATEMENT_TYPE.FUNCTION);
        // TODO: implement non-expr body
        const body = [_return({expr})];
        return [_function({body}), i3];

      }],
      [TOKEN_NAMES.OPEN_BRACE, () => {
        if ([STATEMENT_TYPE.ASSIGNMENT, STATEMENT_TYPE.DECLARATION].includes(context)) {
          const [_, i2] = consumeOne(i, TOKEN_NAMES.OPEN_BRACE);
          i = i2;
          const value = {};
          while (true) {
            let varName, i3;
            // TODO: don't use try, implement peek
            try {
              [[varName], i3] = consume(i, [
                {token: [TOKEN_NAMES.SYMBOL, any]},
                {token: TOKEN_NAMES.COLON},
              ]);
            } catch (e) {
              break;
            }
            i = i3;
            const [expr, i4] = parseNode(tokens[i3], STATEMENT_TYPE.OBJECT_LITERAL);
            i = i4;
            value[varName] = expr;
            const [_, i5] = consumeOne(i4, TOKEN_NAMES.COMMA);
            i = i5;
          }
          const [__, i6] = consumeOne(i, TOKEN_NAMES.CLOSE_BRACE);
          return [objectLiteral({value}), i6];
        } else {
          console.log({context});
          throw 'unimplemented';
        }
      }],
      [any, () => { throw 'did not match any ' + token}],
    ]);
    const [astNode, newIndex] = parseNode(tokens[i]);
    AST.body.push(astNode);
    i = newIndex;
  }
  return AST;
};

export default parse;