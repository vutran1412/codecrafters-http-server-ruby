require "socket"

server = TCPServer.new("localhost", 4221)
client_socket, client_address = server.accept
line = client_socket.gets
puts line.inspect
target = line.split(' ')[1]
if target == "/"
  client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"
elsif target.include?("/echo/")
  response_body = target.split("/").last
  client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{response_body.bytesize}\r\n\r\n#{response_body}"
else
  client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
end
