module UIHelper
  def hover_app_selector(and_click:)
    find(".application-selector").hover
    find(".application-selector .navbar-item", text: and_click).click
  end

  def click_on_server_selector(name)
    within ".server-selector" do
      click_on name
    end
  end

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
