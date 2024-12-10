require "socket"

server = TCPServer.new("localhost", 4221)
puts "Server running on port 4221"
loop do
  client_socket, client_address = server.accept
  puts "Client connected"
  headers = []
  while (line = client_socket.gets)
    break if line.strip.empty?
    headers << line
  end
  puts "Request Headers:\n#{headers.join("\n")}"
  request_line = headers.first
  if request_line
    method, path, _http_version = request_line.split(" ")
    if path == "/"
      client_socket.puts "HTTP/1.1 200 OK\r\n\r\n"
    elsif path == "/user-agent"
      user_agent = headers.find { |header| header.start_with?("User-Agent:") }
      if user_agent
        user_agent = user_agent.split(": ", 2)[1]
        response_body = user_agent.strip
        client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{response_body.bytesize}\r\n\r\n#{response_body}"
      else
        client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
      end
    elsif path.start_with?("/echo/")
      response_body = path.split("/echo/").last
      client_socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{response_body.bytesize}\r\n\r\n#{response_body}"
    else
      client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
    end
  else
    client_socket.puts "HTTP/1.1 400 Bad Requst\r\n\r\n"
  end
  client_socket.close
  puts "Client disconnected"
end
