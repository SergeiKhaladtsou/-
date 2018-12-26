require "socket"

SIZE_PACKETH = 1024

include Socket::Constants

def resume_download(file_name, pack, socket)
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
    server.send pack.to_s, 0, sender
    quantity.times do |packeth|
      data = file.read(SIZE_PACKETH)
      next if pack.to_i < packeth
      puts packeth
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
end

def resume_upload(file_name, pack, socket)
  server_command = 8
  server.send server_command.to_s, 0 ,sender
  server.send file_name, 0, sender
  server.send pack.to_s, 0, sender
  file = File.open file_name, "ab"
  last_packeth, sender = server.recvfrom(SIZE_PACKETH)
  last_packeth.strip!
  quantity, sender = server.recvfrom(SIZE_PACKETH)
  quantity.strip!
  ans = Array.new quantity + 1
  while ans.include?(nil)
    message = ""
    ans.each_index do |item|
      next if ans[item] != nil
      begin
        message = "#{message}-#{item}"
      rescue
        ans.each_index do |index|
          if ans[index] == nil
            report = File.new "Error_report", "wb"
            report.write "3-#{file_name}-#{index}-"
            report.close
            exit
          else
            file.write ans[index]
          end
        end
      end
    end
    server.send message, 0, sender
    data, sender = server.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
    while data != "y"
      index = data.split("-")[0].to_i
      ans[index] = data.sub("#{index}-", "")
      data, sender = server.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
    end
  end
  server.send "y", 0, sender
  ans.each_index do |index|
    next if index < pack
    file.write ans[index]
  end
  file.close
end

print "Input your ip address: "
address = gets

server = Socket.new(AF_INET, SOCK_DGRAM, 0)
server.bind(Addrinfo.udp(address.strip!, "2000"))

secs = Integer(3)
usecs = Integer(0)
optval = [secs, usecs].pack("1_2")
server.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval)

p server.connect_address
ok, sender = server.recvfrom(SIZE_PACKETH)

loop do
  unless File.exist?("Error_report")
      command, sender = server.recvfrom(SIZE_PACKETH)
      puts "command = #{command.to_i 2}"
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
      ans = Array.new quantity + 1
      while ans.include?(nil)
        message = ""
        ans.each_index do |item|
          next if ans[item] != nil
          message = "#{message}-#{item}"
        end
        server.send message, 0, sender
        begin
          data, sender = server.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
        rescue
          ans.each_index do |index|
            if ans[index] == nil
              report = File.new "Error_report", "wb"
              report.write "3-#{file_name}-#{index}-"
              report.close
              exit
            else
              file.write ans[index]
            end
          end
        end
        while data != "y"
          index = data.split("-")[0].to_i
          ans[index] = data.sub("#{index}-", "")
          begin
            data, sender = server.recvfrom(SIZE_PACKETH + quantity.to_s.size + 1)
          rescue
            ans.each_index do |index|
              if ans[index] == nil
                report = File.new "Error_report", "wb"
                report.write "3-#{file_name}-#{index}-"
                report.close
                exit
              else
                file.write ans[index]
              end
            end
          end
        end
      end
      server.send "y", 0, sender
      ans.each_index do |index|
        file.write ans[index]
      end
      file.close
    when 4
      file_name, sender = server.recvfrom(SIZE_PACKETH)
      file_name.strip!
      unless File.exist?(file_name)
        puts "File don't exist!"
        server.send 0, 0
      else
        file = File.open file_name, "rb"
        last_packeth = file.size % SIZE_PACKETH
        quantity = file.size / SIZE_PACKETH
        server.send quantity.to_s, 0, sender
        server.send last_packeth.to_s, 0, sender
        data, sender = server.recvfrom(65507)
        while data != "y" and data.size != 1
          data = data.split("-")
          file = File.open file_name, "rb"
          (quantity + 1).times do |index|
            message = file.read(SIZE_PACKETH)
            next if !data.include?(index.to_s)
            server.send "#{index}-#{message}", 0, sender
          end
          sleep(0.1)
          server.send "y", 0, sender
          data, sender = server.recvfrom(65507)
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
