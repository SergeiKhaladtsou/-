require_relative "application.rb"

L = 2.5             #Lambda
U = 3               #Mu
SIZE = 1000          #Number of applications

loop do
  puts "1 - FIFO"
  puts "2 - Min work time"
  puts "3 - Exit"
  com = gets
  com = com.strip.to_i
  @queue = Array.new
  @full_time = 0
  case com
  when 1
    item = 0
    while item < SIZE
      @new = (Math.log10(rand) / L).abs
      @full_time += @new
      @queue[item] = Application.new @full_time, @new
      item += 1
    end
    item = 0
    while item < SIZE
      @work = (Math.log10(rand) / U).abs
      if @queue[item].create < @queue[item - 1].delete
        @queue[item].delete = @queue[item - 1].delete + @work
        @queue[item].queue = @queue[item - 1].delete - @queue[item].create
      else
        @queue[item].delete = @queue[item].create + @work
      end
      item += 1
    end
    item = 0
    while item < SIZE
      j = item + 1
      puts item
      while j < SIZE and @queue[item].delete > @queue[j].create
        @queue[j].wait += 1
        j += 1
      end
      item += 1
    end
    sum = 0
    wait_app = 0
    @queue.each do |item|
      sum += item.queue
      wait_app += item.wait
    end
    print  `clear`
    puts "Lоч = #{wait_app / SIZE}"
    puts "Wоч = #{sum / SIZE * 2}"
    puts "Wc = #{(@queue[SIZE - 1].delete - @queue[0].create) / SIZE * 10}"
  when 2

  when 3
    exit
  end
end
