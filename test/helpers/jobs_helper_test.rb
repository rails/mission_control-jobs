require "test_helper"

class MissionControl::Jobs::JobsHelperTest < ActionView::TestCase
  class JobWithRegularHashArguments < ApplicationJob
    def perform(value, options)
    end
  end

  class JobWithKeywordArgument < ApplicationJob
    def perform(value, value_kwarg:)
    end
  end

  class JobWithMultipleTypeArguments < ApplicationJob
    def perform(value, options = {}, **kwargs)
    end
  end

  setup do
    @post = Post.create!(title: "test")
    @datetime = Time.parse("2024-10-08 12:30:00 UTC")
  end

  test "render job arguments" do
    assert_rendered_as \
      "10, {datetime: 2024-10-08 12:30:00 UTC}",
      JobWithRegularHashArguments, 10, datetime: @datetime

    assert_rendered_as \
      "2024-10-08 12:30:00 UTC, {number: 10, string: hola, class: ApplicationJob}",
      JobWithRegularHashArguments, @datetime, number: 10, string: "hola", class: ApplicationJob

    assert_rendered_as \
      "#{@post.to_gid}, {array: [1, 2, 3]}",
      JobWithRegularHashArguments, @post, array: [ 1, 2, 3 ]

    assert_rendered_as \
      "[1, 2, 3], {post: #{@post.to_gid}}",
      JobWithRegularHashArguments, [ 1, 2, 3 ], post: @post

    assert_rendered_as \
      "{nested: {post: gid://dummy/Post/1}}, {post: gid://dummy/Post/1}",
      JobWithRegularHashArguments, { nested: { post: @post } }, post: @post

    assert_rendered_as \
      "gid://dummy/Post/1, {nested: {post: gid://dummy/Post/1, datetime: 2024-10-08 12:30:00 UTC}}",
      JobWithRegularHashArguments, @post, nested: { post: @post, datetime: @datetime }

    assert_rendered_as \
      "[1, 2, 3], {value_kwarg: #{@post.to_gid}}",
      JobWithKeywordArgument, [ 1, 2, 3 ], value_kwarg: @post

    assert_rendered_as \
      "ApplicationJob, {value_kwarg: {nested: gid://dummy/Post/1}}",
      JobWithKeywordArgument, ApplicationJob, value_kwarg: { nested: @post }

    assert_rendered_as \
      "hola, {options: {post: gid://dummy/Post/1}, array: [1, 2, 3]}",
      JobWithMultipleTypeArguments, "hola", options: { post: @post }, array: [ 1, 2, 3 ]

    assert_rendered_as \
      "ApplicationJob, {}, {datetime: 2024-10-08 12:30:00 UTC}",
      JobWithMultipleTypeArguments, ApplicationJob, {}, datetime: @datetime

    assert_rendered_as \
      "[2024-10-08 12:30:00 UTC, gid://dummy/Post/1, ApplicationJob, 1, 2, 3, [1, 2, 3], {nested: here}]",
      JobWithMultipleTypeArguments, [ @datetime, @post, ApplicationJob, 1, 2, 3, [ 1, 2, 3 ], { nested: :here } ]
  end

  private
    def assert_rendered_as(result, job_class, *arguments)
      job = enqueue_job job_class, *arguments
      assert_equal result, job_arguments(job)
    end

    def enqueue_job(klass, *arguments)
      job = klass.perform_later(*arguments)
      ActiveJob.jobs.pending.where(queue_name: job.queue_name).find_by_id(job.job_id)
    end
end
