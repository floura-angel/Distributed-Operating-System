defmodule TapestryNode do
    use GenServer
    
     #Generate Node process
        def start(hashid) do
            {:ok,pid} = GenServer.start(__MODULE__,hashid)
            {pid,hashid}
        end
    
        def init(args) do  
            {:ok,%{:node_id => args}}
        end
        
        def handle_cast({:checkReplaceParent,pid_hashid_map,hashid_slist,parent_final,hashid,numReq},state) do
            #check longest sequence => determine row and column
            longest_prefix_count = longest_prefix_match(parent_final, hashid,0,0)
            numRow = longest_prefix_count
            _numCol = elem(Integer.parse(String.at(hashid, longest_prefix_count),16),0)
            # IO.inspect numRow
            # # IO.inspect parent_final
            # IO.inspect numCol
            routing_table = state[:routing_table]
    
            routing_t = set_routing_table_entry(hashid,longest_prefix_count,pid_hashid_map,routing_table,hashid)
                # IO.inspect routing_t
            {_,routing_table1}=Map.get_and_update(state,:routing_table, fn curVal -> {curVal,routing_t} end)
            state=Map.merge(state, routing_table1)
            #update the members of the parent node => only once
            #IO.inspect state[:routing_table]
            #IO.inspect map_size(routing_table1)
    
            #updating the parent nodes and the nodes after that row
            x = Map.keys(routing_t)
            # IO.inspect x
            # last_x = x[length(x)-1]
            last_x = Enum.at(x,-1)
            # IO.inspect last_x
            table = state[:routing_table]
            inspect table
    
            list_neighbors =
            for x<- 0..numRow do
                for y<- 0..15 do
                    if table[x][y] != nil do
                        # IO.inspect table[x][y]
                        Enum.at(Tuple.to_list(table[x][y]),0)
                    end
                end
            end
    
            list_neighbors1 = List.flatten(list_neighbors)
            # IO.inspect list_neighbors1
            all_factors = Enum.reject(list_neighbors1, fn x -> x == nil end)
            # IO.inspect all_factors
    
            for x<- all_factors do
                GenServer.cast(pid_hashid_map[x], {:checkReplace,pid_hashid_map,hashid_slist,x,hashid,numReq})
            end
    
            # IO.inspect table
            newnode_neighbors =
            for x<- 0..numRow do
                for y<- 0..15 do
                    if routing_table[x][y] != nil do
                        Enum.at(Tuple.to_list(table[x][y]),0)
                    end
                end
            end
            newnode_neighbors1 = List.flatten(newnode_neighbors)
            newnode_factors = Enum.reject(newnode_neighbors1, fn x -> x == nil end)
            # IO.inspect newnode_factors
            #IO.inspect hashid
            route_table = computeRouteTable(pid_hashid_map, newnode_factors, hashid)  
            # IO.inspect pid_hashid_map[hashid]
            GenServer.cast(pid_hashid_map[hashid],{:updateNode,route_table,numReq,8,16})
            # GenServer.cast(pid_hashid_map[hashid],{:printTable})
            {:noreply,state}
        end
    
        def handle_cast({:printTable},state) do
            _routing_table = state[:routing_table]
            # IO.inspect "hello"
           # IO.inspect routing_table
            {:noreply, state}
        end  
    
        def longest_prefix_match(key,hash_id,start_value,longest_prefix_count) do
            longest_prefix_count=cond do 
                (String.at(key,start_value) == String.at(hash_id,start_value)) ->
                    longest_prefix_match(key,hash_id,start_value+1,longest_prefix_count+1)
                true ->
                    longest_prefix_count
            end
            longest_prefix_count
        end

   
        def handle_cast({:checkReplace,pid_hashid_map,_hashid_slist,x,hashid,_numReq},state) do
            #check longest sequence => determine row and column
             #check longest sequence => determine row and column
            longest_prefix_count = longest_prefix_match(x, hashid,0,0)
            numRow = longest_prefix_count
            _numCol = elem(Integer.parse(String.at(hashid, longest_prefix_count),16),0)
            # IO.inspect numRow
            # # IO.inspect parent_final
            # IO.inspect numCol
            routing_table = state[:routing_table]
    
            routing_t = set_routing_table_entry(hashid,longest_prefix_count,pid_hashid_map,routing_table,hashid)
                # IO.inspect routing_t
            {_,routing_table1}=Map.get_and_update(state,:routing_table, fn curVal -> {curVal,routing_t} end)
            state=Map.merge(state, routing_table1)
            # GenServer.cast(self(), {:printTable})
            #if nil update
            {:noreply, state}
        end
    
        def informExistence(pid_hashid_map,parent_final,hashid_slist,hashid,numReq,_all_parents) do
            #get process id
            #IO.inspect "informing existence"
            process_id = pid_hashid_map[parent_final]
            #cast to it's genserver
            GenServer.cast(process_id, {:checkReplaceParent,pid_hashid_map,hashid_slist,parent_final,hashid,numReq})
            # :timer.sleep(10000)
            #GenServer.cast(process_id, {:printTable})
            #build own table
    
        end 
    
    
        def findParent(pid_hashid_map,hashid_slist,hashid,numReq) do
            #IO.inspect "in findParent"
            match_count = 0
            list_longseq = Enum.map(hashid_slist, fn x -> 
                if x != hashid do
                    count = longest_prefix_match(x,hashid,0,0)
                    if match_count <= count do
                        [x, count]
                    end
                end
            end)
            #IO.inspect list_longseq
    
            all_factors = Enum.reject(list_longseq, fn x -> x == nil end)
            #IO.inspect all_factors
            # all_factors1 = Enum.reject(all_factors, fn x -> Enum.at(x,1) == 1 end)
    
            parent = Enum.map(all_factors, fn  x -> 
                count_temp = Enum.at(x,1)
                count_temp
            end)
            #IO.inspect parent
            max_parent = Enum.max(parent)
    
            list_parent =
            Enum.map(all_factors, fn  x ->
                if Enum.at(x,1) == max_parent do
                    Enum.at(x,0)
                end
            end)
            all_factors2 = Enum.reject(list_parent, fn x -> x == nil end)
            #select using distance
            parent_final = Enum.at(all_factors2,0)
            all_parents=all_factors
            informExistence(pid_hashid_map,parent_final,hashid_slist,hashid,numReq,all_parents)
     end

        #surrogate routing        
        def check_route_row(routing_table,numRow,numCol,_nextVal)  do
            if(numCol+1!=15) do
            newVal=routing_table[numRow][numCol+2]
            check_route_row(routing_table,numRow,numCol+1,newVal)
            else
            {nil,nil} 
            end  
        end
        def check_route_row(routing_table,numRow,numCol,nextVal) when nextVal != nil do
             routing_table[numRow][numCol+1]
        end
    
    
        def find_node(key, longest_prefix_count, routing_table) do
            numRow = longest_prefix_count
            #orig numCol = Integer.parse(String.at(key, longest_prefix_count))
            numCol = elem(Integer.parse(String.at(key, longest_prefix_count),16),0)
            result = cond do
                routing_table[numRow][numCol] != nil ->
                    routing_table[numRow][numCol]
                true ->  
                    nextVal=routing_table[numRow][numCol+1]
                    check_route_row(routing_table,numRow,numCol,nextVal)
                    #{nil,nil}
            end
            result
        end
        def findDistance(node1,node2) do 
            list1 = Enum.map(0..(String.length(node1)-1), fn x -> 
                k=elem(Integer.parse(String.at(node1,x),16),0)
                k
            end)
    
            list2 = Enum.map(0..(String.length(node2)-1), fn x -> 
                k=elem(Integer.parse(String.at(node2,x),16),0)
                k
            end)
    
            #IO.inspect list1
            #IO.inspect list2
    
            sum1 = Enum.sum(list1)
            sum2 = Enum.sum(list2)
            diff=abs(sum1-sum2)
        end
        def set_routing_table_entry(entry, longest_prefix_count, pid_hashid_map, routing_table,hashid) do 
            #IO.inspect entry
            #process_id=self
    
            numRow = longest_prefix_count
            numCol = elem(Integer.parse(String.at(entry, longest_prefix_count),16),0)
            routing_table_updated = cond do
                routing_table[numRow][numCol] == nil ->
                    rowMap = cond do
                        routing_table[numRow] == nil ->
                            %{}
                        true ->
                            routing_table[numRow]
                     end
                    if(routing_table[numRow][numCol]!=nil) do
                        {hashid1,_pid}=routing_table[numRow][numCol]
                        diff1=findDistance(hashid,hashid1)
                        diff2=findDistance(hashid,entry)
                    if(diff1<diff2) do
                        entry=hashid1
                    else
                        entry=entry
                    end
                end
    
                    entry_tup={entry,pid_hashid_map[entry]}
                    #IO.inspect "entry_tup #{entry_tup}"
                    rowMap = Map.put(rowMap, numCol, entry_tup)
                    #IO.inspect "Rowmap #{rowMap}"
                    routing_table = Map.put(routing_table, numRow, rowMap)
                    routing_table
                true ->
                    routing_table
                end
            
                #IO.inspect "The updated routing table #{inspect routing_table_updated}"
            routing_table_updated
        end
    
    
        #routing table construction
        def computeRouteTable(pid_hashid_map,hashid_slist,hashid) do
            
            routing_table=Enum.reduce(hashid_slist, %{}, fn( entry ,acc_routing_table) -> (
                cond do
                    (String.equivalent?(entry,hashid) == false) ->
                        longest_prefix_count = longest_prefix_match(entry,hashid,0,0)
                        acc_routing_table=Map.merge(acc_routing_table ,set_routing_table_entry(entry, longest_prefix_count, pid_hashid_map, acc_routing_table,hashid))
                        #IO.inspect acc_routing_table
                        acc_routing_table
                    true ->
                        #IO.inspect acc_routing_table
                        acc_routing_table
                end
            ) end)
    
            #IO.inspect "The complete routing table : #{routing_table}"
            routing_table
        end
    
        def hashdval(hashid) do
            elem(Integer.parse(hashid,16),0)
        end


        def handle_cast({:updateNode,routing_table,num_req,num_rows,num_cols},state) do
            {_,routing_table}=Map.get_and_update(state,:routing_table, fn curVal -> {curVal,routing_table} end)
            {_,num_req}=Map.get_and_update(state,:num_req, fn curVal -> {curVal,num_req} end)
            {_,num_rows}=Map.get_and_update(state,:num_rows, fn curVal -> {curVal,num_rows} end)
            {_,num_cols}=Map.get_and_update(state,:num_cols, fn curVal -> {curVal,num_cols} end)
            #IO.inspect routing_table
            state=Map.merge(state, routing_table)  
            state=Map.merge(state, num_req)
            state=Map.merge(state, num_rows)
            state=Map.merge(state, num_cols)
            {:noreply,state}
        end
    
        def handle_cast({:sentRequest, currentCount, hashId, nodeList}, state) do
            if(currentCount < state[:num_req]) do
                key = Enum.random(nodeList)
               routeDiscovered = []
               currentCount= cond do 
                    (String.equivalent?(key, hashId) == false) ->
                        GenServer.cast(self(), {:route, hashId, key, 0,routeDiscovered})
                        currentCount = currentCount + 1
                        currentCount
                    
                    true ->
                        currentCount
                end
                GenServer.cast(self(), {:sentRequest, currentCount, hashId, nodeList})
            end
            {:noreply, state}
        end
    
        def handle_cast({:route, source, destination, hopCount,routeDiscovered}, state) do
            cond do 
    
                String.equivalent?(source, destination) == true ->
           
                     GenServer.cast({:global, :Boss}, {:messageRecieved,hopCount})
               
                
                true -> # Routing logic
                       
                       _destinationval=hashdval(destination)
                       longest_prefix_count = longest_prefix_match(source, destination,0,0)
                       routing_table = state[:routing_table]
                       {routing_table_entry,entry_pid} = find_node(destination, longest_prefix_count, routing_table)
                       routeDiscovered = [routing_table_entry] ++routeDiscovered
                        GenServer.cast(entry_pid, {:route, routing_table_entry, destination, hopCount + 1,routeDiscovered})
                           
            end
            
            {:noreply, state}
        end
    
end