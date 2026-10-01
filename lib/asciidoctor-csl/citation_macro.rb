require 'asciidoctor'
require 'asciidoctor/extensions'
require 'citeproc'

module AsciidoctorCsl
  # CitationMacro
  #
  # The `cite:key1,key2[locator, label, prefix=..., suffix=...]` macro.
  class CitationMacro < ::Asciidoctor::Extensions::InlineMacroProcessor
    include ::Asciidoctor::Logging
    use_dsl

    named :cite
    name_positional_attributes 'locator', 'label'

    attr_accessor :csl

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
          logger.warn "cite: unknown locator label '#{label}', expected one of #{CiteProc::CitationItem.labels.join(', ')}"
        end
        items.last[:label] = label
      end

      items.last[:suffix] = ", #{attributes['suffix']}" if attributes['suffix']

      if csl.nil?
        logger.warn "cite: CSL style not found"
        return nil
      end

      text = csl.render(:citation, items)
      # Support footnote styles
      text = "footnote:[#{text.gsub(']', '\\]')}]" if csl.engine.style.info.citation_format == :note

      create_inline parent, :quoted, text,  attributes: { 'subs' => :normal }
    end
  end
end
