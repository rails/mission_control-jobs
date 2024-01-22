class WithPaginationFailingJob < FailingJob
  self.default_page_size = 2
end
