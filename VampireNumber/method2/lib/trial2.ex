defmodule Trial2 do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def handle_cast({:result, value}, state) do
    {:noreply, [value | state]}
  end

  def handle_call(:output, _from, state) do
    {:reply, state, state}
  end

  def init(state) do
    {:ok, state}
  end

  #### boss actor##########

  def boss(start_range, stop_range) do
    {:ok, pid} = Trial2.start_link()
    # IO.inspect(pid)
    dataset_size = abs(stop_range - start_range)
    no_dataset_size = round(div(dataset_size, 10))

    tasks =
      for x <- 1..no_dataset_size do
        Task.async(fn ->
          worker(start_range + (x - 1) * 10, start_range + x * 10 - 1, pid)
          x
        end)
      end

    Enum.map(tasks, fn x -> Task.await(x, :infinity) end)

    x = GenServer.call(pid, :output)
    # IO.puts("####################################")
    Enum.map(x, fn y -> IO.puts(y) end)
    # IO.inspect(x)
  end

  ########### worker actor ############

  def worker(start, stop, pid) do
    Enum.map(start..stop, fn x -> maincompute(x, pid) end)
  end

  def all_combinations([]), do: [[]]

  def all_combinations(number) do
    for head <- number,
        tail <- all_combinations(number -- [head]),
        do: [head | tail]
  end

  def maincompute(number, pid) do
    list_factors = [Integer.to_string(number)]

    x1 =
      Enum.map(all_combinations(Integer.to_charlist(number)), fn x ->
        length_list = length(Integer.to_charlist(number))

        if String.length(Integer.to_string(String.to_integer(List.to_string(x)))) == length_list do
          # IO.puts(div(String.to_integer(List.to_string(x)), :math.pow(10, 2) |> round))
          first_half = String.to_integer(List.to_string(Enum.slice(x, 0, div(length_list, 2))))

          last_half =
            String.to_integer(List.to_string(Enum.slice(x, div(length_list, 2), length_list)))

          if String.length(Integer.to_string(first_half)) ==
               String.length(Integer.to_string(last_half)) do
            product = first_half * last_half

            if String.at(
                 Integer.to_string(first_half),
                 String.length(Integer.to_string(first_half)) - 1
               ) ==
                 String.at(
                   Integer.to_string(last_half),
                   String.length(Integer.to_string(last_half)) - 1
                 ) and
                 String.at(
                   Integer.to_string(last_half),
                   String.length(Integer.to_string(last_half)) - 1
                 ) ==
                   "0" do
            else
              if product == number do
                if Enum.member?(list_factors, Integer.to_string(first_half)) do
                  # String.split
                  # IO.puts(first_half)
                else
                  Integer.to_string(first_half) <> " " <> Integer.to_string(last_half) <> " "
                  # [first_half, last_half]
                end
              end
            end
          end
        end
      end)

    # IO.inspect(Enum.uniq(Enum.reject(x1, fn x -> x == nil end)))
    all_factors = List.to_string(Enum.reject(x1, fn x -> x == nil end))
    factors = Enum.uniq(String.split(all_factors, " ", trim: true))

    if length(factors) > 0 do
      final = Enum.join(factors, " ")
      # IO.puts(Integer.to_string(number) <> " " <> final)
      final2 = Integer.to_string(number) <> " " <> final
      # final2
      # IO.inspect(pid)
      GenServer.cast(pid, {:result, final2})
    else
      # do nothing
    end
  end
end
