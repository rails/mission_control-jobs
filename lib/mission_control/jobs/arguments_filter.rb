# Replaces argument values with [FILTERED] for any keys that match a filter.
class MissionControl::Jobs::ArgumentsFilter
  FILTERED = "[FILTERED]"

  def initialize(filter)
    @filter = filter
  end

  def apply_to(arguments)
    case arguments
    when Array
      arguments.map { |a| apply_to(a) }
    when Hash
      arguments.map do |k, v|
        [ k, filter.include?(k.to_s) ? FILTERED : v ]
      end.to_h
    else
      arguments
    end
  end

  private
    attr_reader :filter
end
