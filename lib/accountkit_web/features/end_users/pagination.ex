defmodule AccountkitWeb.Features.EndUsers.Pagination do
  @page_size 10

  def page_size, do: @page_size

  def paginate(items, page, page_size \\ @page_size) do
    total_entries = length(items)
    total_pages = max(ceil_div(total_entries, page_size), 1)
    page = page |> clamp(1, total_pages)

    %{
      entries: Enum.slice(items, (page - 1) * page_size, page_size),
      page: page,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages,
      pages: page_window(page, total_pages)
    }
  end

  def page_window(_page, total_pages) when total_pages <= 7, do: Enum.to_list(1..total_pages)

  def page_window(page, total_pages) do
    pages =
      ([1, total_pages] ++ Enum.to_list(max(page - 1, 1)..min(page + 1, total_pages)))
      |> Enum.uniq()
      |> Enum.sort()

    pages
    |> Enum.reduce([], fn page, acc ->
      case acc do
        [] ->
          [page]

        [previous | _] when page == previous + 1 ->
          [page | acc]

        _ ->
          [page, :ellipsis | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp clamp(value, min, _max) when value < min, do: min
  defp clamp(value, _min, max) when value > max, do: max
  defp clamp(value, _min, _max), do: value

  defp ceil_div(0, _divisor), do: 0
  defp ceil_div(value, divisor), do: div(value + divisor - 1, divisor)
end
