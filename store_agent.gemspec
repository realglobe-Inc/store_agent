# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'store_agent/version'

Gem::Specification.new do |spec|
  spec.name          = "store_agent"
  spec.version       = StoreAgent::VERSION
  spec.authors       = ["realglobe-Inc"]
  spec.email         = ["info@realglobe.jp"]
  spec.summary       = %q{TODO: Write a short summary. Required.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = "https://github.com/realglobe-Inc/store_agent"
  spec.licenses       = ["Apache License 2.0"]

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 2.0.0.247")

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1.0"
  spec.add_development_dependency "guard", "~> 2.6.1"
  spec.add_development_dependency "guard-rspec", "~> 4.3.1"
  spec.add_development_dependency "git", "~> 1.2.8"
  spec.add_development_dependency "rugged", "~> 0.21.0"
  spec.add_development_dependency "simplecov", "~> 0.9.1"
  spec.add_development_dependency "metric_fu", "~> 4.11.1"
  spec.add_dependency "oj"
end
