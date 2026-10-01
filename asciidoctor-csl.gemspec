# frozen_string_literal: true

begin
  require_relative 'lib/asciidoctor-csl/version'
rescue LoadError
  require 'asciidoctor-csl/version'
end

Gem::Specification.new do |s|
  s.name = 'asciidoctor-csl'
  s.version = AsciidoctorCsl::VERSION
  s.authors = ['Niko Strijbol']
  s.email = ['niko@strijbol.be']
  s.homepage = 'https://github.com/niknetniko/asciidoctor-csl'
  s.summary = 'An Asciidoctor extension that adds CSL integration to AsciiDoc'
  s.license = 'EUPL-1.2'
  s.description = 'asciidoctor-csl is an Asciidoctor extension that adds CSL support for AsciiDoc documents.'
  s.required_ruby_version = '>= 3.2'
  s.files = Dir['lib/**/*'] + %w[LICENSE.txt README.adoc]
  s.add_dependency 'asciidoctor', '~> 2.0'
  s.add_dependency 'citeproc-ruby', '~> 2.1'
  s.add_dependency 'csl-styles', '~> 2.0'
  s.add_dependency 'logger', '~> 1.7'

  s.metadata['rubygems_mfa_required'] = 'true'
end
