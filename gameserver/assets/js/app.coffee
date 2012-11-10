window.onload = ->
  
  # Connect to socket.io
  socket = io.connect()

  # React to a received message
  socket.on "ping", (data) ->
    
    # Modify the DOM to show the message
    # document.getElementById("msg").innerHTML = data.msg
    
    # Send a message back to the server
    socket.emit "pong",
      msg: "The web browser also knows socket.io."