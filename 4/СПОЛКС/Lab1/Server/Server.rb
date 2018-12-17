require "socket"

SIZE_PACKETH = 1024

include Socket::Constants

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
          quantity = socket[0].gets
          last_packeth = check_size.to_i % SIZE_PACKETH
          quantity.to_i.times do
            file.write socket[0].read(SIZE_PACKETH)
          end
          file.write socket[0].read(last_packeth)
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
          socket[0].puts last_packeth = file.size % SIZE_PACKETH
          socket[0].puts quantity = file.size / SIZE_PACKETH
          quantity.times do
            socket[0].write file.read(SIZE_PACKETH)
          end
          socket[0].write file.read(last_packeth)
          file.close
        end
      when 5
        socket[0].close
        break
      when 6
        socket[0].close
        server.close
        exit
      when 7
        file_name = socket[0].gets
        last_packeth = socket[0].gets
        quantity = socket[0].gets
        file_name.strip!
        last_packeth.strip!
        quantity.strip!
        packeth = socket[0].gets
        packeth.strip!
        file = File.open file_name, "ab"
        quantity.to_i.times do |pack|
          next if pack < packeth.to_i
          data = socket[0].read(SIZE_PACKETH)
          file.write data
        end
        file.write socket[0].read(last_packeth.to_i)
        file.close
      when 8
        file_name = socket[0].gets
        file_name.strip!
        packeth = socket[0].gets
        packeth.strip!
        last_packeth = socket[0].gets
        last_packeth.strip!
        quantity = socket[0].gets
        quantity.strip!
        file = File.open file_name, "rb"
        quantity.to_i.times do |pack|
          data = file.read(SIZE_PACKETH)
          next if pack < packeth.to_i
          socket[0].puts data
        end
        socket[0].puts file.read(last_packeth.to_i)
      end
    end
  end
end
