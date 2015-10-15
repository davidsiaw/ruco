# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruco/version'

Gem::Specification.new do |spec|
  spec.name          = "ruco-cpp"
  spec.version       = Ruco::VERSION
  spec.authors       = ["David Siaw"]
  spec.email         = ["davidsiaw@gmail.com"]

  spec.summary       = "Boilerplate generator for Coco/R"
  spec.description   = "Generates an LL(1) parser for a grammar described in a .ruco file"
  spec.homepage      = "https://github.com/davidsiaw/ruco"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = Dir['lib/**/*.rb'] + 
                        Dir['bin/*'] + 
                        Dir['ext/**/*'] + 
                        Dir['data/**/*'] +
                        ["Rakefile"]
  spec.bindir        = "bin"
  spec.executables   = ["ruco"]
  spec.require_paths = ["lib"]

  spec.extensions = %w[ext/cocor/extconf.rb]

  spec.add_dependency "activesupport", "~> 4.2"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rake-compiler", "~> 0.9.5"
  spec.add_development_dependency "rspec", "~> 3.3"
end
