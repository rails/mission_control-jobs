class ActiveJob::Queue
  attr_reader :name

  def initialize(name)
    @name = name
  end
end
