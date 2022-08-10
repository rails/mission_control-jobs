class FailingJob < ApplicationJob
  def perform(value = nil)
    raise "This always fails!"
  end
end
