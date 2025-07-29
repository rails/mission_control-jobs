class ActiveJob::JobArgumentFilter
  FILTERED = "[FILTERED]"

  class << self
    def filter_arguments(arguments)
      arguments.each do |argument|
        if argument.is_a?(Hash)
          filter_argument_hash(argument)
        end
      end
    end

    def filter_argument_hash(argument)
      return argument if MissionControl::Jobs.filter_arguments.blank?

      argument.each do |key, value|
        if MissionControl::Jobs.filter_arguments.include?(key.to_s)
          argument[key] = FILTERED
        end
      end
    end
  end
end
