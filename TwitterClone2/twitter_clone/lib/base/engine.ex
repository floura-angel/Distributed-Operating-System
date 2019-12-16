defmodule Base.Engine do
    use GenServer
    use Phoenix.Channel

    def start_link do
        Base.Api.initialize
        GenServer.start_link(__MODULE__, [0], name: :Server)
    end

    def handle_call({:registerUser, username, password}, _from, state) do        
       {:reply, Base.Api.register_new_user(username, password), state}   
   end

   def init(init_arg) do
      {:ok, init_arg}
    end

   def handle_call({:login, username, password, socket}, _from, state) do
        #session_Id = :crypto.hash(:sha256, username.to) |> Base.encode16
        {:reply, Base.Api.loginUser(username, password, socket), state}
    end

    def handle_call({:logout, username, session_Id}, _from, state) do
        {:reply, Base.Api.logoutUser(username, session_Id), state}        
    end

    def handle_call({:hit_counter}, _from, state) do
        count = Enum.at(state, 0)
        {:reply, count, state}        
    end

    def handle_call({:fetch_tweets, username, session_key}, _from, state) do

        {:reply, state}
    end    

    def handle_call({:follow, followed_username, follower_username}, _from, state) do
        {:reply, Base.Api.subscribe(followed_username, follower_username), state}
    end

    def handle_call({:unfollow, followed_username, follower_username, follower_session_key}, _from, state) do        
        {:reply, state}
    end

    def handle_call({:follower, username, follower_session_key}, _from, state) do        
        {:reply, Base.Api.get_follower(username), state}
    end
    
    def handle_call({:following, username, follower_session_key}, _from, state) do
        {:reply, Base.Api.get_following(username), state}        
    end    
    
    def handle_cast({:mytweet, username, tweet}, state) do
        counter = 0
        if Base.Api.get_online_status(username) do
            retrieveHashTags = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet)
            Enum.each(Enum.concat(retrieveHashTags), fn hashtag -> 
                Base.Api.insert_hashtag(hashtag, tweet)
            end)  
            retrieveMentions = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweet)
            Enum.each(Enum.concat(retrieveMentions), fn mentions -> 
                Base.Api.insert_mentions(mentions, tweet) 
            end)
        end
        counter = Enum.at(state, 0)
        case Base.Api.insert_tweet(username, tweet) do
            {:ok, msg} ->
            case Base.Api.get_follower(username) do
                {:ok, follower_list} ->
                len = length(follower_list)
                counter = counter + len
                for follower <- follower_list do
                    if Base.Api.get_online_status(follower) do
                        case Base.Api.get_node_name(follower) do                                                      
                        {:ok, node_name} ->         
                        IO.inspect follower                                       
                        push  node_name, "receive_tweet", %{"message" => tweet, "name" => username} 
                        {:error, msg} -> IO.inspect msg
                        end
                    else
                        {:error, "Error in getting login status" }                                                                      
                    end                         
                end
                {:error, _} -> "Error in getting follower list"
            end
            {:error, msg} -> IO.inspect "Error in sending tweet"    
        end                                    
    {:noreply, [counter]}
    end

    def handle_cast({:retweet, username1, username2, tweet}, state) do
        counter = Enum.at(state, 0)        
        case Base.Api.insert_tweet(username1, tweet) do
            {:ok, msg} ->
            case Base.Api.get_follower(username1) do
                {:ok, follower_list} ->
                len = length(follower_list)
                counter = counter + len
                for follower <- follower_list do
                    if Base.Api.get_online_status(follower) do
                        case Base.Api.get_node_name(follower) do                                          
                            {:ok, node_name} ->  
                            counter = counter + 1
                            push  node_name, "receive_retweet", %{"message" => tweet, "username1" => username1, "username2" => username2}
                            {:error, msg} -> IO.inspect msg
                        end
                    else
                        {:error,"Error in getting login status" }
                    end                                                                                                   
                end
                {:error, _} -> "Error in getting follower list"
            end
            {:error, msg} -> IO.inspect "Error in sending tweet"    
        end                 
        {:noreply, [counter]}
        end    

    def handle_call({:search_following_tweet, keyword}, _from, state) do        
        {:reply, state}
    end

    def handle_call({:search_hashtag, tag}, _from, state) do        
        counter = Enum.at(state, 0)
        counter = counter + 1        
        {:reply, Base.Api.get_hashtag(tag), [counter]}
    end

    def handle_call({:search_user, username}, _from, state) do   
        counter = Enum.at(state, 0)
        counter = counter + 1        
        {:reply, Base.Api.get_username(username), [counter]}
    end    

    end