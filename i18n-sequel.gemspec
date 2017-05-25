# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'i18n/sequel/version'

Gem::Specification.new do |s|
  s.name         = "i18n-sequel"
  s.version      = I18n::Sequel::VERSION
  s.authors      = ["Jim Garvin"]
  s.email        = "jim@thegarvin.com"
  s.homepage     = "http://github.com/coderifous/i18n-sequel"
  s.summary      = "I18n Sequel backend"
  s.description  = "I18n Sequel backend. Allows to store translations in a database using Sequel, e.g. for providing a web-interface for managing translations."
  s.license      = 'MIT'

  s.files        = Dir.glob("{ci,lib,test}/**/**") + %w(MIT-LICENSE README.textile Rakefile)
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  s.add_dependency 'i18n', '>= 0.5.0'
  s.add_development_dependency 'bundler'
end
