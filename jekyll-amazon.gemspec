# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll-amazon/version'

Gem::Specification.new do |spec|
  spec.name          = "jekyll-amazon"
  spec.version       = Jekyll::Amazon::VERSION
  spec.authors       = ["tokzk"]
  spec.email         = ["t@okzk.org"]

  spec.summary       = %q{Liquid tag for display Amazon associate links in Jekyll sites.}
  spec.homepage      = "https://github.com/tokzk/jekyll-amazon"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.license       = "MIT"

  spec.add_dependency "amazon-ecs", "~> 2.4.0"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "jekyll", ">= 3.0"
end
