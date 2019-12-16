import {Socket} from "phoenix"

var numClients
var channelsList = []
var socketsList = []
let maxClients = 100
let userFollowers = {}
let userNamesList = []
let userName
let password
let messageContainer = document.querySelector('#message-list')
var clientsProcessed = 0

register()

function register(){
  for (numClients = 0; numClients < maxClients; numClients++){
      userName = "client_"+numClients
      password = "password_"+numClients
      let socket = new Socket("/socket", {params: {token: window.userToken, userName: userName}})
      userNamesList[numClients] = userName
      userFollowers[userName] = []
      socket.connect()
      socketsList[numClients] = socket
      let channel = socket.channel("room:lobby", {})
      channelsList[numClients] = channel
      channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })
      channel.push("register", { name: userName, password: password })
      .receive("registered" , resp => console.log("registered", resp))
    }
  for (let channel of channelsList){
    // console.log("hii")
      channel.on("registered", payload => {
        clientsProcessed++
        // console.log("you")
        if (clientsProcessed === maxClients-1){
          // console.log("inside subscribe")
          subscribe()
        }
      })
  }
}

function subscribe() {
  // console.log("inside subscribe")
  var numSubscribers, subscribersList;
  for (numClients = 0; numClients < maxClients; numClients++){
    numSubscribers = Math.floor((maxClients-2)/(numClients+1)) 
    if (numSubscribers == 0){
      numSubscribers = 1
    }
    subscribersList = getRandom(userNamesList, numSubscribers)
    var user = userNamesList[numClients]

    let ch = channelsList[numClients]

    ch.push("subscribe", {following: subscribersList, follower:user  , type:"more"})
    .receive("subscribed", resp => console.log("subscribed", user))
  }
   var clientssubscribed= 0
  for (var i = 0; i<maxClients; i++){
    channelsList[i].on("subscribed", payload => {
      clientssubscribed++
      console.log("subscribed", clientssubscribed)

      if (clientssubscribed === maxClients){
        simulation()
      }
    })
  }
}

function getRandom(arr, n, i) {
  var result = new Array(n),
  len = arr.length,
  taken = new Array(len);
  if (n > len)
    throw new RangeError("getRandom: more elements taken than available");
  while (n--) {
    var x = randNum(arr, i);
    result[n] = arr[x in taken ? taken[x] : x];
    taken[x] = --len;
  }
  return result;
}

function randNum(arr,excludeNum){
  var randNumber = Math.floor(Math.random()*arr.length);
  if(arr[randNumber]==excludeNum){
      return randNum(arr,excludeNum);
  }else{
      return randNumber;
  }
}

var clearCounter = 0

function simulation(){
  console.log("simulation started")
  let times = maxClients
  while (clearCounter < times){
    for (var i = 0; i < userNamesList.length; i++){
      var runBehavior = getRandom(["send_tweet", "search_hashtag", "search_mentions"], 1)
      switch (runBehavior[0]){
        case("send_tweet"):
          console.log("sending tweet", userNamesList[i])
          sendTweet(i)
        break
        case("search_hashtag"):
          console.log("searching for hashtag", userNamesList[i])
          var hashtagList = "#DOSisgreat"
          channelsList[i].push("search_hashtag", { hashtag: hashtagList});
        break
        case("search_mentions"):
          console.log("searching for mentions", userNamesList[i])
          channelsList[i].push('search_username', { username: userNamesList[i]})
        break
        // case("retweet"):
        //   console.log("Retweeting", userNamesList[i])
        //   channelsList[i].push('search_username', { username: userNamesList[i]})
        // break
        default:
        break
      }
      clearCounter++
    }
  }
}

function sendTweet(i){
  console.log("sending tweets")
  var numUsers = userNamesList.length
  var mention, tweetText, numSubscribers, interval
  mention = getRandom(userNamesList, 1)
  tweetText = "tweet@"+mention+ "#DOSisgreat"
  console.log(tweetText)
  numSubscribers = userFollowers[userNamesList[i]].len
  channelsList[i].push("mytweet", {name: userNamesList[i],tweet:tweetText})
  console.log("retweeting tweets")
  let temp = randNum(userNamesList,i)
  console.log(temp)
  channelsList[temp].push('send_retweet', { username1: userNamesList[temp], username2: userNamesList[i], tweet: tweetText});
 }

 export default socketsList