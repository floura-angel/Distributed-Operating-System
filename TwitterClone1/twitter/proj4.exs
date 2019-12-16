# IO.inspect(System.argv())
if length(System.argv()) == 2 do
      numUsers = String.to_integer(Enum.at(System.argv, 0))
      numMsgs = String.to_integer(Enum.at(System.argv, 1))
      # Boss.mainfunction(start_range,stop_range)
      Twitter.main(numUsers,numMsgs,"server")
else 
	if length(System.argv()) == 0 do
		Twitter.main(0,0,"server")
	else
		numUsers = String.to_integer(Enum.at(System.argv, 0))
      	numMsgs = String.to_integer(Enum.at(System.argv, 1))
		Twitter.main(numUsers,numMsgs,"server")
	end   
end
