class FailingJob < ApplicationJob
  def perform
    raise "This always fails!"
  end
end
