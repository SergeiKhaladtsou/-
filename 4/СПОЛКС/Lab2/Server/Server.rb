require "socket"

SIZE_PACKETH = 1024

include Socket::Constants

print "Input your ip address: "
address = gets

server = Socket.new(AF_INET, SOCK_DGRAM, 0)
server.bind(Addrinfo.udp(address.strip!, "2000"))

server.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 30)

p server.connect_address

loop do
  command, sender = server.recvfrom(SIZE_PACKETH)
  if command
    case command.to_i 2
    when 1
      puts Time.now
      server.send "Server time #{Time.now}", 0, sender
    when 2
      line, sender = server.recvfrom(SIZE_PACKETH)
      puts line.strip!
      server.send line.delete("ECHO "), 0, sender
    when 3
      file_name, sender = server.recvfrom(SIZE_PACKETH)
      file_name.strip!
      check_size, sender = server.recvfrom(SIZE_PACKETH)
      check_size.strip!
      unless check_size.to_i == 0
        file = File.open file_name, "wb"
        quantity, sender = server.recvfrom(SIZE_PACKETH)
        last_packeth = check_size.to_i % SIZE_PACKETH
        quantity.to_i.times do
          data = server.read(SIZE_PACKETH)
          file.write data
        end
        data = server.read(last_packeth)
        file.write data
        file.close
      end
    when 4
      file_name, sender = server.recvfrom(SIZE_PACKETH)
      file_name.strip!
      unless File.exist?(file_name)
        puts "File don't exits!"
        server.send "0", 0, sender
      else
        file = File.open file_name, "rb"
        server.send file.size.to_s, 0, sender
        last_packeth = file.size % SIZE_PACKETH, 0, sender
        server.send last_packeth.to_s, 0, sender
        quantity = file.size / SIZE_PACKETH
        server.send quantity.to_s , 0, sender
        quantity.times do
          server.send file.read(SIZE_PACKETH), 0, sender
        end
        server.send file.read(last_packeth), 0, sender
        file.close
      end
    when 6
      server.close
      exit
    when 7
      file_name, sender = server.recvfrom(SIZE_PACKETH)
      last_packeth, sender = server.recvfrom(SIZE_PACKETH)
      quantity, sender = server.recvfrom(SIZE_PACKETH)
      file_name.strip!
      last_packeth.strip!
      quantity.strip!
      packeth, sender = server.recvfrom(SIZE_PACKETH)
      packeth.strip!
      file = File.open file_name, "ab"
      quantity.to_i.times do |pack|
        next if pack < packeth.to_i
        data = server.read(SIZE_PACKETH)
        file.write data
      end
      data  = server.read(last_packeth.to_i)
      file.write data
      file.close
    when 8
      file_name, sender = server.recvfrom(SIZE_PACKETH)
      file_name.strip!
      packeth, sender = server.recvfrom(SIZE_PACKETH)
      packeth.strip!
      last_packeth, sender = server.recvfrom(SIZE_PACKETH)
      last_packeth.strip!
      quantity, sender = server.recvfrom(SIZE_PACKETH)
      quantity.strip!
      file = File.open file_name, "rb"
      quantity.to_i.times do |pack|
        data = file.read(SIZE_PACKETH)
        next if pack < packeth.to_i
        server.send data, 0, sender
      end
      server.send file.read(last_packeth.to_i), 0, sender
    end
  end
end
