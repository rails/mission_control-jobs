# A container to register applications
class MissionControl::Jobs::Applications
  include Enumerable

  delegate :[], to: :applications_by_name
  delegate :each, :last, to: :to_a

  def initialize
    @applications_by_name = HashWithIndifferentAccess.new
  end

  def add(name, queue_adapters_by_name = {})
    @applications_by_name[name] ||= MissionControl::Jobs::Application.new(name: name)
    @applications_by_name[name].add_servers(queue_adapters_by_name)
  end

  def to_a
    @applications_by_name.values
  end

  private
    attr_reader :applications_by_name
end
