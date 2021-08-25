# Variables

# declaration
let a = 3;
print(a);

# mutable & assignment
let mut b = 'str';
print(b);
b = 5;
print(b);

# if statements

if (1 > 3) {
  print('nope');
} else {
  print('oh yea');
}

# ifs are expressions!

let three = if (3 > 1) 3;
print(three);

# arrays
let arr = [1, 2, 3];
print(arr[1]);

# functions
let function = (a) =>
  if (a == [1, 2]) print('we do deep value equality!');

function([1, 2]);

# objects

let obj = {
  a: 1,
  b: { c: 'three' }
};

let Person = (name) => {
  let obj1 = {
    name: name,
    print: () => print(obj1.name)
  };
  return obj1;
};

Person('Marcelle').print();

# pattern matching

let f = (arr) => match (arr) {
  [a, b, c] => a * b * c
};

print(f([1, 2, 3]));