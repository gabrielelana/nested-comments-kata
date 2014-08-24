# run it with `elixir 001-elixir/nested_comments.exs`

defmodule NestedComments do
  def render(comments) do
    render_structure(structure(comments))
  end

  defp render_structure({:ul, comments}) do
    """
    <ul>
    #{render_structure(comments) |> indent}
    </ul>
    """
  end
  defp render_structure([{:li, comment}|comments]) do
    """
    <li>#{comment}</li>
    #{render_structure(comments)}
    """
  end
  defp render_structure([{:li, comment, ul = {:ul, _}}|comments]) do
    """
    <li>#{comment}
    #{render_structure(ul) |> indent}
    </li>
    #{render_structure(comments)}
    """
  end
  defp render_structure([]) do
    ""
  end

  defp indent(content) do
    content
      |> String.split("\n", trim: true)
      |> Enum.map(&("  " <> &1))
      |> Enum.join("\n")
  end

  def structure(comments) do
    {_, ul} = structure(comments, []); {:ul, ul}
  end

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
