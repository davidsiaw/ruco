# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruco/version'

Gem::Specification.new do |spec|
  spec.name          = "ruco"
  spec.version       = Ruco::VERSION
  spec.authors       = ["David Siaw"]
  spec.email         = ["davidsiaw@gmail.com"]

  spec.summary       = "Boilerplate generator for Coco/R"
  spec.description   = ""
  spec.homepage      = "https://github.com/davidsiaw/ruco"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ["ruco"]
  spec.require_paths = ["lib"]

  spec.extensions = %w[ext/cocor]

  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rake-compiler"
  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "rspec"
end
