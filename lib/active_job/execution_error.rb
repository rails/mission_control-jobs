# Information about a given error when executing a job.
#
# It's attached to failed jobs in +#last_execution_error+.
ActiveJob::ExecutionError = Struct.new(:error_class, :message, :backtrace, keyword_init: true) do
  def to_s
    "ERROR #{error_class}: #{message}\n#{backtrace&.collect { |line| "\t#{line}" }&.join("\n")}"
  end
end
