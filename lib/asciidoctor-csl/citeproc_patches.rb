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

        text = in_xref { render_layout(item, node) }
        text = "<<#{item.id},#{text}>>" unless text.empty?
        join [item.prefix, text, item.suffix].compact
      end

      private

      def in_xref
        format.in_xref = true
        yield
      ensure
        format.in_xref = false
      end
    end

    # Support for linking URLs in the title.
    module LinkTitles
      def render_bibliography(item, node)
        return super unless format.respond_to?(:link_titles) && format.link_titles

        target = link_target(item.data)
        return super unless target

        doi = item.data[:DOI]
        url = item.data[:URL]
        suppressed = item.data.suppressed.dup

        format.title_link = target
        # Blank DOI/URL so the style renders the entry as if it had neither:
        # groups around them collapse as for any missing variable.
        item.data[:DOI] = nil
        item.data[:URL] = nil

        result = super
        return result unless format.title_link

        # The style rendered no title: render the entry as usual.
        format.title_link = nil
        item.data[:DOI] = doi
        item.data[:URL] = url
        # Rendering suppresses variables used as substitutes; undo that too.
        item.data.suppressed.replace suppressed
        super
      ensure
        format.title_link = nil if format.respond_to?(:title_link=)
      end

      private

      def link_target(data)
        doi = data[:DOI].to_s.strip
        return doi.match?(%r{\Ahttps?://}i) ? doi : "https://doi.org/#{doi}" unless doi.empty?

        url = data[:URL].to_s.strip
        url unless url.empty?
      end
    end
  end
end

CiteProc::Item.prepend AsciidoctorCsl::CiteprocPatches::SeparateSuppression
CiteProc::Ruby::Renderer.prepend AsciidoctorCsl::CiteprocPatches::LinkCitations
CiteProc::Ruby::Renderer.prepend AsciidoctorCsl::CiteprocPatches::LinkTitles
