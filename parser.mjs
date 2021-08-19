import {TOKEN_NAMES} from "./tokenizer.mjs";
import {match, any} from './utils.mjs';

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

const expression = () => ({

});

const parse = tokens => {
  const AST = {
    type: STATEMENT_TYPE.PROGRAM,
    body: []
  };
  let current = { type: null, };
  const clear = () => current = { type: null, };
  for (const token of tokens) {
    // console.log(token)
    match(token, [
      [TOKEN_NAMES.END_STATEMENT, () => {
        if (current.type === STATEMENT_TYPE.ASSIGNMENT) {
          AST.body.push(assignment(current));
        }
        clear();
      }],
      [TOKEN_NAMES.LET, () => {
        current.type = STATEMENT_TYPE.ASSIGNMENT
        // const [mutable, symbol, _] = consume([
        //   {type: TOKEN_NAMES.MUT, optional: true},
        //   {type: TOKEN_NAMES.SYMBOL},
        //   {type: TOKEN_NAMES.ASSIGNMENT},
        // ])
      }],
      [[TOKEN_NAMES.SYMBOL, any], ([_, sym]) => {
        if (current.type !== STATEMENT_TYPE.ASSIGNMENT) throw 'AHHHH';
        current.symbol = sym;
      }],
      [[TOKEN_NAMES.LITERAL, any], ([_, lit]) => {
        if (current.type !== STATEMENT_TYPE.ASSIGNMENT) throw 'AHHHH';
        current.value = lit;
      }]
    ]);
  }
  return AST;
};

export default parse;