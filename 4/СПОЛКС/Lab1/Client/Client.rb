require "socket"
include Socket::Constants

SIZE_PACKETH = 1024

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
    printf "Input file name: "
    file_name = gets
    file_name.strip!
    client.puts file_name
    unless File.exist?(file_name)
      puts "File don't exits!"
      client.puts 0
    else
      file = File.open file_name, "rb"
      client.puts file.size
      last_packeth = file.size % SIZE_PACKETH
      client.puts quantity = file.size / SIZE_PACKETH
      start_time = Time.now
      quantity.times do |packeth|
        data = file.read(SIZE_PACKETH)
        client.write data
      end
      client.write file.read(last_packeth)
      file.close
      puts "Upload time: #{Time.now - start_time}"
    end
  when 4
    print "Input file name: "
    file_name = gets
    file_name.strip!
    client.puts file_name
    check_size = client.gets
    check_size.strip!
    last_packeth = client.gets
    last_packeth.strip!
    quantity = client.gets
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
    file_name = client.gets
    last_packeth = client.gets
    quantity = client.gets
    file_name.strip!
    last_packeth.strip!
    quantity.strip!
    packeth = client.gets
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
    file_name = client.gets
    file_name.strip!
    packeth = client.gets
    packeth.strip!
    last_packeth = client.gets
    last_packeth.strip!
    quantity = client.gets
    quantity.strip!
    file = File.open file_name, "rb"
    quantity.to_i.times do |pack|
      data = file.read(SIZE_PACKETH)
      next if pack < packeth.to_i
      client.puts data
    end
    client.puts file.read(last_packeth.to_i)
  end
end
