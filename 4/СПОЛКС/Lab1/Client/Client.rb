require "socket"


include Socket::Constants

#client = TCPSocket.open "#{address.strip}", 2000

print "Input ip address server: "
address = gets

client = Socket.new(AF_INET, SOCK_STREAM, 0)
sockaddr = Socket.pack_sockaddr_in(2000, address.strip!)

client.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 30)
client.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_KEEPCNT, true)
client.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_KEEPIDLE, true)
client.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_KEEPINTVL, true)

client.connect(sockaddr)

loop do
  begin
    puts "1. Time"
    puts "2. Echo"
    puts "3. Upload"
    puts "4. Download"
    puts "5. Disconnect"
    puts "6. Close server and disconnect"
    command = gets
    command.strip!
    client.puts command.to_i.to_s 2
    case command.to_i
    when 1
      start_time = Time.now
      line = client.gets
      line.strip!
      puts line
    when 2
      print "Input strintg "
      client.puts "ECHO #{line = gets}"
      puts "Answer: #{client.gets}"
    when 3
      print "Input file name: "
      file_name = gets
      file_name.strip!
      client.puts file_name
      unless File.exist?(file_name)
        puts "File don't exits!"
        client.puts 0
      else
        start_time = Time.now
        file = File.open file_name, "rb"
        client.puts file.size
        data = file.read
        client.puts data
        puts "Upload time: #{Time.now - start_time}"
        file.close
      end
    when 4
      print "Input file name: "
      file_name = gets
      file_name.strip!
      client.puts file_name
      check_size = client.gets
      check_size.strip!
      unless check_size.to_i == 0
        start_time = Time.now
        file = File.open file_name, "wb"
        while check_size.to_i > file.size
          data = client.gets
          file.write data
        end
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
    end
  rescue => err
    puts err
    puts "Connection error! Reconnect? (y)"
    ans = gets
    unless ans.strip! == "y"
      exit
    else
      redo
      #client.connect(sockaddr)
      #retry
    end
  end
end
