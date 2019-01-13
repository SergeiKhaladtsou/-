class Application

  attr_accessor :create, :wait, :delete, :queue, :destroy

  def initialize create_time
    @create = create_time #время создания
    @wait = 0             #максимальное место в очереди
    @queue = 0            #время в очереди
    @delete = 0           #время удаления
    @destroy = 0          #время обработки
  end

end
