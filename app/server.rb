require "socket"

server = TCPServer.new("localhost", 4221)
client_socket, client_address = server.accept
client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"
