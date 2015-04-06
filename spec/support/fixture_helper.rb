require "yaml"

module FixtureHelper
  def fixture_load(name)
    YAML.load_file(fixture_file_path(name))
  end

  def fixture_file_path(name)
    File.expand_path("../../fixtures/#{name}.yml", __FILE__)
  end
end
