module JobsHelper
  extend ActiveSupport::Concern

  def assert_job_proxy(expected_class, job)
    assert_instance_of ActiveJob::JobProxy, job
    assert_equal expected_class.to_s, job.class_name
  end

  def within_job_server(app_id, server: nil, &block)
    application = MissionControl::Jobs.applications[app_id]
    server = (server && application.servers[server]) || application.servers.first
    raise "No jobs server for application with id #{app_id} (#{server})" if server.nil?
    server.activating &block
  end
end
