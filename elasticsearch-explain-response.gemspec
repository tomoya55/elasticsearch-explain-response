# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "elasticsearch-explain-response"
  spec.version       = "0.2.1"
  spec.authors       = ["Tomoya Hirano"]
  spec.email         = ["hiranotomoya@gmail.com"]
  spec.summary       = %q{Parser for Elasticserach Explain response}
  spec.description   = %q{Parser for Elasticserach Explain response}
  spec.homepage      = "http://github.com/tomoya55/elasticsearch-explain-response"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "elasticsearch", "~> 1.0.0"
  spec.add_development_dependency "ansi"
end
