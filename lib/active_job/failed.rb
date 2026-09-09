module ActiveJob::Failed
  extend ActiveSupport::Concern

  included do
    attr_accessor :last_execution_error, :failed_at
  end

  def error_class_name
    last_execution_error&.error_class
  end
end
