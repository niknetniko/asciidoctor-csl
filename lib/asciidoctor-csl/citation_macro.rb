# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'citeproc'

module AsciidoctorCsl
  # CitationMacro
  #
  # The `cite:key1,key2[locator, label, prefix=..., suffix=..., link=false]` macro.
  class CitationMacro < ::Asciidoctor::Extensions::InlineMacroProcessor
    include ::Asciidoctor::Logging

    use_dsl

    named :cite
    name_positional_attributes 'locator', 'label'

    attr_accessor :csl

    # Whether the document has a bibliography with entries to link to.
    attr_writer :bibliography

    def process(parent, target, attributes)
      keys = target.split(',').map(&:strip)
      unknown, known = keys.partition { |key| csl.nil? || !csl.key?(key) }

      logger.warn "cite: unknown references: #{unknown.join(', ')}" unless unknown.empty?
      return create_inline parent, :quoted, "[#{keys.join(', ')}]" if known.empty?

      items = known.map { |key| { id: key } }
      items.first[:prefix] = "#{attributes['prefix']} " if attributes['prefix']

      if attributes['locator']
        items.last[:locator] = attributes['locator']
        label = attributes['label'] || 'page'
        unless CiteProc::CitationItem.labels.include?(label.to_sym)
          allowed = CiteProc::CitationItem.labels.join(', ')
          logger.warn "cite: unknown locator label '#{label}', expected one of #{allowed}"
        end
        items.last[:label] = label
      end

      items.last[:suffix] = ", #{attributes['suffix']}" if attributes['suffix']

      if csl.nil?
        logger.warn 'cite: CSL style not found'
        return nil
      end

      csl.engine.format.link_citations = @bibliography && attributes['link'] != 'false'
      text = csl.render(:citation, items)
      return create_footnote parent, text if csl.engine.style.info.citation_format == :note

      create_inline parent, :quoted, text, attributes: { 'subs' => :normal }
    end

    private

    # Create the footnote like the footnote macro does, so the citation is not escaped to fit in `footnote:[]`.
    def create_footnote(parent, text)
      document = parent.document
      content = parent.apply_subs text
      index = document.counter 'footnote-number'
      document.register :footnotes, ::Asciidoctor::Document::Footnote.new(index, nil, content)
      create_inline parent, :footnote, content, attributes: { 'index' => index }
    end
  end
end
