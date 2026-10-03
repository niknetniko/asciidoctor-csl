# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'citeproc'

module AsciidoctorCsl
  # BibitemMacro
  #
  # The `bibitem:key1[link-title=false]` macro.
  class BibitemMacro < ::Asciidoctor::Extensions::InlineMacroProcessor
    include ::Asciidoctor::Logging

    use_dsl

    named :bibitem

    attr_accessor :processor

    def process(parent, target, attributes)
      options = attributes.key?('link-title') ? { link_titles: attributes['link-title'] != 'false' } : {}
      entry = processor&.render_entry(target, **options)
      if entry.nil?
        logger.warn "bibitem: unknown reference: #{target}"
        return create_inline parent, :quoted, "[#{target}]"
      end

      create_inline parent, :quoted, entry, attributes: { 'subs' => :normal }
    end
  end
end
