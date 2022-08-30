class ApplicationJob < ActiveJob::Base
  class_attribute :invocations

  before_perform do |job|
    job.class.invocations ||= []
    job.class.invocations << Invocation.new(arguments)
  end

  Invocation = Struct.new(:arguments)
end
