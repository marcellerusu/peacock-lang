let users = [{ id: 3, country: 'canada', name: 'Marcelle' }];
let has_canadians = users
  |> List.map(Map.pick(['country']))
  |> List.includes({ country: 'canada' });
print(has_canadians);