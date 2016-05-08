$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "nano-service/version"

Gem::Specification.new do |s|
  s.name        = 'nano-service'
  s.version     = NanoService::VERSION
  s.licenses    = ['MIT']
  s.authors     = ['Dave Riess']
  s.email       = ['dave@wundercapital.com']
  s.homepage    = 'https://github.com/wunderteam/nano-service'
  s.summary     = 'A thin module wrapper for helping enforce service boundaries'
  s.description = 'A thin module wrapper for helping enforce service boundaries'

  s.required_ruby_version = '>= 2.2.0'
  s.add_dependency 'activerecord',    ">= 3.0.0"
  s.add_dependency 'activesupport',   ">= 3.0.0"
  s.add_dependency 'globalid'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
end
