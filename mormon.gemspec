# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mormon/version'

Gem::Specification.new do |gem|
  gem.name          = "mormon"
  gem.version       = Mormon::VERSION
  gem.authors       = ["Geronimo Diaz", "John Kølle"]
  gem.email         = ["geronimod@gmail.com", "john.kolle@gmail.com"]
  gem.description   = %q{ OSM Router }
  gem.summary       = %q{ OSM Routing with some extra features: reset tiles cache, random routes and distance optimizer for routes with several stops. It's based on Pyroute library. }
  gem.homepage      = "https://github.com/geronimod/mormon"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.rubyforge_project = "mormon"
  
  gem.add_dependency "nokogiri"
  gem.add_development_dependency "rspec"
  #gem.add_development_dependency "debugger"
end
