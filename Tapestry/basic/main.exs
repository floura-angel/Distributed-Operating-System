defmodule Main do   
    [arg1,arg2]= Enum.map(System.argv, (fn(a) -> a end))
    numNodes=String.to_integer(arg1)
    numRequest=String.to_integer(arg2)
    IO.puts "numNodes: #{numNodes}"
    IO.puts "numRequest: #{numRequest}"
    if(numRequest>0 && numNodes>1)do
    Tapestry.startTapestry(numNodes,numRequest)
    else
        IO.puts "Invalid input either number of requests is 0 or number of nodes is 1"
        Process.exit(self(),:normal)
    end
    :timer.sleep(100)
    IO.puts "Press control + C to exit"
    Tapestry.looper()
end
