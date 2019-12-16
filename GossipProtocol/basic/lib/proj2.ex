defmodule Proj2 do
  def main(args) do
    if length(args) == 3 do
      numNodes = String.to_integer(Enum.at(args, 0))

      Gossip_Protocol.main(
        numNodes,
        Enum.at(args, 1),
        Enum.at(args, 2)
      )
    else
      IO.puts("Wrong arguments")
    end
  end
end
