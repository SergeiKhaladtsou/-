require "socket"
include Socket::Constants

SIZE_PACKETH = 1024

print "Input ip address server: "
address = gets

client = Socket.new(AF_INET, SOCK_DGRAM, 0)
sockaddr = Socket.pack_sockaddr_in(2000, address.strip!)

client.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 30)

client.connect(sockaddr)
client.send "1", 0
puts "Do you want resume ? (1/0)"
ans = gets
loop do
  command = if ans.to_i == 1
              command, sender = client.recvfrom(SIZE_PACKETH)
              puts command
              ans = 0
              command
            else
              puts "1. Time"
              puts "2. Echo"
              puts "3. Upload"
              puts "4. Download"
              puts "5. Disconnect"
              puts "6. Close server and disconnect"
              command = gets
              command = command.strip.to_i.to_s 2
              client.send command, 0
              command
            end
  command.strip!
  case command.to_i 2
  when 1
    start_time = Time.now
    line, sender = client.recvfrom(SIZE_PACKETH)
    line.strip!
    puts line
  when 2
    print "Input strintg "
    client.send "ECHO #{line = gets}", 0
    line, sender = client.recvfrom(SIZE_PACKETH)
    puts "Answer: #{line}"
  when 3
    puts "File list:"
    puts `ls`
    puts
    printf "Input file name: "
    file_name = gets
    file_name.strip!
    client.send file_name, 0
    unless File.exist?(file_name)
      puts "File don't exits!"
      client.send 0, 0
    else
      file = File.open file_name, "rb"
      client.send file.size.to_s, 0
      last_packeth = file.size % SIZE_PACKETH
      quantity = file.size / SIZE_PACKETH
      client.send quantity.to_s, 0
      start_time = Time.now
      quantity.times do |packeth|
        puts packeth
        data = file.read(SIZE_PACKETH)
        client.send data, 0
        asc, sender = client.recvfrom(SIZE_PACKETH)
        while asc != data
          client.send data, 0
          asc, sender = client.recvfrom(SIZE_PACKETH)
        else
          client.send "yes"
        end
      end
      client.send file.read(last_packeth), 0
      file.close
      puts "Upload time: #{Time.now - start_time}"
    end
  when 4
    print "Input file name: "
    file_name = gets
    file_name.strip!
    client.send file_name, 0
    check_size, sender = client.recvfrom(SIZE_PACKETH)
    check_size.strip!
    last_packeth, sender = client.recvfrom(SIZE_PACKETH)
    last_packeth.strip!
    quantity, sender = client.recvfrom(SIZE_PACKETH)
    quantity.strip!
    unless check_size.to_i == 0
      start_time = Time.now
      file = File.open file_name, "wb"
      quantity.to_i.times do |packeth|
        file.write client.read(SIZE_PACKETH)
      end
      file.write client.read(last_packeth.to_i)
      file.close
      puts "Upload time: #{Time.now - start_time}"
    else
      puts "File don't exist!"
    end
  when 5
    client.close
    break
  when 6
    client.close
    break
  when 7
    file_name, sender = client.recvfrom(SIZE_PACKETH)
    last_packeth, sender = client.recvfrom(SIZE_PACKETH)
    quantity, sender = client.recvfrom(SIZE_PACKETH)
    file_name.strip!
    last_packeth.strip!
    quantity.strip!
    packeth, sender = client.recvfrom(SIZE_PACKETH)
    packeth.strip!
    file = File.open file_name, "ab"
    quantity.to_i.times do |pack|
      next if pack < packeth.to_i
      data = client.read(SIZE_PACKETH)
      file.write data
    end
    file.write client.read(last_packeth.to_i)
    file.close
  when 8
    file_name, sender = client.recvfrom(SIZE_PACKETH)
    file_name.strip!
    packeth, sender = client.recvfrom(SIZE_PACKETH)
    packeth.strip!
    file = File.open file_name, "rb"
    last_packeth = file.size % SIZE_PACKETH
    client.send last_packeth.to_s, 0
    quantity = file.size / SIZE_PACKETH
    client.send quantity.to_s, 0
    quantity.to_i.times do |pack|
      data = file.read(SIZE_PACKETH)
      next if pack < packeth.to_i
      puts pack
      client.send data, 0
    end
    client.send file.read(last_packeth), 0
    file.close
  end
end
