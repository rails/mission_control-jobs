class FailingJob < ApplicationJob
  def perform(value = "This always fails!", error = RuntimeError)
    raise error, value
  end
end
