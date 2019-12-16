defmodule Proj2 do
  def main(args) do
    if length(args) == 4 do
      numNodes = String.to_integer(Enum.at(args, 0))

      if numNodes < 1 and String.to_integer(Enum.at(args, 3)) > 99 do
        IO.puts("Wrong parameters. Increase number of nodes or decrease percentage of failure")
      else
        Gossip_Protocol.main(
          numNodes,
          Enum.at(args, 1),
          Enum.at(args, 2),
          String.to_integer(Enum.at(args, 3))
        )
      end
    else
      IO.puts("Wrong arguments")
    end
  end
end
