class AutoRetryingJob < ApplicationJob
  class RandomError < StandardError; end

  retry_on RandomError, attempts: 3, wait: 0.1.seconds

  def perform
    raise RandomError
  end
end
