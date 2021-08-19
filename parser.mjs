import {TOKEN_NAMES} from "./tokenizer.mjs";
import {match, any, eq} from './utils.mjs';

export const STATEMENT_TYPE = {
  ASSIGNMENT: 'ASSIGNMENT',
  FUNCTION: 'FUNCTION',
  RETURN: 'RETURN',
  PROGRAM: 'PROGRAM',
  LITERAL: 'LITERAL',
};

export const assignment = ({symbol, expr, mutable}) => ({
  type: STATEMENT_TYPE.ASSIGNMENT,
  mutable: !!mutable,
  symbol,
  expr
});

export const literal = ({ value }) => ({
  type: STATEMENT_TYPE.LITERAL,
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
    const parseNode = token => match(token, [
      [[TOKEN_NAMES.LITERAL, any], () => {
        const [value, i2] = consumeOne(i, token);
        return [literal({value}), i2];
      }],
      [TOKEN_NAMES.LET, () => {
        const [[mutable, symbol], i2] = consume(i + 1, [
          {token: TOKEN_NAMES.MUT, optional: true},
          {token: [TOKEN_NAMES.SYMBOL, any]},
          {token: TOKEN_NAMES.ASSIGNMENT},
        ]);
        i = i2;
        const [expr, i3] = parseNode(tokens[i2]);
        i = i3;
        const [_, i4] = consumeOne(i3, TOKEN_NAMES.END_STATEMENT);
        return [assignment({mutable, symbol, expr}), i4];
      }],
      [TOKEN_NAMES.OPEN_PARAN, () => {
        // TODO: implement func args
        const [_, i2] = consume(i, [
          {token: TOKEN_NAMES.OPEN_PARAN},
          {token: TOKEN_NAMES.CLOSE_PARAN},
          {token: TOKEN_NAMES.ARROW},
        ]);
        i = i2;
        const [expr, i3] = parseNode(tokens[i2]);
        // TODO: implement non-expr body
        const body = [_return({expr})];
        return [_function({body}), i3];

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