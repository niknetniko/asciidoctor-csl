module AsciidoctorCsl
  class CitationProcessor < ::Asciidoctor::Extensions::TreeProcessor
    include ::Asciidoctor::Logging

    def process(document)
      csl_file = (document.attr 'csl-file').to_s
      csl_style = ((document.attr 'csl-style') || 'ieee').to_s
      csl_lang = (document.attr('csl-lang') || document.attr('lang') || 'en').to_s

      return if csl_file.empty?

      # The cite macros
      cite = document.extensions.inline_macros.map(&:instance).find { |m| m.name == :cite }
      bibitem = document.extensions.inline_macros.map(&:instance).find { |m| m.name == :bibitem }

      path_to_csl = document.normalize_system_path csl_file, document.base_dir
      processor = Processor.new path_to_csl, true, csl_style, csl_lang

      # Collect all cited keys, in appearance order.
      document.find_by(traverse_documents: true) { |b| prose?(b) }.each do |block|
        raw_texts(block).each do |text|
          text.scan(cite.regexp) do
            match = Regexp.last_match
            processor.add_citations match[1].split(',') unless match[0].start_with?('\\')
          end
        end
      end

      bibliography = document.extensions.find_block_macro_extension(:bibliography).instance
      # Make processor finalize macro processing as required.
      processor.finalize_macro_processing render_all: bibliography.render_all?
      # Provide the Citeproc renderer
      cite.csl = processor.citeproc
      bibitem.processor = processor

      bibliography.blocks.each { |block| parse_content block, processor.build_bibliography_list }

      nil
    end

    private

    def prose?(block)
      block.content_model == :simple || block.context == :list_item ||
        block.context == :table_cell || block.title?
    end

    def raw_texts(block)
      texts = []
      texts << block.instance_variable_get(:@title) if block.title?
      if block.context == :list_item || block.context == :table_cell
        texts << block.instance_variable_get(:@text)
      elsif block.content_model == :simple
        texts.concat block.lines
      end
      texts.compact
    end
  end
end
