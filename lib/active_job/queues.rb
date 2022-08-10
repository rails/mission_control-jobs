# An enumerable collection of queues that supports direct access to queues by name.
#
#   queue_1 = ApplicationJob::Queue.new("queue_1")
#   queue_2 = ApplicationJob::Queue.new("queue_2")
#   queues = ApplicationJob::Queues.new([queue_1, queue_2])
#
#   queues[:queue_1] #=> queue_1
#   queues[:queue_2] #=> queue_2
#   queues.to_a #=> [ queue_1, queue_2 ] # Enumerable
#
# See +ActiveJob::Queue+.
class ActiveJob::Queues
  include Enumerable

  delegate :each, to: :values
  delegate :values, to: :queues_by_name, private: true
  delegate :[], :size, :to_s, :inspect, to: :queues_by_name

  def initialize(queues)
    @queues_by_name = queues.index_by(&:name).with_indifferent_access
  end

  def to_h
    queues_by_name.dup
  end

  private
    attr_reader :queues_by_name
end
