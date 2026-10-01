require 'asciidoctor'
require 'asciidoctor/extensions'
require 'citeproc'

module AsciidoctorCsl
  # BibitemMacro
  #
  # The `bibitem:key1[]` macro.
  class BibitemMacro < ::Asciidoctor::Extensions::InlineMacroProcessor
    include ::Asciidoctor::Logging
    use_dsl

    named :bibitem

    attr_accessor :processor

    def process(parent, target, attributes)
      entry = processor&.render_entry(target)
      if entry.nil?
        logger.warn "bibitem: unknown reference: #{target}"
        return create_inline parent, :quoted, "[#{target}]"
      end

      create_inline parent, :quoted, entry, attributes: { 'subs' => :normal }
    end
  end
end
