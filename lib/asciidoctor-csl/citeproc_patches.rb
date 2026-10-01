# frozen_string_literal: true

require 'citeproc'
require 'citeproc/ruby'

module AsciidoctorCsl
  module CiteprocPatches
    # Leaks suppressed variables into later renders.
    module SeparateSuppression
      def initialize_copy(other)
        super
        @suppressed = nil
      end
    end

    # Wrap each cited item in a cross-reference to its bibliography entry,
    # leaving the prefix, suffix and delimiters outside the link.
    module LinkCitations
      def render_single_citation(item, node)
        return super unless format.respond_to?(:link_citations) && format.link_citations

        item.suppress! 'author' if item.suppress_author?

        text = render_layout(item, node)
        text = "<<#{item.id},#{text}>>" unless text.empty?
        join [item.prefix, text, item.suffix].compact
      end
    end
  end
end

CiteProc::Item.prepend AsciidoctorCsl::CiteprocPatches::SeparateSuppression
CiteProc::Ruby::Renderer.prepend AsciidoctorCsl::CiteprocPatches::LinkCitations
