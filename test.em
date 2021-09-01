let OPERATORS = {
  '==': {
    value: (a, b) => a == b
  }
};

print(OPERATORS['=='].value(1, 34));