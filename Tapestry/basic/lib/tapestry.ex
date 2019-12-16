
defmodule Tapestry do
  use GenServer

  def init(:ok) do
      {:ok,%{}}
  end

  def handle_cast({:messageRecieved, hopCount}, state) do
      {_, requestsReceived} = Map.get_and_update(state, :requestsReceived, fn curVal -> {curVal, curVal + 1} end)
      state = Map.merge(state, requestsReceived)
      {_, hopCount} = Map.get_and_update(state, :hopCount, fn curVal -> {curVal,Enum.max([curVal,hopCount])} end)
      state = Map.merge(state, hopCount)
      totalMapRequest = state[:numReq] * state[:numNode]
      if(state[:requestsReceived] >= (totalMapRequest-1)) do
          hopCountMax = state[:hopCount]
          IO.puts "Max hop count is: #{inspect hopCountMax}"
          Process.exit(self(), :normal)
      end
      {:noreply, state}
  end
  def handle_cast({:updateTapestry, numReq, node_map, numNode}, state) do
    
      {_, node_map} = Map.get_and_update(state,:node_map, fn curVal -> {curVal, node_map} end)
    
      {_, currentNumNodes} = Map.get_and_update(state, :numNode, fn curVal ->{curVal, numNode} end)
      {_, hopCount} = Map.get_and_update(state, :hopCount, fn curVal -> {curVal, 0} end)
      {_, numReq} = Map.get_and_update(state, :numReq, fn curVal -> {curVal, numReq} end)
      {_, requestsReceived} = Map.get_and_update(state, :requestsReceived, fn curVal -> {curVal, 0} end)
      state = Map.merge(state, node_map)
      state = Map.merge(state, currentNumNodes)
      state = Map.merge(state, hopCount)
      state = Map.merge(state, numReq)
      state = Map.merge(state, requestsReceived)
      #IO.inspect state
      {:noreply, state}
  end
  def nodeJoinadd(pid_hashid_map,hashid_slist,idx_hashid_map) do
    #loop for determining hashid
    idx = length(hashid_slist)+1
      {hashid,idx1} = looper1(idx_hashid_map,String.slice(:crypto.hash(:sha,"#{idx}") |> Base.encode16(),0..7),idx)
    {pid,hashid}=TapestryNode.start(hashid)  	
    pid_hashid_map = Map.put(pid_hashid_map,hashid,pid)

    {pid_hashid_map,hashid}
  end

  def updateJoin(pid_hashid_map,hashid_slist,hashid,numReq) do
    #updateTapestry new process list
    # IO.inspect "inside updateJoin"
    TapestryNode.findParent(pid_hashid_map,hashid_slist,hashid,numReq)
      :timer.sleep(100)
    # route_table = TapestryNode.computeRouteTable(pid_hashid_map, hashid_slist, hashid)  
   #    GenServer.cast(pid_hashid_map[hashid],{:updateNode,route_table,numReq,40,16})
      # GenServer.cast(pid_hashid_map[hashid],{:printTable})
  end

  def startTapestry(numNode, numReq) do
      {:ok, _} = GenServer.start_link(__MODULE__, :ok, name: {:global, :Boss})
      idx_hashid_map = genHashIDs(1,numNode)
      hashid_slist=Map.values(idx_hashid_map)
      #intialize the hashid pid map and then build the network using that
     #IO.inspect "sorted hashid list :#{inspect hashid_slist}"
      pid_hashid_map=mapPIDforHashid(hashid_slist)
      # IO.puts "done hashid pid map "
      initialiseNetwork(pid_hashid_map, hashid_slist,numReq)
     
      #node join
      # IO.inspect pid_hashid_map
      {pid_hashid_map1,hashid} = nodeJoinadd(pid_hashid_map,hashid_slist,idx_hashid_map)
       #IO.inspect pid_hashid_map1
      hashid_slist = [hashid] ++ hashid_slist
      GenServer.cast({:global, :Boss}, {:updateTapestry, numReq, pid_hashid_map1, numNode})  
      #IO.inspect "node added"     
      # IO.inspect hashid_slist
      #IO.inspect pid_hashid_map1
      updateJoin(pid_hashid_map1,hashid_slist,hashid,numReq)

      #IO.puts "done update tapestry"
      startSendingRequest(Map.keys(pid_hashid_map), pid_hashid_map)
      # testsend(sorted_hashid_tup, pid_hashid_map)
  end


  def mapPIDforHashid(hashid_slist) do
      pid_hashid_map=Enum.reduce(hashid_slist, %{}, fn(hashid, pid_map ) -> (
          {pid,hashid}=TapestryNode.start(hashid)
          pid_map = Map.put(pid_map,hashid,pid)
          #IO.inspect pid_map
          pid_map
      )end)

      #IO.inspect "hashid map : #{inspect pid_hashid_map}"
      pid_hashid_map
  end

  def initialiseNetwork(pid_hashid_map,hashid_slist ,numReq) do
      numRows = 8
      numCols = 16 
      Enum.each(hashid_slist, fn (hashid) -> (
          fillTable(hashid_slist, hashid, pid_hashid_map,numReq, numRows, numCols)
      )end)
  end

  def fillTable(hashid_slist, hashid, pid_hashid_map,numReq, numRows, numCols) do
          route_table = TapestryNode.computeRouteTable(pid_hashid_map, hashid_slist, hashid)  
          GenServer.cast(pid_hashid_map[hashid],{:updateNode,route_table,numReq,numRows,numCols})
  end

  def looper1(idx_hashid_map,hashid,idx) do
  if Map.has_key?(idx_hashid_map, hashid) do
          {hashid1,idx1} = looper1(idx_hashid_map,String.slice(:crypto.hash(:sha,"#{idx}") |> Base.encode16(),0..7),(idx+100000))
          {hashid1,idx1}
      else
        {hashid,idx}
      end
end

  def genHashIDs(start,numNode) do

      # generate the hashids 
      range=start..numNode
      idx_to_hashid_map=Enum.reduce(range, %{}, fn (idx,idx_hashid_map) -> (
          hashid= :crypto.hash(:sha,"#{idx}") |> Base.encode16()
          hashid=String.slice(hashid,0..7)
          {hashid,idx1} = looper1(idx_hashid_map,String.slice(:crypto.hash(:sha,"#{idx}") |> Base.encode16(),0..7),idx)
          idx2 = 
          if idx1 > numNode do
            idx1
          else
            idx
          end
          idx_hashid_map=Map.put(idx_hashid_map,idx2, hashid)
          idx_hashid_map
      )end)
      idx_to_hashid_map
  end


  def startSendingRequest(nodeList, hashIdMap) do
      #IO.inspect nodeList
      Enum.each(nodeList, fn(x) -> (
          pId = hashIdMap[x]
          GenServer.cast(pId,{:sentRequest, 0, x, nodeList})
      ) end)
      # IO.puts "Ending send data"
  end
  
  def looper() do
    looper()
  end

end