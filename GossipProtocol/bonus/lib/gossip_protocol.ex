defmodule Gossip_Protocol do
  # -----------------------------------Failure of nodes--------------------------
  def failure(percentage, actors) do
    if percentage > 0 do
      indexed_actors =
        Stream.with_index(actors, 1)
        |> Enum.reduce(%{}, fn {y, magicN}, acc -> Map.put(acc, magicN, y) end)

      # IO.puts(trunc(percentage / 100 * map_size(indexed_actors)))
      # IO.puts(length(actors))
      # IO.puts(map_size(indexed_actors))
      num = trunc(percentage / 100 * map_size(indexed_actors))
      # IO.puts(num)
      ## -- list of nodes to delete---
      list =
        if num > 1 do
          list =
            Enum.map(1..num, fn i ->
              :rand.uniform(num)
            end)
        else
          if num == 1 do
            list = [1]
          else
            IO.puts("not enough actors alive")
          end
        end

      # IO.inspect(list)
      no_dup = Enum.uniq(list)

      Enum.map(no_dup, fn i ->
        {:ok, n} = Map.fetch(indexed_actors, i)
        # IO.inspect(self())
        # IO.puts("hi")
        # Process.exit(n, :normal)
        if Process.alive?(n) do
          Worker.job_timeout(n)
          # Process.exit(n, :normal)
        end

        # IO.inspect(Process.alive?(n))
        # Process.exit(n, :kill)
      end)
    else
    end
  end

  # ---------------------------------------main----------------------------------------

  def main(arg1, arg2, arg3, arg4) do
    numberNodes = arg1

    if numberNodes > 0 do
      topology = arg2
      algo = arg3
      failure_percentage = arg4

      if algo == "gossip" do
        IO.puts("Gossip algorithm")
        nodes_worker = initialize_nodes(numberNodes)
        init_algorithm(nodes_worker, topology, numberNodes, algo, failure_percentage)
      else
        if algo == "push-sum" do
          IO.puts("Push-Sum algorithm")
          nodes_worker = initialize_nodes_push_sum(numberNodes)
          init_algorithm(nodes_worker, topology, numberNodes, algo, failure_percentage)
        else
          IO.puts("Wrong arguments")
          System.halt(0)
        end
      end
    end
  end

  #  --------------------    gossip protocol   --------------------
  def initialize_nodes(numberNodes) do
    midNode = trunc(numberNodes / 2)

    Enum.map(1..numberNodes, fn x ->
      {:ok, actor} =
        cond do
          x == midNode -> Worker.start_link("The earth revolves around the moon")
          true -> Worker.start_link("")
        end

      actor
    end)
  end

  #  -------------------------------   Verify topology requested   -------------------------------
  def init_algorithm(nodes_worker, topology, numberNodes, algo, failure_percentage) do
    :ets.new(:count, [:set, :public, :named_table])
    :ets.insert(:count, {"rumor_reached", 0})

    # Determine Neighbor nodes as per requested topology
    members =
      case topology do
        "full" ->
          IO.puts("full topology")
          _members = build_full(nodes_worker)

        "honeycomb" ->
          IO.puts("Honeycomb topology")
          _members = honeycomb(nodes_worker, topology)

        "randhoneycomb" ->
          IO.puts("Random Honeycomb topology")
          _members = honeycomb(nodes_worker, topology)

        "rand2D" ->
          IO.puts("Random 2D topology")
          _members = build_2D(nodes_worker, topology)

        "3Dtorus" ->
          IO.puts("3D torus topology")
          _neigbours = build_torus(nodes_worker)

        "line" ->
          IO.puts("line topology")
          _members = build_line(nodes_worker, topology)

        _ ->
          IO.puts("Wrong topology")
          System.halt(0)
      end

    set_members(members)
    prev = System.monotonic_time(:millisecond)

    if algo == "gossip" do
      # call gossip algorithm
      gossip(nodes_worker, members, numberNodes, gossip_count = 0, failure_percentage)
    else
      # call push-sum algorithm
      push_sum(nodes_worker, members, numberNodes, gossip_count = 0, failure_percentage)
    end

    IO.puts(
      "Convergence Time: " <> to_string(System.monotonic_time(:millisecond) - prev) <> " ms"
    )

    System.halt(0)
  end

  #  --------------------   Push-sum   --------------------
  def initialize_nodes_push_sum(numberNodes) do
    midNode = trunc(numberNodes / 2)

    Enum.map(
      1..numberNodes,
      fn x ->
        {:ok, actor} =
          cond do
            x == midNode ->
              x = Integer.to_string(x)
              {x, _} = Float.parse(x)
              Worker.start_link([x] ++ ["The earth revolves around the moon"])

            true ->
              x = Integer.to_string(x)
              {x, _} = Float.parse(x)
              Worker.start_link([x] ++ [""])
          end

        actor
      end
    )
  end

  #  -------------------------------   Start Gossip   -------------------------------  
  def gossip(nodes_worker, members, numberNodes, gossip_count, failure_percentage) do
    # for  {list_members, y}  <-  members  do
    for {list_members, _} <- members do
      Worker.send_message(list_members)
    end

    # IO.inspect(nodes_worker)
    # IO.inspect(trunc(numberNodes / 3))

    # IO.inspect("hi")
    # IO.inspect(length(numberNodes))

    if gossip_count == trunc(numberNodes / 5) do
      # IO.inspect(nodes_worker)
      failure(failure_percentage, nodes_worker)
    end

    nodes_worker = gossip_alive(nodes_worker)
    [{_, rumor_reached}] = :ets.lookup(:count, "rumor_reached")

    if rumor_reached != numberNodes && length(nodes_worker) > 1 do
      members =
        Enum.filter(members, fn {list_members, _} ->
          Enum.member?(nodes_worker, list_members)
        end)

      Process.sleep(10)
      gossip(nodes_worker, members, numberNodes, gossip_count + 1, failure_percentage)
    end
  end

  def gossip_alive(nodes_worker) do
    this_nodes_worker =
      Enum.map(nodes_worker, fn x ->
        if Process.alive?(x) && Worker.get_count(x) < 10 && Worker.has_members(x) do
          x
        end
      end)

    List.delete(Enum.uniq(this_nodes_worker), nil)
  end

  #  ---------------------   Start Push Sum   ---------------------
  def push_sum(nodes_worker, members, numberNodes, gossip_count, failure_percentage) do
    # for  {list_members, y}  <-  members  do
    for {list_members, _} <- members do
      Worker.send_message_push_sum(list_members)
    end

    if gossip_count == trunc(numberNodes / 3) do
      failure(failure_percentage, nodes_worker)
    end

    nodes_worker = pushsum_alive(nodes_worker)
    [{_, rumor_reached}] = :ets.lookup(:count, "rumor_reached")

    if rumor_reached != numberNodes && length(nodes_worker) > 1 do
      members =
        Enum.filter(members, fn {list_members, _} ->
          Enum.member?(nodes_worker, list_members)
        end)

      Process.sleep(10)
      push_sum(nodes_worker, members, numberNodes, gossip_count + 1, failure_percentage)
    end
  end

  def pushsum_alive(nodes_worker) do
    this_nodes_worker =
      Enum.map(
        nodes_worker,
        fn x ->
          ratio_difference = Worker.get_ratio_difference(x)

          if(
            Process.alive?(x) && Worker.has_members(x) &&
              (abs(Enum.at(ratio_difference, 0)) > :math.pow(10, -10) ||
                 abs(Enum.at(ratio_difference, 1)) > :math.pow(10, -10) ||
                 abs(Enum.at(ratio_difference, 2)) > :math.pow(10, -10))
          ) do
            x
          end
        end
      )

    List.delete(Enum.uniq(this_nodes_worker), nil)
  end

  #  ---------------------   Determine neighbor nodes for full topology  ---------------------
  def build_full(nodes_worker) do
    # IO.inspect(nodes_worker)

    nodes =
      Enum.reduce(nodes_worker, %{}, fn x, acc ->
        Map.put(acc, x, Enum.filter(nodes_worker, fn y -> y != x end))
      end)

    # IO.inspect(nodes)
  end

  #  ---------------------   Determine neighbor nodes for line topology  ---------------------
  def build_line(nodes_worker, topology) do
    indexed_nodes_worker =
      Stream.with_index(nodes_worker, 1)
      |> Enum.reduce(%{}, fn {y, list_members}, acc -> Map.put(acc, list_members, y) end)

    n = length(nodes_worker)

    Enum.reduce(1..n, %{}, fn x, acc ->
      members =
        if x == 1 do
          [x + 1]
        else
          if x == n do
            [x - 1]
          else
            [x - 1, x + 1]
          end
        end

      member_ids =
        Enum.map(members, fn i ->
          {:ok, n} = Map.fetch(indexed_nodes_worker, i)
          n
        end)

      {:ok, actor} = Map.fetch(indexed_nodes_worker, x)
      Map.put(acc, actor, member_ids)
    end)
  end

  #  ---------------------   Rand & Honeycomb topology  ---------------------
  def honeycomb(nodes_worker, topology) do
    num1 = length(nodes_worker)

    if num1 < 16 do
      IO.puts("Too less nodes,minimum 16 nodes")
    else
      indexed_nodes_worker =
        Stream.with_index(nodes_worker, 1)
        |> Enum.reduce(%{}, fn {y, list_members}, acc -> Map.put(acc, list_members, y) end)

      num = num1 / 18
      numNodes = trunc(num) * 18
      numNodes = trunc(numNodes)

      Enum.reduce(1..numNodes, %{}, fn x, acc ->
        positivex =
          if rem(x, 9) != 0 && x + 1 <= numNodes do
            x + 1
          end

        negativex =
          if rem(x, 9) != 1 do
            x - 1
          end

        negativey =
          if rem(x, 2) != 0 && x + 9 <= numNodes do
            x + 9
          else
            if rem(x, 2) == 0 && x - 9 > 0 do
              x - 9
            end
          end

        nodes_in_list = [positivex, negativex, negativey]

        nodes_in_list =
          case topology do
            "randhoneycomb" ->
              nodes_in_list ++ pick_a_node(nodes_in_list, x, numNodes)

            _ ->
              nodes_in_list
          end

        list1 = Enum.filter(nodes_in_list, fn x -> x != [] end)
        list = Enum.reject(list1, fn x -> x == nil end)

        member_ids =
          Enum.map(list, fn i ->
            {:ok, n} = Map.fetch(indexed_nodes_worker, i)
            n
          end)

        {:ok, actor} = Map.fetch(indexed_nodes_worker, x)
        Map.put(acc, actor, member_ids)
      end)

      # Enum.reduce(1..num, %{}, fn i, acc ->
      #   if i < num do
      #     members =
      #       if div(i, sqrt) == 0 do
      #         if rem(i, 2) == 1 do
      #           if i + sqrt < num do
      #             [i + 1, i + sqrt]
      #           else
      #             [i + 1]
      #           end
      #         else
      #           if i + sqrt < num do
      #             [i - 1, i + sqrt]
      #           else
      #             [i - 1]
      #           end
      #         end
      #       else
      #         if i == sqrt do
      #           [i - 1, i + sqrt]
      #         else
      #           if rem(div(i, sqrt) + 1, 2) == 0 do
      #             if i == div(i, sqrt) * sqrt + 1 or i == div(i, sqrt) * sqrt do
      #               if i + sqrt < num do
      #                 [i + sqrt, i - sqrt]
      #               else
      #                 [i - sqrt]
      #               end
      #             else
      #               if rem(i, 2) == 0 do
      #                 if i + sqrt < num do
      #                   [i + sqrt, i - sqrt, i + 1]
      #                 else
      #                   [i - sqrt, i + 1]
      #                 end
      #               else
      #                 if i + sqrt < num do
      #                   [i + sqrt, i - sqrt, i - 1]
      #                 else
      #                   [i - sqrt, i - 1]
      #                 end
      #               end
      #             end
      #           else
      #             if i == div(i, sqrt) * sqrt + 1 or i == div(i, sqrt) * sqrt do
      #               if i + sqrt < num do
      #                 [i + sqrt, i - sqrt]
      #               else
      #                 [i - sqrt]
      #               end
      #             else
      #               if rem(i, 2) == 0 do
      #                 if i + sqrt < num do
      #                   [i + sqrt, i - sqrt, i - 1]
      #                 else
      #                   [i - sqrt, i - 1]
      #                 end
      #               else
      #                 if i + sqrt < num do
      #                   [i + sqrt, i - sqrt, i + 1]
      #                 else
      #                   [i - sqrt, i + 1]
      #                 end
      #               end
      #             end
      #           end
      #         end
      #       end

      #     members =
      #       case topology do
      #         "randhoneycomb" ->
      #           members ++ pick_a_node(members, i, num)

      #         _ ->
      #           members
      #       end

      #     all_members = Enum.filter(members, fn x -> x != [] end)

      #     # all_members = Enum.reject(members, fn x -> x == nil end)

      #     member_ids =
      #       Enum.map(all_members, fn x ->
      #         if x < num do
      #           {:ok, n} = Map.fetch(indexed_nodes_worker, x)
      #           # IO.inspect(x)
      #           n
      #         else
      #           []
      #         end
      #       end)

      #     all_member_ids = Enum.filter(member_ids, fn x -> x != [] end)

      #     {:ok, actor} = Map.fetch(indexed_nodes_worker, i)
      #     Map.put(acc, actor, all_member_ids)
      #   else
      #     acc
      #   end
      # end)
    end
  end

  #  ---------------------   2D topology  ---------------------
  def build_2D(nodes_worker, topology) do
    n = length(nodes_worker)

    if n < 10 do
      IO.puts("Too less nodes,minimum 10nodes")
    else
      indexed_nodes_worker =
        Stream.with_index(nodes_worker, 1)
        |> Enum.reduce(%{}, fn {y, list_members}, acc -> Map.put(acc, list_members, y) end)

      distance = 1 / (n * 10)

      list_nodes =
        Enum.map(1..n, fn x ->
          {x, x * distance, x * distance}
        end)

      # IO.inspect(list_nodes)

      members =
        Enum.reduce(list_nodes, %{}, fn {point1, x1, y1}, accu ->
          per_node =
            Enum.reduce(list_nodes, [], fn {point2, x2, y2}, acc ->
              x_cordinate = :math.pow(x1 - x2, 2)
              y_cordinate = :math.pow(y1 - y2, 2)
              # IO.inspect(:math.sqrt(x_cordinate + y_cordinate))

              if point1 != point2 and :math.sqrt(x_cordinate + y_cordinate) <= 0.1 do
                [point2 | acc]
              else
                acc
              end
            end)
            |> Enum.reverse()

          all_members = per_node

          member_ids =
            Enum.map(all_members, fn x ->
              {:ok, n} = Map.fetch(indexed_nodes_worker, x)
              n
            end)

          all_member_ids = Enum.filter(member_ids, fn x -> x != [] end)

          {:ok, actor} = Map.fetch(indexed_nodes_worker, point1)
          Map.put(accu, actor, all_member_ids)
        end)
    end
  end

  #  --------   rand --------
  def pick_a_node(members, i, numberNodes) do
    random_node_index = :rand.uniform(numberNodes)
    members = members ++ [i]

    if(Enum.member?(members, random_node_index)) do
      pick_a_node(members, i, numberNodes)
    else
      [random_node_index]
    end
  end

  #  ---------------------   Torus topology  ---------------------
  def build_torus(nodes_worker) do
    n = length(nodes_worker)

    indexed_nodes_worker =
      Stream.with_index(nodes_worker, 1)
      |> Enum.reduce(%{}, fn {y, list_members}, acc -> Map.put(acc, list_members, y) end)

    cubic = root(3, n)
    numNodes = cubic * cubic * cubic
    # colmcnt = rowcnt * rowcnt
    Enum.reduce(1..numNodes, %{}, fn x, acc ->
      # Enum.map(0..(numNodes - 1), fn x ->
      if x < numNodes do
        posX =
          if(x + 1 <= numNodes && rem(x, cubic) != 0) do
            x + 1
          else
            cubic * round(Float.floor((x - 1) / cubic)) + 1
          end

        posY =
          if(
            rem(x, cubic * cubic) != 0 &&
              cubic * cubic - cubic >= rem(x, cubic * cubic)
          ) do
            x + cubic
          else
            x - cubic * (cubic - 1)
          end

        posZ =
          if(x + cubic * cubic <= numNodes) do
            x + cubic * cubic
          else
            x - cubic * cubic * (cubic - 1)
          end

        negX =
          if(x - 1 >= 1 && rem(x - 1, cubic) != 0) do
            x - 1
          else
            round(cubic * Float.ceil(x / cubic))
          end

        negY =
          if(cubic * cubic - cubic * (cubic - 1) < rem(x - 1, cubic * cubic) + 1) do
            x - cubic
          else
            x + cubic * (cubic - 1)
          end

        negZ =
          if(x - cubic * cubic >= 1) do
            x - cubic * cubic
          else
            x + cubic * cubic * (cubic - 1)
          end

        members = [posX, posY, posZ, negX, negY, negZ]

        member_ids =
          Enum.map(members, fn i ->
            {:ok, n} = Map.fetch(indexed_nodes_worker, i)
            n
          end)

        {:ok, actor} = Map.fetch(indexed_nodes_worker, x)
        Map.put(acc, actor, member_ids)
      else
        acc
      end
    end)
  end

  #  ------------------------   Set members  ------------------------
  def set_members(members) do
    for {list_members, y} <- members do
      Worker.set_members(list_members, y)
    end
  end

  #  ---------------   root of a number  ---------------
  def root(_, b) when b < 2, do: b

  def root(a, b) do
    a1 = a - 1
    f = fn x -> (a1 * x + div(b, raise_power(x, a1))) |> div(a) end
    c = 1
    d = f.(c)
    e = f.(d)
    stoping_cond(c, d, e, f)
  end

  defp stoping_cond(c, d, e, _) when c in [d, e], do: min(d, e)
  defp stoping_cond(_, d, e, f), do: stoping_cond(d, e, f.(e), f)

  defp raise_power(_, 0), do: 1
  defp raise_power(n, m), do: Enum.reduce(1..m, 1, fn _, acc -> acc * n end)
end
