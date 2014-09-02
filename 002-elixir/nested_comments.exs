defmodule NestedComments do

  def render({:ul, comments}) do
    """
    <ul>
    #{render(comments) |> indent}
    </ul>
    """
  end
  def render([{:li, comment}|comments]) do
    """
    <li>#{comment}</li>
    #{render(comments)}
    """
  end
  def render([{:li, comment, ul = {:ul, _}}|comments]) do
    """
    <li>#{comment}
    #{render(ul) |> indent}
    </li>
    #{render(comments)}
    """
  end
  def render([]) do
    ""
  end
  def render(comments) do
    render(structure(comments))
  end

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

  defp parent_of?(p1, p2) do
    String.starts_with? p2, p1
  end

  defp indent(content) do
    content
      |> String.split("\n", trim: true)
      |> Enum.map(&("  " <> &1))
      |> Enum.join("\n")
  end
end


ExUnit.start

defmodule NestedCommentsTest do
  use ExUnit.Case, async: true

  test ".append/2" do
    assert(
      {:ul, [
        {:li, "01"}
      ]}
      == (
        {:ul, []} |>
          NestedComments.append("01")
      )
    )

    assert(
      {:ul, [
        {:li, "01"},
        {:li, "02"}
      ]}
      == (
        {:ul, []} |>
          NestedComments.append("01") |>
          NestedComments.append("02")
      )
    )

    assert(
      {:ul, [
        {:li, "01", {:ul, [
          {:li, "01.01"}
        ]}}
      ]} == (
        {:ul, [{:li, "01"}]} |>
          NestedComments.append("01.01")
      )
    )

    assert(
      {:ul, [
        {:li, "01", {:ul, [
          {:li, "01.01"},
          {:li, "01.02"}
        ]}}
      ]} == (
        {:ul, [
          {:li, "01", {:ul, [
            {:li, "01.01"}
          ]}}
        ]} |>
          NestedComments.append("01.02")
      )
    )

    assert(
      {:ul, [
        {:li, "01", {:ul, [
          {:li, "01.01"}
        ]}},
        {:li, "02"}
      ]} == (
        {:ul, [
          {:li, "01", {:ul, [
            {:li, "01.01"}
          ]}}
        ]} |>
          NestedComments.append("02")
      )
    )
  end

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
