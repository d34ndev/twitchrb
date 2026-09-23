require_relative 'lib/twitch/version'

Gem::Specification.new do |spec|
  spec.name          = "twitchrb"
  spec.version       = Twitch::VERSION
  spec.authors       = [ "Dean Perry" ]
  spec.email         = [ "dean@deanpcmad.com" ]

  spec.summary       = "A Ruby library for interacting with the Twitch Helix API"
  spec.homepage      = "https://github.com/d34ndev/twitchrb"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.3")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/d34ndev/twitchrb/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/d34ndev/twitchrb/issues"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = [ "lib" ]

  spec.add_dependency "faraday", ">= 2.14.3", "< 3"
  spec.add_dependency "ostruct", "~> 0.6.0"
end
