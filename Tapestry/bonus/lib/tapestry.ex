
defmodule Tapestry do
  use GenServer

  def init(:ok) do
      {:ok,%{}}
  end

  def handle_cast({:delivered, hopCount}, state) do
       curhop=hopCount
      {_, requestsReceived} = Map.get_and_update(state, :requestsReceived, fn currentVal -> {currentVal, currentVal + 1} end)
      state = Map.merge(state, requestsReceived)
      {_, hopCount} = Map.get_and_update(state, :hopCount, fn currentVal -> {currentVal,Enum.max([currentVal,hopCount])} end)
      state = Map.merge(state, hopCount)
      mapReq = state[:numReq] * state[:numNode]
      if(state[:requestsReceived] >= (mapReq-1)) do
          hopCountMax = state[:hopCount]
          IO.puts "Max hop count is: #{inspect hopCountMax}"
          Process.exit(self(), :normal)
      end
      {:noreply, state}
  end
  def handle_cast({:updatePastry, numReq, node_map, numNode}, state) do
    
      {_, node_map} = Map.get_and_update(state,:node_map, fn currentVal -> {currentVal, node_map} end)
    
      {_, currentNumNodes} = Map.get_and_update(state, :numNode, fn currentVal ->{currentVal, numNode} end)
      {_, hopCount} = Map.get_and_update(state, :hopCount, fn currentVal -> {currentVal, 0} end)
      {_, numReq} = Map.get_and_update(state, :numReq, fn currentVal -> {currentVal, numReq} end)
      {_, requestsReceived} = Map.get_and_update(state, :requestsReceived, fn currentVal -> {currentVal, 0} end)
      state = Map.merge(state, node_map)
      state = Map.merge(state, currentNumNodes)
      state = Map.merge(state, hopCount)
      state = Map.merge(state, numReq)
      state = Map.merge(state, requestsReceived)
      #IO.inspect state
      {:noreply, state}
  end
  def nodeJoinadd(hashid_pid_map,hashid_slist) do
    #loop for determining hashid
    idx = length(hashid_slist)+1
    hashid= :crypto.hash(:sha,"#{idx}") |> Base.encode16()
    hashid=String.slice(hashid,0..7)
    {pid,hashid}=TapestryNode.start(hashid)  	
    hashid_pid_map = Map.put(hashid_pid_map,hashid,pid)
    {hashid_pid_map,hashid}
  end

  def updateJoin(hashid_pid_map,hashid_slist,hashid,numReq) do
    #updatePastry new process list
    # IO.inspect "inside updateJoin"
    TapestryNode.findParentFornewNode(hashid_pid_map,hashid_slist,hashid,numReq)
      :timer.sleep(100)
    # route_table = TapestryNode.computeRouteTable(hashid_pid_map, hashid_slist, hashid)  
   #    GenServer.cast(hashid_pid_map[hashid],{:updateNode,route_table,numReq,40,16})
      # GenServer.cast(hashid_pid_map[hashid],{:printTable})
  end

  def startTapestry(numNode, numReq,failureNodesPercent) do
      {:ok, _} = GenServer.start_link(__MODULE__, :ok, name: {:global, :Daddy})
      rangeOfNum = 1..numNode-1
      if failureNodesPercent > 90 do
        IO.puts "Cannot fail that much nodes"
      else
        failureNodes = trunc((failureNodesPercent/100)*(numNode - 1))
        #IO.puts failureNodes
        # return the idx_hashid map, hashid_dval map and hashid sorted tuple.
      #only generates the node ids and maps doesn't spawn yet. 
      {sorted_hashid_tup, hashrange} = genNodeIds(1,numNode)

      hashid_slist=Tuple.to_list(sorted_hashid_tup)

      failureNodesList = Enum.map(1..failureNodes, fn args -> 
          temp = :rand.uniform(args)
          #IO.inspect temp
          Enum.at(hashid_slist,temp)
       end)

      #IO.inspect failureNodesList
      #intialize the hashid pid 
     #IO.inspect "sorted hashid list :#{inspect hashid_slist}"
      hashid_pid_map=getPIDforHashid(hashid_slist)
      # IO.inspect length(list_count)
      # IO.puts "done hashid pid map "
      if buildNetwork(hashid_pid_map,sorted_hashid_tup, hashid_slist,numReq) do
        # :timer.sleep(5000)
      buildNetwork(hashid_pid_map,sorted_hashid_tup, hashid_slist,numReq)
      # IO.inspect(length(hashid_slist))
      # IO.inspect(length(hashid_slist -- failureNodesList))
      # x =  Enum.map(hashid_slist, fn args -> 
      #      TapestryNode.findParent(hashid_pid_map,hashid_slist -- failureNodesList,args)
      #  end)

      parent_nodes=Enum.reduce(hashid_slist, %{}, fn(hashid, acc_hashid_pid_map ) -> (
          parent_id=TapestryNode.findParent(hashid_pid_map,hashid_slist -- failureNodesList,hashid,failureNodesList)
          acc_hashid_pid_map = Map.put(acc_hashid_pid_map,hashid,parent_id)
          #IO.inspect acc_hashid_pid_map
          acc_hashid_pid_map
      )end)

      # IO.inspect parent_nodes
      #node join
      # IO.inspect hashid_pid_map
      {hashid_pid_map1,hashid} = nodeJoinadd(hashid_pid_map,hashid_slist)
       #IO.inspect hashid_pid_map1
      hashid_slist = [hashid] ++ hashid_slist
      GenServer.cast({:global, :Daddy}, {:updatePastry, numReq, hashid_pid_map1, numNode})  
      #IO.inspect "node added"     
      # IO.inspect hashid_slist
      # IO.inspect length(hashrange)
      #IO.inspect hashid_pid_map1
      updateJoin(hashid_pid_map1,hashid_slist,hashid,numReq)

      #IO.puts "done update tapestry"
      # IO.inspect Map.keys(hashid_pid_map)
      sendDataNow(Map.keys(hashid_pid_map), hashid_pid_map,failureNodesList)
      # testsend(sorted_hashid_tup, hashid_pid_map)
        else
          IO.puts "Sorry build went wrong"
      end
      
      end
  end


  def getPIDforHashid(hashid_slist) do
      hashid_pid_map=Enum.reduce(hashid_slist, %{}, fn(hashid, acc_hashid_pid_map ) -> (
          {pid,hashid}=TapestryNode.start(hashid)
          acc_hashid_pid_map = Map.put(acc_hashid_pid_map,hashid,pid)
          #IO.inspect acc_hashid_pid_map
          acc_hashid_pid_map
      )end)

      #IO.inspect "hashid map : #{inspect hashid_pid_map}"
      hashid_pid_map
  end


  def buildNetwork(hashid_pid_map,sorted_hashid_tup, hashrange, numReq) do
      hashid_slist= Tuple.to_list(sorted_hashid_tup)
      numRows = 8
      numCols = 16 

      #TODO: make creation of static distributed and test.. This is still serial intiailization...
      Enum.each(hashid_slist, fn (hashid) -> (
          join(hashid_slist, hashid, hashid_pid_map, sorted_hashid_tup,hashrange, numReq, numRows, numCols)
      )end)
  end

  def join(hashid_slist, hashid, hashid_pid_map, sorted_hashid_tup,hashrange, numReq, numRows, numCols) do
        
          route_table = TapestryNode.computeRouteTable(hashid_pid_map, hashrange, hashid)  
          #IO.puts "Route table for hashID #{inspect hashid} , Table : Row2 #{inspect route_table[2]} "
          # IO.puts "Row2 #{inspect route_table[1]}"
          GenServer.cast(hashid_pid_map[hashid],{:updateNode,route_table,numReq,numRows,numCols})
  end

  def looper1(acc_idx_hashid_map,hashid,idx) do
  if Map.has_key?(acc_idx_hashid_map, hashid) do
    #IO.inspect hashid
          {hashid1,idx1} = looper1(acc_idx_hashid_map,String.slice(:crypto.hash(:sha,"#{idx}") |> Base.encode16(),0..7),(idx+100000))
          {hashid1,idx1}
      else
        {hashid,idx}
      end
end

  def genNodeIds(start,numNode) do

      # generate the hashids for the range 1..nodenum.
      range=start..numNode
      idx_to_hashid_map=Enum.reduce(range, %{}, fn (idx,acc_idx_hashid_map) -> (
          hashid= :crypto.hash(:sha,"#{idx}") |> Base.encode16()
          hashid=String.slice(hashid,0..7)
          {hashid,idx1} = looper1(acc_idx_hashid_map,String.slice(:crypto.hash(:sha,"#{idx}") |> Base.encode16(),0..7),idx)
          idx2 = 
          if idx1 > numNode do
            idx1
          else
            idx
          end
          acc_idx_hashid_map=Map.put(acc_idx_hashid_map,idx2, hashid)
          #IO.inspect acc_idx_hashid_map
          acc_idx_hashid_map
      )end)

      hashrange=Map.values(idx_to_hashid_map)
  
      #hashid to decimal value map.
      hashid_dval_map=Enum.reduce(hashrange, %{}, fn (hashid,acc_hashid_dval_map) -> (
          dval=elem(Integer.parse(hashid,16),0)
          hashid_dval_map=Map.put(acc_hashid_dval_map, hashid,dval)
          hashid_dval_map
      )end)

      #sorted hashid map for leaf set generation.
      sorted_hashid_tup =  Enum.sort(hashrange, fn(x,y) -> (hashid_dval_map[x]<hashid_dval_map[y])end) |> List.to_tuple

      {sorted_hashid_tup,hashrange}
  end


  def sendDataNow(nodeList, hashIdMap,failureNodes) do
      #IO.inspect nodeList
      Enum.each(nodeList, fn(x) -> (
          pId = hashIdMap[x]
          GenServer.cast(pId,{:recieveMessage, 0, x, nodeList,failureNodes,hashIdMap})
      ) end)
      # IO.puts "Ending send data"
  end
  
  def looper() do
    looper()
  end

end