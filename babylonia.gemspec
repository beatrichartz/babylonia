# -*- encoding: utf-8 -*-
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'babylonia/version'

Gem::Specification.new do |s|
  s.name              = "babylonia"
  s.version           = Babylonia::VERSION
  s.authors           = ["Beat Richartz"]
  s.description       = "Let your users translate their content into their languages without additional tables or columns in your tables"
  s.email             = "attr_accessor@gmail.com"
  s.licenses          = ["MIT"]
  s.require_paths     = ["lib"]
  s.summary           = "Let there be languages!"
  
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- spec/*`.split("\n")
  s.require_paths     = ["lib"]
  
  s.add_dependency              "i18n", ">= 0.5.0"
  s.add_development_dependency  "bundler", ">= 1.0.0"
end

