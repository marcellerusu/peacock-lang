import {TOKEN_NAMES} from "./tokenizer.mjs";
import {match, any, eq} from './utils.mjs';

export const STATEMENT_TYPE = {
  ASSIGNMENT: 'ASSIGNMENT',
  FUNCTION: 'FUNCTION',
  RETURN: 'RETURN',
  PROGRAM: 'PROGRAM',
};

export const assignment = ({symbol, value, mutable}) => ({
  type: STATEMENT_TYPE.ASSIGNMENT,
  mutable: !!mutable,
  symbol,
  value
});

export const _function = ({paramNames, body}) => ({
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
      } else throw "JESSE ALARCON";
    } else {
      tokenValue = match(token, [
        [[TOKEN_NAMES.SYMBOL, any], ([_, sym]) => sym],
        [[TOKEN_NAMES.LITERAL, any], ([_, lit]) => lit],
      ]);
    }
    if (typeof tokenValue !== 'undefined') tokenValues.push(tokenValue);
  }
  return [tokenValues, i];
}

const parse = tokens => {
  const consume = makeConsumer(tokens);
  const AST = { type: STATEMENT_TYPE.PROGRAM, body: [], };
  for (let i = 0; i < tokens.length; i++) {
    match(tokens[i], [
      [TOKEN_NAMES.LET, () => {
        const [[mutable, symbol, value], newIndex] = consume(i + 1, [
          {token: TOKEN_NAMES.MUT, optional: true},
          {token: [TOKEN_NAMES.SYMBOL, any]},
          {token: TOKEN_NAMES.ASSIGNMENT},
          {token: [TOKEN_NAMES.LITERAL, any]},
          {token: TOKEN_NAMES.END_STATEMENT}
        ]);
        i = newIndex;
        AST.body.push(assignment({mutable, symbol, value}));
      }],
    ]);
  }
  return AST;
};

export default parse;