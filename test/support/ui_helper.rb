module UIHelper
  def within_queue_row(name, &block)
    row = find(".queues .queue", text: name)
    within row, &block
  end
end
