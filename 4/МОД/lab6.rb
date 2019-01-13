require_relative "application.rb"

L = 2.5             #Lambda
U = 3               #Mu
SIZE = 1000        #Number of applications

def min(oh)
  min_index = 0
  oh.each_index do |index|
    min_index = index if oh[index].destroy < oh[min_index].destroy
  end
  min_index
end

def index(oh, queue)
  ind = 0
  queue.each_index do |index|
    ind = index if queue[index] == oh
  end
  ind
end

def max(queue)
  max = queue[0].delete
  queue.each_index do |index|
    max = queue[index].delete if queue[index].delete > max
  end
  max
end

loop do
  puts "1 - New"
  puts "2 - FIFO"
  puts "3 - Min work time"
  puts "4 - Exit"
  com = gets
  com = com.strip.to_i
  case com
  when 1
    @queue = Array.new
    @full_time = 0
    item = 0
    while item < SIZE
      @new = (Math.log10(rand) / L).abs
      @full_time += @new
      @queue[item] = Application.new @full_time
      item += 1
    end
    item = 0
    while item < SIZE
      @queue[item - 1].destroy = (Math.log10(rand) / U).abs
      item += 1
    end
  when 2
    item = 0
    while item < SIZE
      if @queue[item].create < @queue[item - 1].delete
        @queue[item].delete = @queue[item - 1].delete + @queue[item].destroy
        @queue[item].queue = @queue[item - 1].delete - @queue[item].create
      else
        @queue[item].delete = @queue[item].create + @queue[item].destroy
      end
      item += 1
    end
    item = 0
    while item < SIZE
      j = item + 1
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
    puts "Lоч = #{wait_app / SIZE}"
    puts "Wоч = #{(sum / SIZE * 200).to_i.to_f / 100}"
    puts "Wc = #{((@queue[SIZE - 1].delete - @queue[0].create) / SIZE * 1000).to_i.to_f / 100}"
  when 3
    @queue.each do |item|
      item.queue = 0
      item.delete = 0
      item.wait = 0
    end
    sum_loh = 0
    n_loh = 0
    sum_woh = 0
    sum_wc = 0
    w = 0
    index = 0
    oh = Array.new
    s = @queue[index].create
    e = s + @queue[index].destroy
    @queue[index].delete = e
    index += 1
    while index < SIZE
      if @queue[index].create < e
        oh << @queue[index]
      elsif oh.size == 0 and @queue[index].create >= e
        delay = @queue[index].create - e
        s = @queue[index].create
        e = s + @queue[index].destroy
        @queue[index].delete = e
      elsif @queue[index].create >= e
        if @queue[index].create == e
          oh << @queue[index]
          w = 1
        end
        min_index = min(oh)
        s = e
        e = e + oh[min_index].destroy
        ind = index(oh[min_index], @queue)
        @queue[ind].delete = e
        @queue[ind].queue = e - @queue[ind].create
        oh.delete_at(min_index)
        if w == 1
          oh << @queue[index]
          w = 0
        end
      end

      delay = 0
      sum_loh += oh.size
      n_loh += 1 if oh.size > 0
      index += 1
    end
    while oh.size > 0
      s = e
      min_index = min(oh)
      e = e + oh[min_index].destroy
      ind = index(oh[min_index], @queue)
      @queue[ind].delete = e
      @queue[ind].queue = e - @queue[ind].create
      oh.delete_at(min_index)
      sum_loh += oh.size
      n_loh += 1
    end
    @queue.each_index do |index|
      sum_woh += @queue[index].queue
      sum_wc += (@queue[index].delete - @queue[index].create).abs
    end
    sum_wc = max(@queue)
    puts "Lоч = #{sum_loh / n_loh}"
    puts "Wоч = #{(sum_woh / SIZE * 200).to_i.to_f / 100}"
    puts "Wc = #{(sum_wc / SIZE * 1000).to_i.to_f / 100}"
  when 4
    exit
  when 5
    print  `clear`
  end
end
