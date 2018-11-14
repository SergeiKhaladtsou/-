require "socket"


include Socket::Constants

#socket = TCPServer.open "#{address.strip!}", 2000

print "Input your ip address: "
address = gets

server = Socket.new(AF_INET, SOCK_STREAM, 0)
server.bind(Addrinfo.tcp(address.strip!, "2000"))

server.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 30)
server.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_KEEPCNT, true)
server.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_KEEPIDLE, true)
server.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_KEEPINTVL, true)

p server.connect_address

loop do
  server.listen(5)
  socket = server.accept
  p socket
  begin
    loop do
      command = socket[0].gets
      if command
        case command.to_i 2
        when 1
          puts Time.now
          socket[0].puts "Server time #{Time.now}"
        when 2
          line = socket[0].gets
          puts line.strip!
          socket[0].puts line.delete("ECHO ")
        when 3
          file_name = socket[0].gets
          file_name.strip!
          check_size = socket[0].gets
          check_size.strip!
          unless check_size.to_i == 0
            file = File.open file_name, "wb"
            while check_size.to_i > file.size
              data = socket[0].gets
              file.write data
            end
            file.close
          end
        when 4
          file_name = socket[0].gets
          file_name.strip!
          unless File.exist?(file_name)
            puts "File don't exits!"
            socket.puts 0
          else
            file = File.open file_name, "rb"
            socket[0].puts file.size
            data = file.read
            socket[0].puts data
            file.close
          end
        when 5
          socket[0].close
          break
        when 6
          socket[0].close
          server.close
          exit
        end
      end
    end
  rescue => err
    puts err
    puts "Connection error! Reconnect? (y)"
    ans = gets
    unless ans.strip! == "y"
      exit
    else
      redo
      #socket[0].close
      #server.listen(5)
      #socket = server.accept
      #p socket
      #retry
    end
  end
end
