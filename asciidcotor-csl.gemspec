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
  s.license = 'TBD'
  s.description = 'asciidoctor-csl is an Asciidocotor extension that adds CSL support for AsciiDoc documents.'
  s.required_ruby_version = '>= 2.4.0'
  s.files = Dir['lib/**/*'] + ['LICENSE.txt', 'README.adoc']
  s.add_runtime_dependency 'asciidoctor', '~> 2.0'
  s.add_runtime_dependency 'logger'
  s.add_runtime_dependency 'citeproc-ruby', '~> 2.1'
  s.add_runtime_dependency 'csl-styles', '~> 2.0'

  s.add_development_dependency 'minitest', '~> 6.0'
  s.add_development_dependency 'rake', '~> 13.4'
end
