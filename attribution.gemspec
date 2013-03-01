# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "attribution"
  gem.version       = "0.2.0"
  gem.authors       = ["Paul Barry"]
  gem.email         = ["mail@paulbarry.com"]
  gem.description   = %q{Add attributes to Ruby objects}
  gem.summary       = %q{Add attributes to Ruby objects}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "activesupport"
  gem.add_runtime_dependency "tzinfo"
end
