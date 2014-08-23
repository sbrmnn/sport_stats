# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sport_stats/version'

Gem::Specification.new do |spec|
  spec.name          = "sport_stats"
  spec.version       = SportStats::VERSION
  spec.authors       = ["gth824c@gmail.com"]
  spec.email         = ["gth824c@gmail.com"]
  spec.summary       = %q{This package prints out sports stats with a give csv input}
  spec.description   = %q{TBA}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "activesupport"
  spec.add_dependency "fastest-csv"
end
