defmodule Worker do
  use GenServer

  def start_link(x) do
    GenServer.start_link(Server, x)
  end

  def send_message(server) do
    GenServer.cast(server, {:send_message})
  end

  def job_timeout(pid) do
    # IO.inspect(pid)
    # IO.puts("hi")
    # IO.inspect(self())
    GenServer.cast(pid, {:job_timeout, pid})
  end

  def get_member(server) do
    GenServer.call(server, {:get_neighbors})
  end

  def get_ratio_difference(server) do
    GenServer.call(server, {:get_ratio_difference})
  end

  def get_count(server) do
    {:ok, count} = GenServer.call(server, {:get_count, "count"}, :infinity)
    count
  end

  def set_count(server) do
    {:ok} = GenServer.call(server, {:set_count, 0})
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def get_rumour(server) do
    {:ok, rumour} = GenServer.call(server, {:get_rumour, "rumour"})
    rumour
  end

  def has_members(server) do
    {:ok, neighbors} = GenServer.call(server, {:get_neighbors})
    length(neighbors) > 0
  end

  def send_message_push_sum(server) do
    GenServer.cast(server, {:send_message_push_sum})
  end

  def set_members(server, neighbors) do
    GenServer.cast(server, {:set_members, neighbors})
  end
end
