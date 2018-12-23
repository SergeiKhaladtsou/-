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
    unless File.exist?(file_name)
      puts "File don't exist!"
      client.send 0, 0
    else
      client.send file_name, 0
      file = File.open file_name, "rb"
      last_packeth = file.size % SIZE_PACKETH
      quantity = file.size / SIZE_PACKETH
      client.send quantity.to_s, 0
      client.send last_packeth.to_s, 0
      time = Time.now
      quantity.times do |packeth|
        puts packeth
        data = file.read(SIZE_PACKETH)
        client.send "#{packeth}-#{data}", 0
        ans = "n"
        ans, sender = client.recvfrom(SIZE_PACKETH)
        while ans == "n"
          puts packeth
          client.send "#{packeth}-#{data}", 0
          ans, sender = client.recvfrom(SIZE_PACKETH)
        end
      end
      puts quantity
      data = file.read(last_packeth)
      file.close
      client.send "#{quantity}-#{data}", 0
      ans = "n"
      ans, sender = client.recvfrom(SIZE_PACKETH)
      while ans == "n"
        puts quantity
        puts ans
        client.send "#{quantity}-#{data}", 0
        ans, sender = client.recvfrom(SIZE_PACKETH)
      end
      puts "Upload time: #{Time.now - time}"
    end
  when 4
    puts "File list:"
    puts `ls`
    puts
    printf "Input file name: "
    file_name = gets
    file_name.strip!
    client.send file_name, 0
    file = File.new file_name, "wb"
    quantity, sender = client.recvfrom(SIZE_PACKETH)
    last_packeth, sender = client.recvfrom(SIZE_PACKETH)
    quantity = quantity.strip.to_i
    last_packeth = last_packeth.strip.to_i
    quantity.times do |packeth|
      puts packeth
      data, sender = client.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
      while data.split("-")[0].to_i != packeth
        puts data.split("-")[0]
        client.send "n", 0
        data, sender = client.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
      end
      client.send "y", 0
      file.write data.sub("#{data.split("-")[0]}-", "")
    end
    puts quantity
    data, sender = client.recvfrom(last_packeth + quantity.to_s.size + 1)
    while data.split("-")[0].to_i != quantity
      puts data.split("-")[0]
      client.send "n", 0
      data, sender = client.recvfrom(last_packeth + quantity.to_s.size + 1)
    end
    client.send "y", 0
    file.write data.sub("#{data.split("-")[0]}-", "")
    file.close
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
