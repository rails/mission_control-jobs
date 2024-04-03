require_relative "lib/mission_control/jobs/version"

Gem::Specification.new do |spec|
  spec.name = "mission_control-jobs"
  spec.version = MissionControl::Jobs::VERSION
  spec.authors = [ "Jorge Manrubia" ]
  spec.email = [ "jorge@hey.com" ]
  spec.homepage = "https://github.com/basecamp/mission_control-jobs"
  spec.summary = "Operational controls for Active Job"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/basecamp/mission_control-jobs"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", "~> 7.1"
  spec.add_dependency "importmap-rails"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "stimulus-rails"

  spec.add_development_dependency "resque"
  spec.add_development_dependency "solid_queue"
  spec.add_development_dependency "selenium-webdriver"
  spec.add_development_dependency "resque-pause"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "redis", "~> 4.0.0"
  spec.add_development_dependency "redis-namespace"
  spec.add_development_dependency "rubocop", "~> 1.52.0"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails-omakase"
  spec.add_development_dependency "sprockets-rails"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "puma"
end
