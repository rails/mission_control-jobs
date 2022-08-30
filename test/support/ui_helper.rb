module UIHelper
  def within_queue_row(text, &block)
    row = find(".queues .queue", text: text)
    within row, &block
  end

  def queue_row_elements
    all(".queues .queue")
  end

  def within_job_row(text, &block)
    row = find(".jobs .job", text: text)
    within row, &block
  end

  def job_row_elements
    all(".jobs .job")
  end
end
