# A collection of elements offering a Hash-like access based on
# their +id+.
class MissionControl::Jobs::IdentifiedElements
  include Enumerable

  delegate :[], to: :elements
  delegate :each, :last, :length, to: :to_a

  def initialize
    @elements = HashWithIndifferentAccess.new
  end

  def <<(item)
    @elements[item.id] = item
  end

  def to_a
    @elements.values
  end

  private
    attr_reader :elements
end
