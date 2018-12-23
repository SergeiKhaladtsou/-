require "socket"

SIZE_PACKETH = 1024

include Socket::Constants

def resume_download(file_name, packeth, socket)
  server_command = 7
  unless File.exist?(file_name)
    puts "File don't exist"
  else
    file = File.open file_name, "rb"
    server.send server_command.to_s, 0, sender
    server.send file_name, 0, sender
    last_packeth = file.size % SIZE_PACKETH
    server.send last_packeth.to_s, 0, sender
    quantity = file.size / SIZE_PACKETH
    server.send quantity.to_s, 0, sender
    server.send packeth.to_s, 0, sender
    quantity.times do |pack|
      data = file.read(SIZE_PACKETH)
      next if pack < packeth.to_i
      begin
        socket.write data
      rescue
        report = File.new "Error_report", "wb"
        report.write "3-"
        report.write "#{file_name}-"
        report.write "#{pack}-"
        exit
      end
    end
    socket.write file.read(last_packeth)
    file.close
  end
end

def resume_upload(file_name, packeth, socket)
  server_command = 8
  server.send server_command.to_s, 0,sender
  server.send file_name, 0, sender
  server.send packeth.to_s, 0, sender
  file = File.open file_name, "ab"
  last_packeth, sender = server.recvfrom(SIZE_PACKETH)
  last_packeth.strip!
  quantity, sender = server.recvfrom(SIZE_PACKETH)
  quantity.strip!
  quantity.to_i.times do |pack|
    next if pack < packeth.to_i
    begin
      data = socket.read(SIZE_PACKETH)
    rescue
      report = File.new "Error_report", "wb"
      report.write "4-"
      report.write "#{file_name}-"
      report.write "#{pack}-"
      exit
    end
    file.write data
  end
  file.write socket.read(last_packeth.to_i)
  file.close
end

print "Input your ip address: "
address = gets

server = Socket.new(AF_INET, SOCK_DGRAM, 0)
server.bind(Addrinfo.udp(address.strip!, "2000"))

p server.connect_address
ok, sender = server.recvfrom(SIZE_PACKETH)

loop do
  unless File.exist?("Error_report")
      command, sender = server.recvfrom(SIZE_PACKETH)
  else
    puts "Resume ..."
    report = File.open "Error_report", "rb"
    data = report.read
    report.close
    comand, file_name, packeth = data.split("-")
    comand.strip!
    file_name.strip!
    packeth.strip!
    File.delete("Error_report")
    if comand.to_i == 3
      resume_upload(file_name, packeth, server)
    else
      resume_download(file_name, packeth, server)
    end
  end
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
      file = File.new file_name, "wb"
      quantity, sender = server.recvfrom(SIZE_PACKETH)
      last_packeth, sender = server.recvfrom(SIZE_PACKETH)
      quantity = quantity.strip.to_i
      last_packeth = last_packeth.strip.to_i
      quantity.times do |packeth|
        puts packeth
        begin
          data, sender = server.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
        rescue
          report = File.new "Error_report", "wb"
          report.write "3-#{file_name}-#{packeth}"
          exit
        end
        while data.split("-")[0].to_i != packeth
          puts data.split("-")[0]
          server.send "n", 0, sender
          begin
            data, sender = server.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
          rescue
            report = File.new "Error_report", "wb"
            report.write "3-#{file_name}-#{packeth}"
            exit
          end
        end
        server.send "y", 0, sender
        file.write data.sub("#{data.split("-")[0]}-", "")
      end
      puts quantity
      data, sender = server.recvfrom(last_packeth + quantity.to_s.size + 1)
      while data.split("-")[0].to_i != quantity
        puts data.split("-")[0]
        server.send "n", 0, sender
        data, sender = server.recvfrom(last_packeth + quantity.to_s.size + 1)
      end
      server.send "y", 0, sender
      file.write data.sub("#{data.split("-")[0]}-", "")
      file.close
    when 4
      file_name, sender = server.recvfrom(SIZE_PACKETH)
      file_name.strip!
      unless File.exist?(file_name)
        puts "File don't exist!"
        server.send 0, 0, sender
      else
        file = File.open file_name, "rb"
        last_packeth = file.size % SIZE_PACKETH
        quantity = file.size / SIZE_PACKETH
        server.send quantity.to_s, 0, sender
        server.send last_packeth.to_s, 0, sender
        quantity.times do |packeth|
          puts packeth
          data = file.read(SIZE_PACKETH)
          begin
            server.send "#{packeth}-#{data}", 0, sender
          rescue
            report = File.new "Error_report", "wb"
            report.write "4-#{file_name}-#{packeth}"
            exit
          end
          ans = "n"
          ans, sender = server.recvfrom(SIZE_PACKETH)
          while ans == "n"
            puts packeth
            server.send "#{packeth}-#{data}", 0, sender
            ans, sender = server.recvfrom(SIZE_PACKETH)
          end
        end
        puts quantity
        data = file.read(last_packeth)
        file.close
        begin
          server.send "#{packeth}-#{data}", 0, sender
        rescue
          report = File.new "Error_report", "wb"
          report.write "4-#{file_name}-#{packeth}"
          exit
        end
        ans = "n"
        ans, sender = server.recvfrom(SIZE_PACKETH)
        while ans == "n"
          puts quantity
          puts ans
          server.send "#{quantity}-#{data}", 0, sender
          ans, sender = server.recvfrom(SIZE_PACKETH)
        end
      end
    when 5
      server.close
      break
    when 6
      server.close
      server.close
      exit
    end
  end
end
