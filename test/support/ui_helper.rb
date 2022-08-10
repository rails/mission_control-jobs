module UIHelper
  def within_queue_row(name, &block)
    row = find(".queues .queue", text: name)
    within row, &block
  end

  def queue_elements
    all(".queues .queue")
  end

  def job_elements
    all(".jobs .job")
  end
end
