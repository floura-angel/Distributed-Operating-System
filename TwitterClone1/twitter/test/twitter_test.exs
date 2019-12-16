defmodule TwitterTest do
  use ExUnit.Case
  doctest Twitter
    setup do
      {server_pid} = Engine.start_link(2)
      {:ok,server: server_pid}
    end
  test "registeration", %{server: pid} do
       ## check whether user is registered with Server
       pid1=Client.start_link(1,1,5,pid)
       Process.sleep(1000)
       assert  Engine.check_member(1)== :ok
          
       pid2=Client.start_link(2,1,5,pid)
       Process.sleep(1000)
       assert Engine.check_member(2)== :ok
       
       ## checking not registered user
       assert Engine.check_member(110)== :not_ok
   end

  test "Login", %{server: pid} do 
       #check whether user logs in or not
       pid3=Client.start_link(3,1,5,pid)
       assert  Engine.check_login(3)== :ok
       #check whether unregistered user is able to login
       assert  Engine.check_login(4)== :not_ok
       Process.sleep(1000)
       #logging out user 3 
       GenServer.cast(pid,{:logout,3})
       Process.sleep(1000)
       # Checking user 3 is logged in ?
       assert  Engine.check_login(3)== :not_ok

  end

  test "check_duplicate",%{server: pid} do
    #Registering a user
    pid1=Client.start_link(15,1,5,pid)
    Process.sleep(1000)
    assert  Engine.check_member(15)== :ok
    Process.sleep(1000)
    #Checking whether a user_id planning to give is present or not
    assert  Engine.checkDuplicate(15)==:not_ok
    #Checking a new user_id
    assert   Engine.checkDuplicate(102)==:ok
  end 

  
   
   test "Logout", %{server: pid} do
      pid7=Client.start_link(10,1,5,pid)
      assert  Engine.check_login(10)== :ok
      GenServer.cast(pid,{:logout,10})
      Process.sleep(2000)
      #Checking logout
      assert Engine.check_logout(10)==:ok
      GenServer.cast(pid,{:login,10,pid7})
      Process.sleep(1000)
      #Checking Logout after logging in 
      assert Engine.check_logout(10)==:not_ok
   end

  test "hashtags",%{server: pid} do
    pid4=Client.start_link(4,1,5,pid)
    assert  Engine.check_login(4)== :ok
    #user 4 uses a hashtag 
    #COP5615isgreat is a predifined hashtag used for simulation
    assert :ets.member(:hashtags,"#COP5615isgreat")== true
    #hashtag not used by user 4
    assert :ets.member(:hashtags,"#FlouraNadar")!= true
    #user 4 now uses the above hashtag
    GenServer.cast(pid,{:tweets,4,"user#{4} tweeting that #FlouraNadar"})
    Process.sleep(1000)
    #now the hashtag exists
    assert :ets.member(:hashtags,"#FlouraNadar")== true
  end

  test "mentions",%{server: pid} do
    pid5=Client.start_link(5,1,5,pid)
    assert Engine.check_login(5)== :ok
    #user mentioning someone
    GenServer.cast(pid,{:tweets,5,"user#{5} tweeting @#{8}"})
    Process.sleep(1000)
    assert :ets.member(:mentions,"@#{8}")==true
    #user has not been mentioned
    assert :ets.member(:mentions,"@#{100}")!= true
  end

    test "check_delete", %{server: pid} do
      pid6=Client.start_link(7,1,5,pid)
      assert Engine.check_login(7)== :ok
       #deleting account
       GenServer.cast(pid,{:deleteAccount,7})
       Process.sleep(2000)
       # trying to check still a member
       assert Engine.check_member(7)==:not_ok
       # trying to delete a not existing user
       assert Engine.delete_account(100)==:not_ok
    end

   test "check_subscribe", %{server: pid} do
      pid8=Client.start_link(8,1,5,pid)
      assert Engine.check_login(8)== :ok
      pid9=Client.start_link(9,1,5,pid)
      assert Engine.check_login(9)== :ok
      # user 9 subscribes user 8
      Engine.subscribeTwoUsers(pid,9,8)
      Process.sleep(2000)
      #checking whether 9 is a follower of 8
      assert Engine.check_subscribers(8,9)==:ok
      assert Engine.check_subscribers(8,100)==:not_ok
    end

    test "check_send_tweet", %{server: pid} do
      pid10=Client.start_link(11,1,5,pid)
      assert Engine.check_login(11)== :ok
      pid9=Client.start_link(12,1,5,pid)
      assert Engine.check_login(12)== :ok
      #user 12 subscribes to 11
      Engine.subscribeTwoUsers(pid,12,11)
      Process.sleep(2000)
      assert Engine.check_subscribers(11,12)==:ok
      # user 11 sends a tweet
      GenServer.cast(pid,{:tweets,11,"This is a test tweet from #{11}to follower #{12}"})
      Process.sleep(1000)
      #checking whether the user 12 has received tweet
      assert Engine.check_recievedTweet(12,11,"This is a test tweet from #{11}to follower #{12}")== :ok
      pid11=Client.start_link(13,1,5,pid)
      assert Engine.check_login(13)== :ok
      #user 13 has not  subscribed to 11
      assert Engine.check_recievedTweet(13,11,"This is a test tweet from #{11}to follower #{12}")== :not_ok
      Engine.subscribeTwoUsers(pid,13,12)
      Process.sleep(1000)
      GenServer.cast(pid,{:tweets,12,"This is a test tweet from #{12}to follower #{13}"})
      Process.sleep(1000)
      #checking whether the user 13 receives the right tweet
      assert Engine.check_recievedTweet(13,12,"This is a wrong test tweet from #{12}to follower #{13}")== :not_ok
    end    
   
    # test "checking_re-tweet",%{server: pid} do
    #   pid18=Client.start_link(18,1,5,pid)
    #   assert Engine.check_login(18)== :ok
    #   pid19=Client.start_link(19,1,5,pid)
    #   assert Engine.check_login(19)== :ok
    #   # user 19 subscribes user 18
    #   Engine.subscribeTwoUsers(pid,19,18)
    #   Process.sleep(1000)
    #   GenServer.cast(pid,{:tweets,18,"This is a test tweet from #{18}to follower #{19}"})
    #   Process.sleep(1000)
    #   pid20=Client.start_link(20,1,5,pid)
    #   assert Engine.check_login(20)== :ok
    #   Engine.subscribeTwoUsers(pid,20,19)
    #   Process.sleep(1000)
    #   Engine.retweettwo(pid,19,18)
    #   Process.sleep(1000)
    #   assert Engine.check_recievedTweet(20,19,"This is a test tweet from #{18}to follower #{19}")== :ok
    # end

end

