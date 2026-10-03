# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor/extensions'

module AsciidoctorCsl
  # BibliographyBlockMacro
  #
  # Provides the bibliography block macro. (bibliography::[select=cited, link-title=false])
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

    def process(parent, _target, attrs)
      case attrs['select']
      when nil, 'cited' then nil
      when 'all' then @render_all = true
      else
        logger.warn "bibliography: unknown value for select attribute: #{attrs['select']}"
      end

      block = create_block parent, :open, nil, { 'role' => 'bibliography' }
      block.set_attr 'link-title', attrs['link-title'] if attrs.key?('link-title')
      blocks << block
      block
    end
  end
end
