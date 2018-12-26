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
ansv = gets
loop do
  command = if ansv.to_i == 1
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
              puts "command = #{command}"
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
      client.send 0
    else
      client.send file_name, 0
      file = File.open file_name, "rb"
      last_packeth = file.size % SIZE_PACKETH
      quantity = file.size / SIZE_PACKETH
      client.send quantity.to_s, 0
      client.send last_packeth.to_s, 0
      time = Time.now
      data, sender = client.recvfrom(65507)
      while data != "y" and data.size != 1
        data = data.split("-")
        file = File.open file_name, "rb"
        (quantity + 1).times do |index|
          message = file.read(SIZE_PACKETH)
          next if !data.include?(index.to_s)
          client.send "#{index}-#{message}", 0
        end
        sleep(0.1)
        client.send "y", 0
        data, sender = client.recvfrom(65507)
      end
      puts "Upload time: #{Time.now - time}"
    end
  when 4
    printf "Input file name: "
    file_name = gets
    file_name.strip!
    client.send file_name, 0
    file = File.new file_name, "wb"
    quantity, sender = client.recvfrom(SIZE_PACKETH)
    last_packeth, sender = client.recvfrom(SIZE_PACKETH)
    quantity = quantity.strip.to_i
    last_packeth = last_packeth.strip.to_i
    ans = Array.new quantity + 1
    time = Time.now
    while ans.include?(nil)
      message = ""
      ans.each_index do |item|
        next if ans[item] != nil
        message = "#{message}-#{item}"
      end
      client.send message, 0
      data, sender = client.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
      while data != "y"
        index = data.split("-")[0].to_i
        ans[index] = data.sub("#{index}-", "")
        data, sender = client.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
      end
    end
    puts "Upload time: #{Time.now - time}"
    client.send "y", 0
    ans.each_index do |index|
      file.write ans[index]
    end
    file.close
    puts "After write file: #{Time.now - time}"
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
    data, sender = client.recvfrom(65507)
    while data != "y" and data.size != 1
      data = data.split("-")
      file = File.open file_name, "rb"
      (quantity + 1).times do |index|
        message = file.read(SIZE_PACKETH)
        next if !data.include?(index.to_s)
        client.send "#{index}-#{message}", 0
      end
      sleep(0.1)
      client.send "y", 0
      data, sender = client.recvfrom(65507)
    end
    client.send file.read(last_packeth), 0
    file.close
  end
end
