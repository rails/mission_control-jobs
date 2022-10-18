class FailingPostJob < ApplicationJob
  def perform(post, published_at, author: "Jorge", price: 0.0)
    raise "This always fails! Post: #{post.inspect}"
  end
end
