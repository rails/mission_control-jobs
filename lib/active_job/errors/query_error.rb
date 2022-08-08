module ActiveJob
  module Errors
    class QueryError < StandardError
      def initialize(jobs_relation)
        super "Can't fetch jobs for relation: #{jobs_relation}"
      end
    end
  end
end
