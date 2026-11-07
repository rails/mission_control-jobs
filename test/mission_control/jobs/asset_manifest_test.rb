require "test_helper"

class MissionControl::Jobs::AssetManifestTest < ActiveSupport::TestCase
  # Sprockets raises on directives pointing at missing directories, but only
  # Sprockets hosts read the manifest, so nothing else in the suite would notice.
  test "the manifest only links directories that exist" do
    manifest = MissionControl::Jobs::Engine.root.join("app/assets/config/mission_control_jobs_manifest.js")

    directories = manifest.read.scan(/link_directory (\S+)/).flatten
    assert_not_empty directories

    directories.each do |directory|
      assert manifest.dirname.join(directory).directory?, "#{directory} is linked in the manifest but doesn't exist"
    end
  end
end
