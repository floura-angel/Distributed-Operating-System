defmodule Boss do
  use GenServer

  def init(vampirenumber) do
    {:ok, vampirenumber}
  end

  def handle_cast({:result, value}, state) do
    {:noreply, [value | state]}
  end

  def handle_call(:output, _from, state) do
    {:reply, state, state}
  end

  def handle_info(msg, state) do
    Enum.map(msg, fn x -> IO.puts(x) end)
    # IO.puts("#{msg}")
    {:noreply, state}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def main(start_range, stop_range) do
    {:ok, pid} = Boss.start_link()
    dataset_size = abs(stop_range - start_range)
    no_dataset_size = round(div(dataset_size, 10))
    # IO.inspect(pid)

    # Enum.map(1..no_dataset_size, fn x ->
    #   # IO.inspect(x)
    #   spawn_link(fn ->
    #     Trial2.worker(start_range + (x - 1) * 10, start_range + x * 10 - 1, pid)
    #   end)
    # end)
    tasks =
      for x <- 1..no_dataset_size do
        Task.async(fn ->
          # IO.puts(x)
          Worker.main(start_range + (x - 1) * 10, start_range + x * 10 - 1, pid)
          x
        end)
      end

    Enum.map(tasks, fn x -> Task.await(x, :infinity) end)
  end
end
