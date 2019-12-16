
import {Socket} from "phoenix"


let socket = new Socket("/socket", {params: {token: window.userToken}})

//authentication

socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("room:lobby", {});
let list    = $('#message-list');
let password = $('#password');
let name    = $('#name');
let login= $('#login')
let register= $('#register')
let sendtweetlist= $('#send-tweet-list')
let tweetbox = $('#tweetbox')
let followtxt=$('#followtext')
let homepagediv =$('#homepage')
let searchhashtagtext=$('#searchhashtag')
let messageContainer = document.querySelector('#message-list')



let searchusernametxt= $('#searchusername')


let retweetusernametxt=$('#retweetusername')
let retweettxt=$('#retweettxt')



let loggedinuser=name.val()



// searchhashtagbtn.on('click', event => {   
//   channel.push('search_hashtag', { hashtag: searchhashtagtext.val()});
 
// }
// );

document.getElementById("Hashtag").onclick=function(){
  channel.push('search_hashtag', { hashtag: searchhashtagtext.val()});
  
}


// searchusernamebtn.on('click', event => {
//   channel.push('search_username', { username: searchusernametxt.val()});
 
// }
// );

document.getElementById("Mentions").onclick=function(){
  channel.push('search_username', { username: searchusernametxt.val()});
}






// document.getElementById("Re-Tweet").onclick=function(){
//   channel.push('send_retweet', { username1: name.val(), username2: retweetusernametxt.val(), tweet: retweettxt.val()});
// }

document.getElementById("Tweet").onclick=function(){
  channel.push('mytweet', { name: name.val(), tweet: tweetbox.val()});
}

document.getElementById("Login").onclick=function(){
  channel.push('login', { name: name.val(), password: password.val() });
  password.val('');
  let messageItem = document.createElement("li");
      messageItem.innerText = `${name.val()} logged in at [${Date()}]`
      messageContainer.appendChild(messageItem)
     
  
}

document.getElementById("Register").onclick=function(){
  channel.push('register', { name: name.val(), password: password.val() });
  name.val('');
  password.val('');
 
}



document.getElementById('Clear').onclick = function () {
  messageContainer.innerHTML=""
 }

document.getElementById("Follow").onclick=function(){
  channel.push('subscribe', { following: followtxt.val(), follower: name.val(), type:"single"});
  
}

channel.on('receive_tweet', payload => {
  // list.append(`<b>${payload.name || 'Celebrity'} tweeted : </b> ${payload.message}<br>`);
  // list.prop({scrollTop: list.prop("scrollHeight")});
  let messageDiv = document.createElement("div")
    let messageItem = document.createElement("li");  
    let messageButton = document.createElement("button");    
    
    messageDiv.appendChild(messageItem)
    messageDiv.appendChild(messageButton)    
    messageItem.innerText = `${name.val()} Tweeted: [${Date()}] ${payload.message}`
    messageButton.innerText = "ReTweet"
    messageButton.class="btn btn-info"
    messageButton.style.display = "inline"
    messageButton.addEventListener('click', ()=>{
        channel.push("send_retweet", {username1: name.val() , username2: payload.name, tweet: payload.message })
    })
    // messageButton.style.float ="right"
    console.log(messageItem.innerText)
    messageContainer.appendChild(messageDiv)
});

channel.on('receive_retweet', payload => {
  list.append(`<b>${payload.username1 } retweeted ${payload.username2} tweet - </b> ${payload.message}<br>`);
  list.prop({scrollTop: list.prop("scrollHeight")});
  let messageDiv = document.createElement("div")
    let messageItem = document.createElement("li");  
    let messageButton = document.createElement("button");    
    
    messageDiv.appendChild(messageItem)
    messageDiv.appendChild(messageButton)    
    messageItem.innerText = `${name.val()} Tweeted: [${Date()}] ${payload.message}`
    messageButton.innerText = "ReTweet"
    messageButton.class="btn btn-info"
    messageButton.style.display = "inline"
    messageButton.addEventListener('click', ()=>{
        channel.push("send_retweet", {username1: name.val() , username2: payload.username1, tweet: payload.message })
    })
    // messageButton.style.float ="right"
    console.log(messageItem.innerText)
    messageContainer.appendChild(messageDiv)
});

channel.on('receive_response', payload => {
  // list.append(`${payload.message}<br>`);
  // list.prop({scrollTop: list.prop("scrollHeight")});
  let messageItem = document.createElement("li");
    messageItem.innerText = `[${Date()}] ${payload.message}`
    messageContainer.appendChild(messageItem)
});

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })


  export default socket