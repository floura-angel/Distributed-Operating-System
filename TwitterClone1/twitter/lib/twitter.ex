defmodule Twitter do
  
  def main(numUsers,numMsgs,as) do
    if as == "server" do
    	processIDServer = Engine.start_link(numUsers)
    	#global registration
    	# :global.register_name(:Server,processIDServer)
    	# IO.inspect(elem(processIDServer,0))
    	#simulation
    	simulate(numUsers,numMsgs,processIDServer)
    # else
    # 	if as == "client" do
    # 		create_users(numUsers,processIDServer)
    # 	end
    end

  end

  def simulate(numUsers,numMsgs,processIDServer) do
  	pid_user = create_users(numUsers,numMsgs,processIDServer)
  	Enum.map(pid_user, fn(userId) -> (
  			# IO.inspect(userId)
  			retweet(elem(processIDServer,0),elem(userId,1),elem(userId,0))
    	)end)
  	# IO.inspect(pid_user)
    # retweet()
    if Mix.env != :test do
    Enum.map(pid_user, fn(userId) -> (
             IO.inspect(userId)
            GenServer.cast(elem(elem(userId,1),0),{:logout, elem(processIDServer,0), elem(userId,0)})
        )end)
    end

  end 

  def retweet(processIDServer,userpid,userId) do
  	# IO.inspect(userId)
  	userId_temp = userId
  	pid = elem(userpid,0)
  	# IO.inspect("Retweeting for #{userId}")
  	:timer.sleep(50)
  	GenServer.cast(pid,{:retweeting, processIDServer, userId_temp})
  end

  #simulating registration of an account
  def create_users(numUsers,numMsgs,processIDServer) do
  	pid_user=
        Enum.map(1..numUsers, fn(userId) -> (
            # clientID=String.to_atom("#{userId}") 
            noOfTweets = numMsgs
        	noToSubscribers = numUsers-userId
            pid = Client.start_link(userId,noOfTweets,noToSubscribers,processIDServer) 
            # IO.inspect(pid)
         )  
        {userId,pid}
    	end)
    # IO.inspect(pid_user)
    pid_user
    end

end
