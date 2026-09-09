class FailingWithCustomErrorJob < ApplicationJob
  class CustomError < StandardError; end

  def perform
    raise CustomError
  end
end
