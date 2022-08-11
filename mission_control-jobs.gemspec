require_relative "lib/mission_control/jobs/version"

Gem::Specification.new do |spec|
  spec.name = "mission_control-jobs"
  spec.version = MissionControl::Jobs::VERSION
  spec.authors = [ "Jorge Manrubia" ]
  spec.email = [ "jorge@hey.com" ]
  spec.homepage = "https://github.com/basecamp/mission_control-jobs"
  spec.summary = "Operational controls for Active Job"
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "http://mygemserver.com"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/basecamp/mission_control-jobs"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.3.1"
  spec.add_dependency 'importmap-rails'
  spec.add_dependency 'turbo-rails'
  spec.add_dependency 'stimulus-rails'

  spec.add_development_dependency "resque"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency "resque-pause"
  spec.add_development_dependency "redis", "~> 4.0.0"
  spec.add_development_dependency "redis-namespace"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
end
