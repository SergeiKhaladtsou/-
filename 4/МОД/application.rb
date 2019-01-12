class Application

  attr_accessor :create, :wait, :delete, :queue, :work

  def initialize create_time, work_time
    @create = create_time
    @wait = 0
    @queue = 0
    @delete = 0
    @work = work_time
  end

end
