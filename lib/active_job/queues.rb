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
  delegate :values, to: :queues_by_id, private: true
  delegate :size, :length, :to_s, :inspect, to: :queues_by_id

  def initialize(queues)
    @queues_by_id = queues.index_by(&:id).with_indifferent_access
  end

  def to_h
    queues_by_id.dup
  end

  def [](name)
    queues_by_id[name.to_s.parameterize]
  end

  private
    attr_reader :queues_by_id
end
