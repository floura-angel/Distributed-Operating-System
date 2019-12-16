defmodule Client do
	use GenServer

    def start_link(clientID,noOfTweets,noToSubscribers,processIDServer) do
        {:ok,pid} = GenServer.start_link(__MODULE__, [clientID,noOfTweets,noToSubscribers,processIDServer])
        # #IO.inspect(pid)
        # #IO.inspect(elem(processIDServer,0))
        if Mix.env == :test do
        main(clientID,noOfTweets,noToSubscribers,processIDServer,pid)
        else
        main(clientID,noOfTweets,noToSubscribers,elem(processIDServer,0),pid)    
        {pid}
        end
    end

    def init(init_arg) do
      {:ok, init_arg}
    end

    def main(clientID,noOfTweets,noToSubscribers,processIDServer,pid) do
        # pid = self()
        # #IO.inspect(pid1)
        GenServer.cast(processIDServer,{:registerUser, clientID, pid})
        #after registration login
        loginUser(clientID,pid,noOfTweets,noToSubscribers,processIDServer)
        :timer.sleep(50)
    end

    def loginUser(clientID,mypid,noOfTweets,noToSubscribers,processIDServer) do
        IO.inspect("logging in: #{clientID}")
        GenServer.cast(processIDServer,{:login, clientID,mypid})
        simulator_calls(clientID,noOfTweets,noToSubscribers,processIDServer)
        # handle_liveView(clientID)
    end
    
    def checkUniqueID(processIDServer,clientID) do
        status = GenServer.call(processIDServer,{:checkDuplicate, clientID})
        status
    end

    

    # def main(clientID,noOfTweets,noToSubscribers,processIDServer,pid) do
    #     # pid = self()
    #     # #IO.inspect(pid1)
    #     status = checkUniqueID(processIDServer,clientID)
    #     if status == :ok do
    #        GenServer.cast(processIDServer,{:registerUser, clientID, pid})
    #         #after registration login
    #         loginUser(clientID,pid,noOfTweets,noToSubscribers,processIDServer)
    #         :timer.sleep(50) 
    #     else
    #         IO.puts("Duplicate ID")
    #     end
    # end
      
    def subscribeList(count,noOfSubs,list) do
        if count == noOfSubs do 
            [count | list]
        else
            subscribeList(count+1,noOfSubs,[count | list]) 
        end
    end
    def pickATweet2(processIDServer,user_id,subscribe) do
    	#pick the last tweet to retweet
    	tweetData = GenServer.call(processIDServer,{:randTweet,user_id,subscribe})
        # IO.inspect tweetData
    	tweetData
    end

   

    def handle_cast({:retweeting, processIDServer, userId}, state)  do
         # :timer.sleep(100)
        #ReTweet
        # IO.inspect("hi")
        tweetData = pickATweet(processIDServer,userId)
        tweetData1 = ["Retweeting "] ++ tweetData
        # IO.inspect("Initial Retweet: #{tweetData}")
        GenServer.cast(processIDServer,{:retweet,userId,tweetData1})
        {:noreply, state}
    end

    def pickATweet(processIDServer,user_id) do
    	#pick the last tweet to retweet
    	tweetData = GenServer.call(processIDServer,{:randTweet,user_id})
        # IO.inspect tweetData
    	tweetData
    end

    def simulator_calls(userId,noOfTweets,noToSubscribe,processIDServer) do

        #Subscribe
        if noToSubscribe > 0 do
            subList = subscribeList(1,noToSubscribe,[])
            # handle_zipf_subscribe(userId,subList)
        end
        #previous users id used for mentions
        userToMention = :rand.uniform(userId)
        GenServer.cast(processIDServer,{:tweets,userId,"user#{userId} tweeting @#{userToMention+3}"})

        #Hashtag
        GenServer.cast(processIDServer,{:tweets,userId,"user#{userId} tweeting that #COP5615isgreat "})

        #Send Tweets
        for _ <- 1..noOfTweets do
        	temp = :rand.uniform(userId)
            GenServer.cast(processIDServer,{:tweets,userId,"user#{userId} tweeting that #{temp} does not make sense"})
        end

        #Queries - mywall
        temp1 = userId-1
        # IO.inspect(temp1)
        if temp1 > 0 do
            subscribeto = :rand.uniform(temp1)
            for x <- 1..subscribeto do
                GenServer.cast(processIDServer,{:iSubscribed,userId,x})
            end 
        end
        # IO.inspect(userId)
        # IO.puts "Followers"
        # IO.inspect(:ets.lookup(:followers, userId))
        # IO.puts "Following"
        # IO.inspect(:ets.lookup(:following, userId))
        


        #query hashtag
        GenServer.cast(processIDServer,{:queryHashtag, userId, "#COP5615isgreat"})
        # GenServer.cast(processIDServer,{:queryHashtag, userId, "#{userId}"})

        #querying mentions
        GenServer.cast(processIDServer,{:queryMentions, userId})
       
        #Get All Tweets
        GenServer.cast(processIDServer,{:meTweeting, userId})
        #Live View
        # handle_liveView(userId)
        if userId == 5 do
            GenServer.cast(processIDServer,{:deleteAccount, userId})   
        end
    end

  

	def handle_cast({:live_tweets, user_id, tweetData}, state) do
	    IO.puts "Tweet from #{user_id} : #{tweetData} 
        "
        # #IO.inspect "\n"
	    {:noreply, state}
	end

end