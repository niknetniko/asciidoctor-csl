# frozen_string_literal: true

module AsciidoctorCsl
  # Render CSL directly to AsciiDoc.
  class Asciidoc < CiteProc::Ruby::Format
    include ::Asciidoctor::Logging

    PROTECTED_RX = /<<[^,>]+,|\{[\w-]+}|\b[a-z][\w-]*:\S*?\[[^\]]*\]|\[[^\]]*\](?=#)|\+\+\+.*?\+\+\+|\+[^+]+\+/
    PLACEHOLDER_RX = /\u0000(\d+)\u0000/
    URL_VARIABLES = %w[URL DOI].freeze

    # Whether rendered citations link to their bibliography entry.
    attr_accessor :link_citations

    # Whether bibliography titles link.
    attr_accessor :link_titles

    # The target for the next rendered title, set per entry by the renderer.
    attr_accessor :title_link

    # Whether we are rendering inside a citation's cross-reference, where links cannot nest.
    attr_accessor :in_xref

    def bibliography(bibliography, _locale = nil)
      bibliography.connector = "\n\n"
      bibliography
    end

    def apply_font_style
      case options[:'font-style']
      when 'italic', 'oblique'
        # AsciiDoc does not support oblique, so italicize it.
        output.replace "__#{output}__"
      when 'normal' then nil
      else
        logger.warn "csl: unsupported font-style '#{options[:'font-style']}'"
      end
    end

    def apply_font_variant
      case options[:'font-variant']
      when 'small-caps' then output.replace "[.small-caps]###{output}##"
      when 'normal' then nil
      else
        logger.warn "csl: unsupported font-variant '#{options[:'font-variant']}'"
      end
    end

    def apply_font_weight
      case options[:'font-weight']
      when 'bold' then output.replace "**#{output}**"
      when 'normal', 'light'
        # AsciiDoc does not support light font variant, so use normal.
        nil
      else
        logger.warn "csl: unsupported font-weight '#{options[:'font-weight']}'"
      end
    end

    def apply_text_decoration
      case options[:'text-decoration']
      when 'underline' then output.replace "[.underline]###{output}##"
      when 'none' then nil
      else
        logger.warn "csl: unsupported text-decoration '#{options[:'text-decoration']}'"
      end
    end

    def apply_vertical_align
      case options[:'vertical-align']
      when 'sup' then output.replace "^#{output.gsub(' ', '{nbsp}')}^"
      when 'sub' then output.replace "~#{output.gsub(' ', '{nbsp}')}~"
      when 'baseline' then nil
      else
        logger.warn "csl: unsupported vertical-align '#{options[:'vertical-align']}'"
      end
    end

    # Replace the AsciiDoc syntax by placeholders without letters, so we only transform actual text.
    def apply_text_case
      protected = []
      output.gsub!(PROTECTED_RX) do
        protected << Regexp.last_match(0)
        "\u0000#{protected.size - 1}\u0000"
      end
      super
    ensure
      output.gsub!(PLACEHOLDER_RX) { protected[Regexp.last_match(1).to_i] } if protected
    end

    # An affix that became part of a link is not added again.
    def prefix
      @prefix_in_link ? '' : super
    end

    protected

    # Escape URLs and DOIs before any formatting, so AsciiDoc does not parse them.
    def setup!
      super
      escape_url if node.is_a?(CSL::Style::Text) && URL_VARIABLES.include?(node.variable)
    end

    def cleanup!
      super
      @prefix_in_link = nil
    end

    def finalize_content!
      super

      return unless title_link && node.is_a?(CSL::Style::Text) && node.variable == 'title'

      output.replace "link:#{passthrough title_link}[#{output.gsub(']', '\]')}]"
      self.title_link = nil # link only the first rendered title
    end

    private

    # Link the value if it is a URL, or becomes one with its prefix (as in prefix="https://doi.org/");
    # a value that already is a URL ignores such a prefix. Anything else is passed through as text.
    def escape_url
      url = if url?(output) then output
            elsif url?(prefix + output) then prefix + output
            end
      @prefix_in_link = url && url?(prefix)

      text = passthrough(url || output)
      output.replace(url && !in_xref ? "link:#{text}[]" : text)
    end

    # Not `++text++`, which cannot contain `++`.
    def passthrough(text)
      "pass:c[#{text.gsub(']', '\]')}]"
    end

    def url?(text)
      text.match?(%r{\Ahttps?://}i)
    end
  end
end
