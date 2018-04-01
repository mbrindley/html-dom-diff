
require File.expand_path('../lib/html-diff/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'html-diff'
  s.version = HTMLDiff::VERSION
  s.homepage = 'https://github.com/derfred/html-diff'
  s.licenses = ['MIT']

  s.authors = ["Frederik Fix"]
  s.email   = ["ich@derfred.com"]

  s.files = `git ls-files README.md LICENSE lib`.split
  s.test_files = `git ls-files specs`.split

  s.add_development_dependency 'rspec'

  s.summary = 'Diff between HTML documents'
  s.description = <<-EOT
Given two closely related HTML documents find a useful diff
EOT
end