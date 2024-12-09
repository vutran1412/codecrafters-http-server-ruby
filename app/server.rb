require "socket"

server = TCPServer.new("localhost", 4221)
client_socket, client_address = server.accept
line = client_socket.gets
target = line.split(' ')[1]
if target == "/"
  client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"
else
  client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
end
