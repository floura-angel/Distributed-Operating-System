defmodule TwitterCloneWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
        {:ok, socket}
    end
    def join("room:"<> _private_room_id, _params, _socket) do
        {:error, %{reason: "unauthorized"}}
    end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  def handle_in("register", payload, socket) do         
      username = payload["name"]
      password = payload["password"]
      IO.inspect GenServer.call(:Server, {:registerUser, username, password}) 
      push socket, "registered",  %{"name" => username}     
      {:reply, :registered, socket}
    end

    def handle_in("login", payload, socket) do
      username = payload["name"]
      password = payload["password"]
      IO.inspect  GenServer.call(:Server, {:login, username, password, socket})
      {:reply, :loginSucess, socket}
    end
    
    def handle_in("logout", payload, socket) do
      username = payload["name"]      
      IO.inspect  GenServer.call(:Server, {:logout, username, socket})
      {:reply, :logoutSucess, socket}
    end

    def handle_in("subscribe", payload, socket) do
      # IO.inspect payload["following"] 
      followed_username1 = payload["following"]   
      #my name 
      # x = [followed_username]
      follower_username = payload["follower"]
      type_op = payload["type"]
      followed_username = 
      if type_op == "single" do
        [followed_username1]
      else
        followed_username1
      end   

      Enum.each(followed_username, fn followme -> 
         IO.inspect  GenServer.call(:Server, {:follow, followme, follower_username})
       end) 
      # IO.inspect  GenServer.call(:Server, {:follow, followed_username, follower_username})
      push socket, "subscribed",  %{"name" => follower_username}
      {:reply, :subscribed, socket}
    end

    def handle_in("mytweet", payload, socket) do
      username = payload["name"]
      tweet = payload["tweet"]    
      IO.inspect GenServer.cast(:Server, {:mytweet, username, tweet})
      push socket, "tweeting",  %{"name" => username}
      {:reply, :tweeting, socket}
    end       

    def handle_in("send_retweet", payload, socket) do
      #mynme
      username1 = payload["username1"]
      username2 = payload["username2"]
      tweet = payload["tweet"]         
      IO.inspect  GenServer.cast(:Server, {:retweet, username1, username2, tweet})
      {:noreply, socket}
    end    

    def handle_in("search_hashtag", payload, socket) do      
      hashtag = Map.get(payload, "hashtag")      
      response =  GenServer.call(:Server, {:search_hashtag, hashtag})
      msg = "Search result for hashtag #{hashtag} : #{response}"
      push  socket, "receive_response", %{"message" => msg}
      {:reply, :requestHashtag, socket}
    end  

    def handle_in("search_username", payload, socket) do
      username = Map.get(payload, "username")      
      response =  GenServer.call(:Server, {:search_user, username})
      msg = "Search result for username #{username} : #{response}"
      push  socket, "receive_response", %{"message" => msg}
      {:reply, :requestMentions, socket}
    end  

    def handle_in("receive_tweet", payload, socket) do      
      {:noreply, socket}
    end
  
end
