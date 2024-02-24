require 'socket'

# create tcp server
server = TCPServer.new('localhost', 3004)
puts "server is started #{Time.now}"

clients = []
@data_store = {}
COMMANDS = %w[GET SET]

loop do
  ready_sockets, _, _ = IO.select([server] + clients)

  ready_sockets.each do |socket|
    if socket == server
      client = server.accept
      clients << client
      puts "Client connected: #{client}"
    else
      begin
        client_command_with_args = socket.read_nonblock(1024)
        command_parts = client_command_with_args.split
        command = command_parts[0]
        args = command_parts[1..-1]

        if command == 'exit'
          socket.puts "Closing ..."
          clients.delete(socket)
          next
        end

        unless COMMANDS.include?(command)
          formatted_args = args.map { |arg| "`#{ arg }`," }.join(" ")
          socket.puts "(error) ERR unknown command `#{ command }`, with args beginning with: #{ formatted_args }"
          next
        end

        if command == "SET"
          @data_store[args[0]] = args[1]
          socket.puts 'OK'
        elsif command == "GET"
          socket.puts @data_store.fetch(args[0], "(nil)")
        end

      rescue IO::WaitReadable, Errno::EINTR
        next
      rescue EOFError, Errno::ECONNRESET
        socket.puts "Client disconnected: #{socket}"
        clients.delete(socket)
      end

    end

  end

end

