require_relative 'lib/twitch/version'

Gem::Specification.new do |spec|
  spec.name          = "twitchrb"
  spec.version       = Twitch::VERSION
  spec.authors       = [ "Dean Perry" ]
  spec.email         = [ "dean@voupe.com" ]

  spec.summary       = "A Ruby library for interacting with the Twitch Helix API"
  spec.homepage      = "https://github.com/d34ndev/twitchrb"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.3")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/d34ndev/twitchrb/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/d34ndev/twitchrb/issues"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "faraday", ">= 2.14.3", "< 3"
end
