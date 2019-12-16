defmodule Server do
  use GenServer

  def init(x) do
    if is_list(x) do
      default = 1

      {:ok,
       %{
         "s" => Enum.at(x, 0),
         "rumour" => Enum.at(x, length(x) - 1),
         "w" => 1,
         "s_before_2" => default,
         "w_before_2" => default,
         "s_before_3" => default,
         "w_before_3" => default,
         "ratio_difference" => default,
         "ratio_difference2" => default,
         "ratio_difference3" => default,
         "neighbors" => []
       }}
    else
      {:ok, %{"rumour" => x, "count" => 0, "neighbors" => []}}
    end
  end

  # ------------------------kill if neighbor dead---------------
  def kill_if_neighbor_dead(map, process_id) do
    x = Map.values(map)
    count = 0

    Enum.each(x, fn y ->
      Enum.each(y, fn z ->
        count =
          if z == process_id do
            count = 1
          else
            count = 0
          end
      end)
    end)

    # if count == 0 do
    #   _ = GenServer.cast(sender, {:remove_neighbor, self()})
    #   {:noreply, state}
    # end
  end

  # -------------------------   Handle message for Gossip Algorithm   -------------------------
  def handle_cast({:receive_message, rumour, sender}, state) do
    {:ok, count} = Map.fetch(state, "count")
    state = Map.put(state, "count", count + 1)

    if count > 10 do
      _ = GenServer.cast(sender, {:remove_neighbor, self()})
      {:noreply, state}
    else
      {:ok, existing_rumour} = Map.fetch(state, "rumour")

      if(existing_rumour != "") do
        {:noreply, state}
      else
        [{_, rumor_reached}] = :ets.lookup(:count, "rumor_reached")
        :ets.insert(:count, {"rumor_reached", rumor_reached + 1})
        {:noreply, Map.put(state, "rumour", rumour)}
      end
    end
  end

  # -------------------------   Handle message for Push-sum Algorithm   -------------------------
  def handle_cast({:receive_message_push_sum, sender, s, w, rumour}, state) do
    {:ok, s_before} = Map.fetch(state, "s")
    {:ok, w_before} = Map.fetch(state, "w")

    {:ok, s_before_2} = Map.fetch(state, "s_before_2")
    {:ok, w_before_2} = Map.fetch(state, "w_before_2")

    {:ok, existing_rumour} = Map.fetch(state, "rumour")

    {:ok, s_before_3} = Map.fetch(state, "s_before_3")
    {:ok, w_before_3} = Map.fetch(state, "w_before_3")
    # IO.inspect(Map.fetch(state, "s"))

    s_after = s_before + s
    w_after = w_before + w

    # IO.inspect(s_after / w_after - s_before / w_before_2)

    if abs(s_after / w_after - s_before / w_before) < :math.pow(10, -10) &&
         abs(s_before / w_before - s_before_2 / w_before_2) < :math.pow(10, -10) &&
         abs(s_before_2 / w_before_2 - s_before_3 / w_before_3) <
           :math.pow(10, -10) do
      GenServer.cast(sender, {:remove_neighbor, self()})
    else
      Map.put(state, "s_before_3", s_before_2)
      Map.put(state, "w_before_3", w_before_2)

      Map.put(state, "s", s_after)
      Map.put(state, "w", w_after)

      Map.put(state, "s_before_2", s_before)
      Map.put(state, "w_before_2", w_before)

      Map.put(state, "ratio_difference", s_after / w_after - s_before / w_before)
      Map.put(state, "ratio_difference2", s_before / w_before - s_before_2 / w_before_2)
      Map.put(state, "ratio_difference3", s_before_2 / w_before_2 - s_before_3 / w_before_3)

      if existing_rumour == "" do
        Map.put(state, "rumour", rumour)
        [{_, rumor_reached}] = :ets.lookup(:count, "rumor_reached")
        :ets.insert(:count, {"rumor_reached", rumor_reached + 1})

        {:noreply, state}
      else
        {:noreply, state}
      end
    end
  end

  # -------------------------   Gossip Algorithm   -------------------------
  def handle_cast({:send_message}, state) do
    {:ok, rumour} = Map.fetch(state, "rumour")
    {:ok, neighbors} = Map.fetch(state, "neighbors")

    if rumour != "" && length(neighbors) > 0 do
      _ = GenServer.cast(Enum.random(neighbors), {:receive_message, rumour, self()})
    end

    {:noreply, state}
  end

  # -------------------------   Push-sum Algorithm   -------------------------
  def handle_cast({:send_message_push_sum}, state) do
    {:ok, rumour} = Map.fetch(state, "rumour")
    {:ok, neighbors} = Map.fetch(state, "neighbors")
    #### values needed to send message through pushsum###

    {:ok, s} = Map.fetch(state, "s")
    {:ok, w} = Map.fetch(state, "w")

    if rumour != "" && length(neighbors) > 0 do
      s = s / 2
      w = w / 2
      state = Map.put(state, "s", s)
      state = Map.put(state, "w", w)
      GenServer.cast(Enum.random(neighbors), {:receive_message_push_sum, self(), s, w, rumour})
    end

    {:noreply, state}
  end

  def handle_cast({:set_members, neighbors}, state) do
    {:noreply, Map.put(state, "neighbors", neighbors)}
  end

  def handle_call({:get_count, count}, _from, state) do
    {:reply, Map.fetch(state, count), state}
  end

  # -------------------------------stop process-----------------
  def handle_cast({:job_timeout, pid}, state) do
    # IO.inspect(self())
    # IO.puts("hi2")
    {:ok, neighbors} = Map.fetch(state, "neighbors")
    # IO.inspect(neighbors)
    GenServer.cast(self(), {:remove_neighbor, neighbors})
    # _ = GenServer.cast(pid, {:remove_neighbor, self()})
    {:noreply, state}
  end

  # --------------------------------------------------------------

  def handle_cast({:remove_neighbor, neighbor}, state) do
    {:ok, neighbors} = Map.fetch(state, "neighbors")
    {:noreply, Map.put(state, "neighbors", List.delete(neighbors, neighbor))}
  end

  def handle_call({:get_rumour, rumour}, _from, state) do
    {:reply, Map.fetch(state, rumour), state}
  end

  def handle_call({:get_neighbors}, _from, state) do
    {:reply, Map.fetch(state, "neighbors"), state}
  end

  def handle_call({:set_count, value}, _from, state) do
    {:reply, Map.fetch(state, "rumor_reached"), state}
  end

  def handle_call({:get_ratio_difference}, _from, state) do
    {:ok, ratio_difference} = Map.fetch(state, "ratio_difference")
    {:ok, ratio_difference2} = Map.fetch(state, "ratio_difference2")
    {:ok, ratio_difference3} = Map.fetch(state, "ratio_difference3")
    {:reply, [ratio_difference] ++ [ratio_difference2] ++ [ratio_difference3], state}
  end
end
