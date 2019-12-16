defmodule Engine do
    use GenServer

    def start_link(numUsers) do
        name = :Server
        {:ok,pid} = GenServer.start(__MODULE__,:ok)
        generateTables(pid)
        # printReporting()
        # spawn fn -> stats_print() end
        # loop_acceptor(listen_socket)
        # #IO.inspect("hi")
        # #IO.inspect(pid)
        {pid}
    end

    def init(init_arg) do
        #to get the process id of server anytime
      {:ok, init_arg}
    end

    def generateTables(pid) do
        :ets.new(:hashtags, [:set, :public, :named_table, read_concurrency: true])
        :ets.new(:tweets, [:set, :public, :named_table, read_concurrency: true])
        :ets.new(:mentions, [:set, :public, :named_table, read_concurrency: true])
        :ets.new(:clients, [:set, :public, :named_table, read_concurrency: true])
        :ets.new(:report, [:set, :public, :named_table, read_concurrency: true])
        :ets.new(:activeUsers,[:set, :public, :named_table, read_concurrency: true])
        #subsribers
        :ets.new(:followers, [:set, :public, :named_table, read_concurrency: true])
        :ets.new(:following, [:set, :public, :named_table, read_concurrency: true])
        # server_id = spawn_link(fn() -> processRequests() end) 
        # receive do: (_ -> :ok)
    end

    def check_member(user_id) do
		if(:ets.member(:clients,user_id)==true) do
			:ok
		else
			:not_ok
		end
	end

	def check_login(user_id) do
		if(:ets.member(:activeUsers,user_id)==true) do
			:ok
		else
			:not_ok
		end
    end

    def check_logout(user_id) do
		if(:ets.member(:activeUsers,user_id)==false) do
			:ok
		else
			:not_ok
		end
    end
    
    def check_recievedTweet(user_id,test_id,tweetData) do
        [temp]=:ets.lookup(:following,user_id)
        listOffollowing=elem(temp,1)
        if(Enum.member?(listOffollowing,test_id)==true)do
            [temp1]=:ets.lookup(:tweets,test_id)
             listOftweets=elem(temp1,1)
             if(Enum.member?( listOftweets,tweetData)==true) do
                :ok
             else 
                :not_ok
             end
        else
            :not_ok
        end
    end

    def delete_account(user_id) do
        if(check_member(user_id)==:ok)do
            GenServer.cast(self(),{:deleteAccount,user_id})
            :ok
        else
            :not_ok
        end
    end
    
    def subscribeTwoUsers(processID,userID,subscribeTo)do
        GenServer.cast(processID,{:iSubscribed,userID,subscribeTo})
    end
    def check_subscribers(user_id,follower_id) do
        [temp]=:ets.lookup(:followers, user_id)
        listOfSubscriber=elem(temp,1)
        if(Enum.member?(listOfSubscriber,follower_id)==true) do
        :ok
    else
        :not_ok
    end 
    end
   

    #registering an account
    def handle_cast({:registerUser, user_id ,pid}, state) do
        #IO.inspect(user_id)
        :ets.insert(:clients, {user_id,pid})
        :ets.insert(:tweets, {user_id, []})
        :ets.insert(:following, {user_id, []})
        :ets.insert(:followers, {user_id, []})
        :ets.insert(:hashtags, [])
        :ets.insert(:mentions, [])
        #IO.inspect("User #{user_id} registered")
        {:noreply, state}
    end

    # def check_tweet(user_id)do
    #     if()
    # end
      
    def handle_call({:checkDuplicate, user_id}, _from, state) do
        temp = check_member(user_id)
        {:reply, temp,state}
    end

    def checkUniqueID(processIDServer,clientID) do
        status = GenServer.call(processIDServer,{:checkDuplicate, clientID})
        status
    end
    
    def handle_cast({:logout, user_id}, state) do
        #reconnecting with previous data
        :ets.delete(:activeUsers, user_id)
        {:noreply, state}
    end

    #tweets to process
    def handle_cast({:tweets, user_id, tweetData}, state) do
        #IO.inspect("Processing tweet from #{user_id}")
        [tempn1] = :ets.lookup(:tweets, user_id)
        :ets.insert(:tweets,{user_id,[tweetData | elem(tempn1,1)]})
        #followers
        [temp]= :ets.lookup(:followers, user_id)
        Enum.each(elem(temp,1), fn followers -> 
            if :ets.lookup(:clients, followers) != [] do
                [temp1] = :ets.lookup(:clients, followers)
                GenServer.cast(elem(temp1,1) ,{:live_tweets, user_id, tweetData})
                # send(elem(temp1,1),{:online,tweetData})
            end
        end)
        #check if anyone is mentioned or use of any hashtags
        #mentions
        retrieveMentions = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweetData)
        Enum.each(Enum.concat(retrieveMentions), fn mentions -> 
            #IO.inspect("Tweet with mentions for #{mentions}")
            if :ets.lookup(:mentions, mentions) != [] do
                [tempn2] = :ets.lookup(:mentions, mentions)
                :ets.insert(:mentions,{mentions,[tweetData | elem(tempn2,1)]})            
            else
                :ets.insert(:mentions,{mentions,[tweetData]})
            end
            #live sessions for other users --- mentioned in tweets and its followers
            userName = String.slice(mentions,1..-1)
            if :ets.lookup(:clients, userName) != [] do
                [temp2] = :ets.lookup(:clients, userName)
                GenServer.cast(elem(temp2,1) ,{:live_tweets, user_id, tweetData})
                # send(elem(temp2,1),{:online,tweetData})
            end end)
        #hashtags
        retrieveHashTags = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweetData)
        Enum.each(Enum.concat(retrieveHashTags), fn hashtag -> 
            # #IO.inspect(:ets.lookup(:hashtags, hashtag))
            #IO.inspect("Tweet with hashtag #{hashtag}")
            if :ets.lookup(:hashtags, hashtag) != [] do
                [tempn3] = :ets.lookup(:hashtags, hashtag)
                # #IO.inspect(elem(tempn3,1))
                :ets.insert(:hashtags,{hashtag,[tweetData | elem(tempn3,1)]})
            else
                :ets.insert(:hashtags,{hashtag,[tweetData]})
            end 
            # #IO.inspect(:ets.lookup(:hashtags, hashtag))
        end)  
        {:noreply, state}
    end

    def wallTweets([],myWallTweets), do: myWallTweets
    def wallTweets([head | tail],myWallTweets) do
        wallTList = 
        if :ets.lookup(:tweets, head) == [] do
            myWallTweets 
        else
            elem(:ets.lookup(:tweets, head), 1) ++ myWallTweets
        end
        wallTweets(tail,wallTList)
    end

    def checkDuplicate(user_id) do
        if :ets.lookup(:clients, user_id) == [] do
            :ok
        else
            [listUSers] = :ets.lookup(:clients, user_id)
            IO.inspect listUSers
            if elem(listUSers,0) == user_id do
                :not_ok
            else
                :ok
            end
        end
    end

    def handle_call({:checkDuplicate, user_id}, _from, state) do
        IO.inspect(user_id)
        temp = checkDuplicate(user_id)
        {:reply, temp,state}
    end

    def retweettwo(processIDServer, userId,subscribe) do
        tweet = pickATweet(processIDServer,subscribe)
        tweetData1 = ["Retweeting "] ++ tweet
        # IO.inspect("Initial Retweet: #{tweetData}")
        GenServer.cast(processIDServer,{:retweet,userId,tweetData1})
    end
    
    def pickATweet(processIDServer,user_id) do
    	#pick the last tweet to retweet
    	tweetData = GenServer.call(processIDServer,{:randTweet,user_id})
        # IO.inspect tweetData
    	tweetData
    end
    #random tweet
    def handle_call({:randTweet, user_id}, _from, state) do
        [x] = :ets.lookup(:following,user_id)
        if(elem(x,1)!=[])do
         [temp]=:ets.lookup(:following,user_id)
         IO.inspect temp
         listOffollowing=elem(temp,1)
         if(listOffollowing!=[]) do
          user=Enum.at(listOffollowing,0)
          [temp10] = :ets.lookup(:tweets, user)
          iAmFollowing = elem(temp10, 1)
          temp = Enum.at(iAmFollowing,0)
          {:reply, temp,state}
          else
            temp="No re-tweet"
            {:reply, temp,state}
          end
        else
            temp="No re-tweet"
            {:reply, temp,state}
        end
    end

    #twitter self page tweets - wall 
    def handle_cast({:myWallTweets, user_id}, state) do
        [temp10] = :ets.lookup(:following, user_id)
        iAmFollowing = elem(temp10, 1)
        if iAmFollowing != [] do
            listTweets = wallTweets(iAmFollowing,[])
            # listTweets1 = Enum.reject(listTweets, fn x -> x == [] end)
            pid_user = 
            if :ets.lookup(:clients, user_id) == [] do
                nil
            else
                [temp3] = :ets.lookup(:clients,user_id)
                elem(temp3, 1)
            end
            if pid_user != nil do
                GenServer.cast(pid_user ,{:live_tweets, user_id, listTweets})
                # send(pid_user,{:myWallTweetsLive,listTweets})
            end     
        end
        {:noreply, state}
    end

    #hashtag query
    def handle_cast({:queryHashtag, user_id, hashtag}, state) do
        # #IO.inspect(:ets.lookup(:hashtags, hashtag))
        [temp4] = 
        if :ets.lookup(:hashtags, hashtag) != [] do
            :ets.lookup(:hashtags, hashtag)
        else
            [{"#",["no tweets on such hashtag"]}]
        end 
        listHashtagTweets = elem(temp4, 1)
        listTweets = ["Hashtag "] ++ listHashtagTweets
        # #IO.inspect(:ets.lookup(:hashtags, hashtag))
        pid_user = 
            if :ets.lookup(:clients, user_id) == [] do
                nil
            else
                [temp3] = :ets.lookup(:clients,user_id)
                elem(temp3, 1)
            end
            # #IO.inspect(temp4)
        if pid_user != nil do
            GenServer.cast(pid_user, {:live_tweets, user_id, listTweets})
        end 
        {:noreply, state}
    end

    #mentions query
    def handle_cast({:queryMentions, user_id}, state) do
        [temp6] = 
        if :ets.lookup(:mentions, "@" <> Integer.to_string(user_id)) != [] do
            :ets.lookup(:mentions, "@" <> Integer.to_string(user_id))
        else
            [{"@",["no mentions for you yet"]}]
        end
        listMentions = elem(temp6, 1)
        listTweets = ["Mentions "] ++ listMentions
        pid_user = 
            if :ets.lookup(:clients, user_id) == [] do
                nil
            else
                [temp3] = :ets.lookup(:clients,user_id)
                elem(temp3, 1)
            end
        if pid_user != nil do
            GenServer.cast(pid_user, {:live_tweets, user_id, listTweets})
        end 
        {:noreply, state}
    end

    #my tweets
    def handle_cast({:meTweeting, user_id}, state) do
        [temp7] = :ets.lookup(:tweets, user_id)
        myTweets = elem(temp7, 1)
        pid_user = 
            if :ets.lookup(:clients, user_id) == [] do
                nil
            else
                [temp3] = :ets.lookup(:clients,user_id)
                elem(temp3, 1)
            end
        if pid_user != nil do
            GenServer.cast(pid_user, {:live_tweets, user_id, myTweets})
        end 
        {:noreply, state}
    end

    def handle_cast({:retweet, user_id, tweetData}, state) do
        [myWallTweets] = :ets.lookup(:tweets, user_id)
        :ets.insert(:tweets,{user_id,[tweetData | elem(myWallTweets, 1)]}) 
        # IO.inspect("Retweeting: #{tweetData}")
        GenServer.cast(self(), {:broadcast_tweets, user_id, tweetData})
        {:noreply, state}
        end

    def getProcessID(user_id) do
        if :ets.lookup(:clients, user_id) == [] do
            nil
        else
            [pid] = :ets.lookup(:clients, user_id)
            elem(pid, 1)
        end
    end

    # Broadcast tweets
    def handle_cast({:broadcast_tweets, user_id, tweetData}, state) do
        # IO.inspect("Broadcast from: #{user_id}")
        # IO.inspect(:ets.lookup(:followers, user_id))
        subscribers = 
        if :ets.lookup(:followers, user_id) == [] do
          []
        else
            [x] = :ets.lookup(:followers, user_id)
            # IO.inspect(:ets.lookup(:followers, user_id))
            elem(x, 1)
        end
        # IO.inspect(:ets.lookup(:followers, user_id))
        # IO.inspect("Broadcast subscribers: #{subscribers}")
        Enum.map(subscribers, fn user -> 
            pid = getProcessID(user)
            # IO.inspect("Retweeting; ")
            GenServer.cast(pid, {:live_tweets, user, tweetData})
         end)  
        {:noreply, state}
    end

    def handle_cast({:iSubscribed, user_id, subscribe}, state) do
        # IO.inspect("subscribers: #{subscribe}")
        if user_id != subscribe do
            [temp8] = :ets.lookup(:following, user_id)
            addSubscriber = [subscribe | elem(temp8, 1)]
            :ets.insert(:following, {user_id, addSubscriber})
            #adding followers list for the other process
            pid_user = 
                if :ets.lookup(:clients, subscribe) == [] do
                    nil
                else
                    [temp3] = :ets.lookup(:clients, subscribe)
                    elem(temp3, 1)
                end
            if pid_user != nil do
                # IO.inspect(user_id)
                if :ets.lookup(:followers, subscribe) != [] do
                    [temp9] = :ets.lookup(:followers, subscribe)
                    # addFollowers = [user_id | elem(temp9, 1)]
                    # IO.inspect(elem(temp9, 1))
                    # addFollowers1 = Enum.uniq(Enum.reject(addFollowers, fn x -> x == nil end))
                    x = elem(temp9,1)
                    # IO.inspect(x)
                    # IO.inspect([user_id] ++ x)
                    :ets.insert(:followers,{subscribe,[user_id] ++ x})
                    # :ets.insert(:followers, {pid_user, addFollowers1})
                else
                    :ets.insert(:followers,{subscribe,[user_id]})
                end
                IO.inspect(:ets.lookup(:followers, subscribe))
            end 
        end        
        {:noreply, state}
    end

    def handle_cast({:disconnection, user_id}, state) do
        #could delete entry but will lose data of the client
        :ets.insert(:clients, {user_id, nil})
        :ets.delete(:activeUsers, user_id)
        #can be used for reconnection
        {:noreply, state}
    end

    def handle_cast({:deleteAccount, user_id}, state) do
        #could delete entry but will lose data of the client
        :ets.delete(:clients, user_id)
        #can be used for reconnection
        #IO.puts("User #{user_id} deleted")
        {:noreply, state}
    end

    def handle_cast({:login, user_id,pid}, state) do
        #reconnecting with previous data
        :ets.insert(:activeUsers, {user_id, pid})
        {:noreply, state}
    end

    def startReporting() do
        #status for reporting 
        :ets.insert(:report, {"numberOfUsers", 0})
        :ets.insert(:report, {"numberOfTweets", 0})
        :ets.insert(:report, {"numberOfUsersActive", 0})
    end

    def printReporting() do
        tweetsCount = :ets.lookup_element(:report, "numberOfTweets", 2)
        userCount = :ets.lookup_element(:report, "numberOfUsers", 2)
        activeUsers = :ets.lookup_element(:report, "numberOfUsersActive", 2)
        # #IO.inspect(tweetsCount,userCount,activeUsers)
    end

end