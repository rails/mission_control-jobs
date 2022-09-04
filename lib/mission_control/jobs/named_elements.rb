class MissionControl::Jobs::NamedElements
  include Enumerable

  delegate :[], to: :elements_by_name
  delegate :each, :last, to: :to_a

  def initialize
    @elements_by_name = HashWithIndifferentAccess.new
  end

  def []=(key, value)
    name_key = key.to_s.parameterize
    @elements_by_name[name_key] ||= MissionControl::Jobs::Application.new(name: name)
    @elements_by_name[name_key].add_servers(queue_adapters_by_name)
  end

  def add(name, queue_adapters_by_name = {})
    name_key = name.to_s.parameterize
    @elements_by_name[name_key] ||= MissionControl::Jobs::Application.new(name: name)
    @elements_by_name[name_key].add_servers(queue_adapters_by_name)
  end

  def to_a
    @elements_by_name.values
  end

  private
    attr_reader :elements_by_name
end
