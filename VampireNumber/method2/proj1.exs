if length(System.argv()) == 2 do
      start_range = String.to_integer(Enum.at(System.argv, 0))
      stop_range = String.to_integer(Enum.at(System.argv, 1))
      # Boss.mainfunction(start_range,stop_range)
      Trial2.boss(start_range,stop_range)
else
      IO.puts("Incorrect arguments")
end
