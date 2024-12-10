require "socket"

server = TCPServer.new("localhost", 4221)
puts "Server running on port 4221"
loop do
  client_socket, client_address = server.accept
  Thread.new(client_socket) do |socket|
    begin
      puts "Client connected"
      headers = []
      while (line = socket.gets)
        break if line.strip.empty?
        headers << line
      end
      puts "Request Headers:\n#{headers.join("\n")}"
      request_line = headers.first
      if request_line
        method, path, _http_version = request_line.split(" ")
        if path == "/"
          socket.puts "HTTP/1.1 200 OK\r\n\r\n"
        elsif path == "/user-agent"
          user_agent = headers.find { |header| header.start_with?("User-Agent:") }
          if user_agent
            user_agent = user_agent.split(": ", 2)[1]
            response_body = user_agent.strip
            socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{response_body.bytesize}\r\n\r\n#{response_body}"
          else
            socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
          end
        elsif path.start_with?("/echo/")
          response_body = path.split("/echo/").last
          socket.puts "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{response_body.bytesize}\r\n\r\n#{response_body}"
        else
          socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
        end
      else
        socket.puts "HTTP/1.1 400 Bad Requst\r\n\r\n"
      end
    rescue => e
      puts "Error handling client: #{e.message}"
    ensure
      socket.close
      puts "Client disconnected"
    end
  end
end
