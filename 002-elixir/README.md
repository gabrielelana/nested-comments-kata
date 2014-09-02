## Nested Comment Kata solution in Elixir

Alternative solution to `001-elixir`, I'm not satisfied by the readability of the previous solution, the code is compact but it's obscure, I don't know if it's because of the lookahead but sure you need to check for many edge cases and the logic is not straightforward

```elixir
defp structure(comments, structured) do
  case comments do
    [] ->
      {[], Enum.reverse(structured)}
    [[_, parent_id, message], next = [_, parent_id, _] | comments] ->
      structure([next|comments], [{:li, message} | structured])
    [[id, _, message], next = [_, id, _] | comments] ->
      {comments, ul} = structure([next|comments], [])
      structure(comments, [{:li, message, {:ul, ul}} | structured])
    [[_, _, message], next = [_, _, _] | comments] ->
      {[next|comments], Enum.reverse([{:li, message} | structured])}
    [[_, _, message] | []] ->
      {[], Enum.reverse([{:li, message} | structured])}
  end
end
```

So, I tried to make it more readable with another approach, more iterative without lookahead: You'll reduce the comments "appending" the current comment to the structured representation (same as the previous solution). This solution is more inefficient (you need to "traverse" the structure every time so the complexity is more than linear in the number of comments) by I think it's more readable

```elixir
def structure(comments) do
  Enum.reduce(comments, {:ul, []}, fn([_, _, path], structured) ->
    append(structured, path)
  end)
end

def append({:ul, list}, path) do
  {:ul, append(list, path)}
end
def append([], path) do
  [{:li, path}]
end
def append([head = {:li, p1}|tail], p2) do
  cond do
    parent_of?(p1, p2) -> [{:li, p1, {:ul, [{:li, p2}]}}|tail]
    true -> [head|append(tail, p2)]
  end
end
def append([head = {:li, p1, {:ul, ul}}|tail], p2) do
  cond do
    parent_of?(p1, p2) -> [{:li, p1, {:ul, append(ul, p2)}}|tail]
    true -> [head|append(tail, p2)]
  end
end
```
