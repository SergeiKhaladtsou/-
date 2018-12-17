require "socket"
include Socket::Constants

SIZE_PACKETH = 1024

def resume_upload(file_name, packeth, client)
  server_command = 7
  unless File.exist?(file_name)
    puts "File don't exist"
  else
    file = File.open file_name, "rb"
    client.send server_command.to_s, 0
    client.send file_name, 0
    last_packeth = file.size % SIZE_PACKETH
    client.send last_packeth.to_s, 0
    quantity = file.size / SIZE_PACKETH
    client.send quantity.to_s, 0
    client.send packeth, 0
    quantity.times do |pack|
      data = file.read(SIZE_PACKETH)
      next if pack < packeth
      begin
        client.send data, 0
      rescue
        report = File.new "Error_report", "rb"
        report.write 3
        report.write file_name
        report.write packeth
        exit
        #retry
      end
    end
    client.send file.read(last_packeth), 0
    file.close
  end
end

def resume_download(file_name, packeth, client)
  server_command = 8
  client.send server_command.to_s, 0
  client.send file_name, 0
  client.send packeth, 0
  file = File.open file_name, "ab"
  last_packeth = file.size % SIZE_PACKETH
  client.send last_packeth.to_s, 0
  quantity = file.size / SIZE_PACKETH
  client.send quantity.to_s, 0
  quantity.times do |pack|
    next if pack < packeth
    begin
      data = client.read(SIZE_PACKETH)
    rescue
      report = File.new "Error_report", "rb"
      report.write 4
      report.write file_name
      report.write packeth
      exit
      #retry
    end
    file.write data
  end
  data = client.read(last_packeth)
  file.write data
  file.close
end

print "Input ip address server: "
address = gets

client = Socket.new(AF_INET, SOCK_DGRAM, 0)
sockaddr = Socket.pack_sockaddr_in(2000, address.strip!)

client.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 30)

client.connect(sockaddr)

loop do
  unless File.exist?("Error_report")
    puts "1. Time"
    puts "2. Echo"
    puts "3. Upload"
    puts "4. Download"
    puts "5. Disconnect"
    puts "6. Close server and disconnect"
    command = gets
    command.strip!
  else
    puts "Resume ..."
    report = File.open "Error_report", "rb"
    command = report.readline
    command.strip!
    file_name = report.readline
    file_name.strip!
    packeth = report.readline
    packeth.strip!
    report.close
    File.delete("Error_report")
    if command.to_i == 3
      resume_upload(file_name, packeth, client)
    else
      resume_download(file_name, packeth, client)
    end
  end
  command = command.to_i.to_s 2
  client.send(command, 0)
  puts command.to_i 2
  case command.to_i 2
  when 1
    start_time = Time.now
    line, sender = client.recvfrom(SIZE_PACKETH)
    line.strip!
    puts line
  when 2
    print "Input strintg "
    line = gets
    client.send "ECHO #{line}", 0
    data, sender = client.recvfrom(SIZE_PACKETH)
    puts "Answer: #{data}"
  when 3
    printf "Input file name: "
    file_name = gets
    file_name.strip!
    client.send file_name, 0
    unless File.exist?(file_name)
      puts "File don't exits!"
      client.send "0", 0
    else
      file = File.open file_name, "rb"
      client.send file.size.to_s, 0
      last_packeth = file.size % SIZE_PACKETH
      quantity = file.size / SIZE_PACKETH
      client.send quantity.to_s, 0
      start_time = Time.now
      quantity.times do |packeth|
        data = file.read(SIZE_PACKETH)
        begin
          client.send data.to_s, 0
        rescue
          report = File.new "Error_report", "rb"
          report.write 3
          report.write file_name
          report.write packeth
          retry
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
        begin
          data = client.read(SIZE_PACKETH)
        rescue
          report = File.new "Error_report", "rb"
          report.write 4
          report.write file_name
          report.write packeth
          retry
        end
        file.write data
      end
      data = client.read(last_packeth.to_i)
      file.write data
      file.close
      puts "Upload time: #{Time.now - start_time}"
    else
      puts "File don't exist!"
    end
  when 5
    client.close
    exit
  when 6
    client.close
    exit
  end
end
