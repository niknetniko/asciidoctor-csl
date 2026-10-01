require 'asciidoctor'
require 'asciidoctor/extensions'

module AsciidoctorCsl
  class BibliographyBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
    include ::Asciidoctor::Logging

    use_dsl
    named :bibliography

    def blocks
      @blocks ||= []
    end

    def render_all?
      @render_all
    end

    def process(parent, target, attrs)
      case attrs['select']
      when nil, 'cited' then nil
      when 'all' then @render_all = true
      else
        logger.warn "bibliography: unknown value for select attribute: #{attrs['select']}"
      end

      block = create_block parent, :open, nil, { 'role' => 'bibliography' }
      blocks << block
      block
    end
  end
end
