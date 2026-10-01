# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor/extensions'

require_relative 'processor'
require_relative 'citation_processor'
require_relative 'citation_macro'
require_relative 'bibitem_macro'
require_relative 'bibliography_macro'

# Register the extensions to asciidoctor
Asciidoctor::Extensions.register do
  block_macro AsciidoctorCsl::BibliographyBlockMacro
  inline_macro AsciidoctorCsl::CitationMacro
  inline_macro AsciidoctorCsl::BibitemMacro
  treeprocessor AsciidoctorCsl::CitationProcessor
end
