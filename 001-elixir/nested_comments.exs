
defmodule NestedComments do
  def render(comments) do
    render(structure(comments), 0)
  end

  defp render({:ul, comments}, level) do
    String.duplicate(" ", level*2) <> "<ul>\n" <>
    render(comments, level+1) <>
    String.duplicate(" ", level*2) <> "</ul>\n"
  end
  defp render([{:li, comment}|comments], level) do
    String.duplicate(" ", level*2) <> "<li>" <> comment <> "</li>\n" <> render(comments, level)
  end
  defp render([{:li, comment, ul = {:ul, _}}|comments], level) do
    String.duplicate(" ", level*2) <> "<li>" <> comment <> "\n" <>
    render(ul, level + 1) <>
    String.duplicate(" ", level*2) <> "</li>\n" <>
    render(comments, level)
  end
  defp render([], _) do
    ""
  end

  def structure(comments) do
    {_, ul} = structure(comments, [], nil); {:ul, ul}
  end

  defp structure(comments, structured, parent_id) do
    case comments do
      [] ->
        {[], Enum.reverse(structured)}
      [[_id, ^parent_id, message] | []] ->
        {[], Enum.reverse([{:li, message} | structured])}
      [[_id, ^parent_id, message], next = [_, ^parent_id, _] | comments] ->
        structure([next|comments], [{:li, message} | structured], parent_id)
      [[id, _parent_id, message], next = [_, id, _] | comments] ->
        {comments, ul} = structure([next|comments], [], id)
        structure(comments, [{:li, message, {:ul, ul}} | structured], parent_id)
      [[id, _parent_id, message], next = [_, _, _] | comments] ->
        {[next|comments], Enum.reverse([{:li, message} | structured])}
    end
  end
end


ExUnit.start

defmodule AssertionTest do
  use ExUnit.Case, async: true

  test "flat list" do
    assert {:ul, [
      {:li, "0001"},
      {:li, "0002"}
    ]} == NestedComments.structure([
      [1,  nil, "0001"],
      [2,  nil, "0002"]
    ])
  end

  test "last nested" do
    assert {:ul, [
      {:li, "0001"},
      {:li, "0002", {:ul, [
        {:li, "0002.0001"}
      ]}}
    ]} == NestedComments.structure([
      [1,  nil, "0001"],
      [2,  nil, "0002"],
      [3,  2,   "0002.0001"]
    ])
  end

  test "nested in the middle" do
    assert {:ul, [
      {:li, "0001"},
      {:li, "0002", {:ul, [
        {:li, "0002.0001"}
      ]}},
      {:li, "0003"},
    ]} == NestedComments.structure([
      [1,  nil, "0001"],
      [2,  nil, "0002"],
      [3,  2,   "0002.0001"],
      [4,  nil, "0003"]
    ])
  end

  test "deep nested" do
    assert {:ul, [
      {:li, "0001"},
      {:li, "0002", {:ul, [
        {:li, "0002.0001"}
      ]}},
      {:li, "0003", {:ul, [
        {:li, "0003.0001"},
        {:li, "0003.0002"}
      ]}},
      {:li, "0004"},
      {:li, "0005", {:ul, [
        {:li, "0005.0001", {:ul, [
          {:li, "0005.0001.0001"}
        ]}},
        {:li, "0005.0002"},
        {:li, "0005.0005"},
        {:li, "0005.0006"}
      ]}},
    ]} == NestedComments.structure([
      [1,  nil, "0001"],
      [2,  nil, "0002"],
      [3,  2,   "0002.0001"],
      [4,  nil, "0003"],
      [5,  4,   "0003.0001"],
      [6,  4,   "0003.0002"],
      [7,  nil, "0004"],
      [8,  nil, "0005"],
      [9,  8,   "0005.0001"],
      [10, 9,   "0005.0001.0001"],
      [11, 8,   "0005.0002"],
      [12, 8,   "0005.0005"],
      [13, 8,   "0005.0006"],
    ])
  end

  test "render deep nested comments" do
    assert """
    <ul>
      <li>0001</li>
      <li>0002
        <ul>
          <li>0002.0001</li>
        </ul>
      </li>
      <li>0003
        <ul>
          <li>0003.0001</li>
          <li>0003.0002</li>
        </ul>
      </li>
      <li>0004</li>
      <li>0005
        <ul>
          <li>0005.0001
            <ul>
              <li>0005.0001.0001</li>
            </ul>
          </li>
          <li>0005.0002</li>
          <li>0005.0005</li>
          <li>0005.0006</li>
        </ul>
      </li>
    </ul>
    """ == NestedComments.render([
      [1,  nil, "0001"],
      [2,  nil, "0002"],
      [3,  2,   "0002.0001"],
      [4,  nil, "0003"],
      [5,  4,   "0003.0001"],
      [6,  4,   "0003.0002"],
      [7,  nil, "0004"],
      [8,  nil, "0005"],
      [9,  8,   "0005.0001"],
      [10, 9,   "0005.0001.0001"],
      [11, 8,   "0005.0002"],
      [12, 8,   "0005.0005"],
      [13, 8,   "0005.0006"],
    ])
  end
end
