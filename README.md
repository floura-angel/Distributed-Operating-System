# Distributed-Operating-System


VAmpire Niumber: An interesting kind of number in mathematics is vampire number. A vampire number is a composite natural number with an even number of digits, that can be factored into two natural numbers each with half as many digits as the original number and not both with trailing zeroes, where the two factors contain precisely all the digits of the original number, in any order, counting multiplicity. A classic example is: 1260= 21 x 60.

Gossip protocol: Gossip type algorithms can be used both for group communication and for aggregate computation. The goal of this project is to determine the convergence of such algorithms through a simulator based on actors written in Elixir. Since actors in Elixir are fully asynchronous, the particular type of Gossip implemented is the so-called Asynchronous Gossip.

Tapestry: The goal of this project is to implement in Elixir using the actor model the Tapestry Algorithm and a simple object access service to prove its usefulness by implementing network join and routing.

TwitterClone: The goal of this is to implement a Twitter-like engine and pair up with Web Sockets to provide full functionality. 
1. Register account and delete account
2. Send tweet. Tweets can have hashtags (e.g. #COP5615isgreat) and mentions (@bestuser). You can use predefines categories of messages for hashtags.
3. Subscribe to user's tweets.
4. Re-tweets (so that your subscribers get an interesting tweet you got by other means).
5. Allow querying tweets subscribed to, tweets with specific hashtags, tweets in which the user is mentioned (my mentions).
6. If the user is connected, deliver the above types of tweets live (without querying).
