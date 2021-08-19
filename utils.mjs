
const eqArr = (a1, a2) =>
  a1.length === a2.length && a1.every((x, i) => eq(x, a2[i]));


export const eq = (a, b) => {
  if (a === any || b === any) {
    return true;
  }
  if (a === b) {
    return true;
  } else if (Array.isArray(a) && Array.isArray(a)) {
    return eqArr(a, b);
  } else {
    const aKeys = Object.keys(a);
    if (aKeys.length !== Object.keys(b).length) return false;
    return aKeys.every(k => eq(a[k], b[k]));
  }
}

export const match = (val, branches) => {
  const res = branches.find(([expr]) => eq(val, expr));
  if (!res) return;
  const [_, fn] = res;
  return fn(val);
}

export const any = 'ANY';

// match(v, [
//   [[1, 2], 3]
// ])