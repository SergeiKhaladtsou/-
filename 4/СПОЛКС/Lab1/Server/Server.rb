require "socket"

SIZE_PACKETH = 1024

include Socket::Constants

print "Input your ip address: "
address = gets

server = Socket.new(AF_INET, SOCK_STREAM, 0)
server.bind(Addrinfo.tcp(address.strip!, "2000"))

server.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 30)

p server.connect_address

loop do
  server.listen(5)
  socket = server.accept
  p socket
  loop do
    unless File.exist?("Error_report")
      command = socket[0].gets
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
        resume_upload(file_name, packeth, socket[0])
      else
        resume_download(file_name, packeth, socket[0])
      end
    end
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
          quantity.to_i.times do |packeth|
            data = socket[0].read(SIZE_PACKETH)
            begin
              file.write data
            rescue
              report = File.new "Error_report", "rb"
              report.write 3
              report.write file_name
              report.write packeth
              exit
            end
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
      end
    end
  end
end

def resume_upload(file_name, packeth, socket)
  server_command = 7
  unless File.exist?(file_name)
    puts "File don't exist"
  else
    file = File.open file_name, "rb"
    socket.puts server_command
    socket.puts file_name
    last_packeth = file.size % SIZE_PACKETH
    socket.puts last_packeth
    quantity = file.size / SIZE_PACKETH
    socket.puts quantity
    socket.puts packeth
    quantity.times do |pack|
      data = file.read(SIZE_PACKETH)
      next if pack < packeth
      begin
        socket.write data
      rescue
        report = File.new "Error_report", "rb"
        report.write 3
        report.write file_name
        report.write packeth
        exit
        #retry
      end
    end
    socket.write file.read(last_packeth)
    file.close
  end
end

def resume_download(file_name, packeth, socket)
  server_command = 8
  socket.puts server_command
  socket.puts file_name
  socket.puts packeth
  file = File.open file_name, "ab"
  last_packeth = file.size % SIZE_PACKETH
  socket.puts last_packeth
  quantity = file.size / SIZE_PACKETH
  socket.puts quantity
  quantity.times do |pack|
    next if pack < packeth
    begin
      data = socket.read(SIZE_PACKETH)
    rescue
      report = File.new "Error_report", "rb"
      report.write 4
      report.write file_name
      report.write packeth
      exit
    end
    file.write data
  end
  file.write socket.read(last_packeth)
  file.close
end
