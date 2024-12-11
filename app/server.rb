require "socket"
require "optparse"

class FileServer
  def initialize(port, directory)
    @port = port
    @directory = directory
    validate_directory
  end

  def start
    server = TCPServer.new("localhost", @port)
    if @directory
      puts "Server running on #{@port}, serving files from #{@directory}"
    else
      puts "Server running on #{@port}"
    end

    loop do
      client_socket = server.accept
      Thread.new(client_socket) { |socket| handle_request(socket) }
    end
  end

  private

  def validate_directory
    unless Dir.exist?(@directory)
      puts "Error: Directory #{@directory} does not exist."
      exit 1
    end
  end

  def handle_request(socket)
    puts "Client connected"
    request = parse_request(socket)

    if request
      process_request(socket, request)
    else
      send_response(socket, 400, "Bad Request")
    end
  rescue => e
    puts "Error handling client: #{e.message}"
  ensure
    socket.close
    puts "Client disconnected"
  end

  def parse_request(socket)
    headers = []
    while (line = socket.gets)
      break if line.strip.empty?
      headers << line.strip
    end

    puts "Request Headers:\n#{headers.join("\n")}"
    {
      request_line: headers.shift.split(" ", 3),
      headers: headers
    }
  end

  def process_request(socket, request)
    method, path, _http_version = request[:request_line]

    case path
    when "/"
      send_response(socket, 200, "Welcome to the File Server!")
    when %r{^/files/(.+)}
      serve_file(socket, Regexp.last_match(1))
    when %r{^/echo/(.+)}
      send_response(socket, 200, Regexp.last_match(1))
    when "/user-agent"
      handle_user_agent(socket, request[:headers])
    else
      send_response(socket, 404, "Not Found")
    end
  end

  def serve_file(socket, file_name)
    file_path = File.join(@directory, file_name)
    if File.exist?(file_path) && File.file?(file_path)
      file_contents = File.read(file_path)
      send_response(socket, 200, file_contents, "application/octet-stream", file_contents.bytesize)
    else
      send_response(socket, 404, "File Not Found")
    end
  end

  def handle_user_agent(socket, headers)
    user_agent_header = headers.find { |header| header.start_with?("User-Agent:") }
    if user_agent_header
      user_agent = user_agent_header.split(": ", 2)[1].strip
      send_response(socket, 200, user_agent, "text/plain", user_agent.bytesize)
    else
      send_response(socket, 400, "User-Agent Not Found")
    end
  end

  def send_response(socket, status_code, body, content_type = "text/plain", content_length = nil)
    content_length ||= body.bytesize
    socket.puts "HTTP/1.1 #{status_code} #{status_message(status_code)}\r"
    socket.puts "Content-Type: #{content_type}\r"
    socket.puts "Content-Length: #{content_length}\r"
    socket.puts "\r\n"
    socket.puts body
  end

  def status_message(code)
    case code
    when 200 then "OK"
    when 400 then "Bad Request"
    when 404 then "Not Found"
    else "Internal Server Error"
    end
  end
end

options = {}
OptionParser.new do |opts|
  opts.on("--directory DIR", "Directory to serve files from") { |dir| options[:directory] = dir }
  opts.on("--port PORT", Integer, "Port to run the server on") { |port| options[:port] = port }
end.parse!

directory = options[:directory] || "./"
port = options[:port] || 4221
FileServer.new(port, directory).start
