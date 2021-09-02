let nine = [1, 2, 3]
  |> List.map(x => x * x)
  |> List.filter(x => x > 2)
  |> List.find(x => x == 9);
 
print(nine);