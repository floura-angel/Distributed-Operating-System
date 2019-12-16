defmodule Base.Api do

    def initialize do
        :ets.new(:hashtags, [:set, :public, :named_table, read_concurrency: true])
        :ets.new(:mentions, [:set, :public, :named_table, read_concurrency: true])
        :ets.new(:clients, [:set, :public, :named_table, read_concurrency: true])
        :ets.new(:activeUsers,[:set, :public, :named_table, read_concurrency: true])
        #subsribers
        tableInitialize()
    end

    def tableInitialize do
    end

    def register_new_user(username, password) do        
        if check_username(username) == false do
            #username, password, node_name, login_state, session_Id, tweet_list, following_list, follower_list
            :ets.insert_new(:clients, {username, password, :null, false, :null, [], [], []})
            {:ok, "#{username} registered successfully."}
        else
            {:error, "#{username} already exist."}
        end
        
    end

    def get_node_name(username) do
        case :ets.lookup(:clients, username) do
            [{_, _, node_name, _, _, _, _, _}] -> {:ok, node_name}
            [] -> {:error, "Unable to retrieve node name because username is invalid"}
        end        
    end

    def get_online_status(username) do
        if :ets.member(:activeUsers,username) == true do
            true
        else
            false
        end       
    end    

    def check_username(username) do
        case :ets.lookup(:clients, username) do
            [{_, _, _, _, _, _, _, _}] -> true
            [] -> false
        end
    end

    #username, password, node_name, login_state, session_Id, tweet_list, following_list, follower_list
    def loginUser(username, password, session_Id) do
        #session id = socketid
        case :ets.lookup(:clients, username) do
            [{username, pass, node_name, login, id, tweet_list, following_list, follower_list}] -> 
                if login == false do
                    if pass == password do
                        :ets.insert(:clients, {username, password, session_Id, 
                            true, session_Id, tweet_list, following_list, follower_list})
                        :ets.insert(:activeUsers, {username, true})
                        {:ok, "#{username} logged In"}    
                    else
                        {:error, "Wrong Password"}                       
                    end
 
                else
                    {:error, "Logged in already"}
                end                
            [] -> {:error, "Invalid user"}
        end
    end

    def logoutUser(username, session_Id) do
        [{username, password, node_name, _, id, tweet_list, following_list, follower_list}] = :ets.lookup(:clients, username)
        if :ets.member(:activeUsers,username) == true do
            :ets.insert(:clients, {username, password, node_name, false, :null, tweet_list, following_list, follower_list}) 
            :ets.delete(:activeUsers, username) 
            {:ok, "#{username} logged out"}    
        else
            {:error, "Invalid, not Active"} 
        end 
    end

    def get_activeUsers(username) do
        case :ets.lookup(:clients, username) do
            [{_, _, _, _, _, tweet_list, _, _}] -> {:ok, tweet_list}
            [] -> {:error, "Unable to retrieve activeUsers because username is invalid"}
        end
    end

    def insert_tweet(username, tweet) do
        case :ets.lookup(:clients, username) do
            [{username, password, node_name, login_state, session_Id, tweet_list, following_list, follower_list}] -> 
                :ets.insert(:clients, {username, password, node_name, login_state, session_Id, [tweet | tweet_list], following_list, follower_list})
                {:ok, "Tweet successfully sent"}
            [] -> {:error, "Unable to send tweet. Please try again."}
        end       
    end    

    def subscribe(followed_username, follower_username) do  
    [{fusername, fpassword, fnode_name, flogin_state, fsession_Id, ftweet_list, ffollowing_list, ffollower_list}] =  :ets.lookup(:clients, follower_username)   
        case :ets.lookup(:clients, followed_username) do
            [{username, password, node_name, login_state, session_Id, tweet_list, following_list, follower_list}] -> 
                :ets.insert(:clients, {username, password, node_name, login_state, session_Id, tweet_list, following_list, [follower_username | follower_list]})
                :ets.insert(:clients, {fusername, fpassword, fnode_name, flogin_state, fsession_Id, ftweet_list, [follower_username | ffollowing_list], ffollower_list})
                {:ok, "Subsribed and added in following and followers list"}
            [] -> {:error, "Can't subscribe"}
        end     
    end    
    

    def get_follower(username) do        
        case :ets.lookup(:clients, username) do
            [{_, _, _, _, _, _, _, follower_list}] ->                
                {:ok, follower_list}
            [] -> {:error, []}
        end     
    end     

    def get_following(username) do        
        case :ets.lookup(:clients, username) do
            [{_, _, _, _, _, _, following_list, _}] ->                
                {:ok, following_list}
            [] -> {:error, []}
        end     
    end
    
    def remove_follower(followed_username, follower_username) do        
        case :ets.lookup(:clients, followed_username) do
            [{username, password, node_name, login_state, tweet_list, following_list, follower_list}] -> 
                follower_list = List.delete(follower_list, follower_username)
                :ets.insert(:clients, {username, password, node_name, login_state, tweet_list, following_list, follower_list})
                {:ok, ""}
            [] -> {:error, ""}
        end     
    end    
    
    def remove_following(followed_username, follower_username) do        
        case :ets.lookup(:clients, follower_username) do
            [{username, password, node_name, login_state, tweet_list, following_list, follower_list}] -> 
                following_list = List.delete(following_list, followed_username)
                :ets.insert(:clients, {username, password, node_name, login_state, tweet_list, following_list, follower_list})
                {:ok, "You have successfully unfollowed #{followed_username}"}
            [] -> {:error, "Unable to unfollow #{followed_username}"}
        end     
    end

    def insert_hashtag(hashtag, tweet) do
        if :ets.lookup(:hashtags, hashtag) != [] do
            [tempn3] = :ets.lookup(:hashtags, hashtag)
            :ets.insert(:hashtags,{hashtag,[tweet | elem(tempn3,1)]})
        else
            :ets.insert(:hashtags,{hashtag,[tweet]})
        end
    end

    def insert_mentions(user, tweet) do
        mentions = String.slice(user,1..-1)
        if :ets.lookup(:mentions, mentions) != [] do
            [tempn2] = :ets.lookup(:mentions, mentions)
            :ets.insert(:mentions,{mentions,[tweet | elem(tempn2,1)]})            
        else
            :ets.insert(:mentions,{mentions,[tweet]})
        end
    end

    def get_hashtag(hashtag) do        
        case :ets.lookup(:hashtags, hashtag) do
            [{hashtag, tweet_list}] -> tweet_list
            [] -> "Cannot find the hashtag #{hashtag}"
        end
    end
    
    def get_username(username) do        
        case :ets.lookup(:mentions, username) do
            [{username, tweet_list}] -> tweet_list
            [] -> "Cannot find the Username #{username}"
        end
    end    
end