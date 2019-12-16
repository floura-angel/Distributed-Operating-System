defmodule Main do   
    [arg1,arg2,arg3]= Enum.map(System.argv, (fn(a) -> a end))
    numNodes=String.to_integer(arg1)
    numRequest=String.to_integer(arg2)
    failureNodes=String.to_integer(arg3)
    IO.puts "numNodes: #{numNodes}"
    IO.puts "numRequest: #{numRequest}"
    IO.puts "failureNodesPercentage: #{failureNodes}"
    Tapestry.startTapestry(numNodes,numRequest,failureNodes)
    :timer.sleep(500)
    IO.puts "Press control + C to exit"
    Tapestry.looper() 
end
