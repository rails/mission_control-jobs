module MissionControl::Jobs::IdentifiedByName
  extend ActiveSupport::Concern

  included do
    attr_reader :name
    alias to_s name
  end

  def initialize(name:)
    @name = name.to_s
  end

  def id
    name.parameterize
  end

  alias to_param id
end
