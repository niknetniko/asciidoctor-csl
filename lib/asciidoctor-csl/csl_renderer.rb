module AsciidoctorCsl
  # Render CSL directly to AsciiDoc.
  class Asciidoc < CiteProc::Ruby::Format
    include ::Asciidoctor::Logging

    PROTECTED_RX = /\{[\w-]+}|\b[a-z][\w-]*:\S*?\[[^\]]*\]|\[[^\]]*\](?=#)|\+\+\+.*?\+\+\+|\+[^+]+\+/.freeze
    PLACEHOLDER_RX = /\u0000(\d+)\u0000/.freeze

    def bibliography(bibliography, locale = nil)
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
  end
end
