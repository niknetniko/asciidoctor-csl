#
# Manage the current set of citations, the document settings,
# and main operations.
#

require 'citeproc/ruby'
require 'csl/styles'
require 'json'
require 'yaml'
require 'date'

require_relative 'citeproc_patches'
require_relative 'csl_renderer'


module AsciidoctorCsl

  # Class used through utility method to hold data about citations for
  # current document, and run the different steps to add the citations
  # and bibliography
  class Processor
    include ::Asciidoctor::Logging

    # AsciiDoc curved quotes, so the converter decides how quotes look,
    # consistent with the rest of the document.
    QUOTE_TERMS = {
      'open-quote' => '"`',
      'close-quote' => '`"',
      'open-inner-quote' => "'`",
      'close-inner-quote' => "`'"
    }.freeze

    attr_reader :citeproc

    def initialize(
      bibliography_file,
      links = false,
      style = 'ieee',
      locale = 'en'
    )
      raise "File '#{bibliography_file}' is not found" unless FileTest.file? bibliography_file

      @links = links
      @style = style
      @locale = locale

      # Citations in the order they appear in the document
      @citations = []

      @citeproc = new_citeproc
      @bibliography = read_bibliography_file(bibliography_file).to_h { |item| [item['id'].to_s, item] }
    end

    # Register the appearance of a citation key.
    def add_citations(keys)
      @citations.concat keys.map(&:strip)
    end

    def render_entry(key)
      return nil unless @bibliography.key?(key)

      entries.render(:bibliography, id: key).first
    end

    # Finalize citation macro processing and build internal citation list.
    #
    # As this function being called, processor will clean up the list of
    # citation keys to form a correct ordered citation list.
    def finalize_macro_processing(render_all: false)
      @citations = @citations.uniq

      keys = render_all ? @citations | @bibliography.keys : @citations
      @citeproc.import keys.filter_map { |key| @bibliography[key] }

      @rendered = @citeproc.bibliography

      @rendered.ids.each_with_index do |id, i|
        @citeproc[id][:'citation-number'] = i + 1
      end
      nil
    end

    def build_bibliography_list
      @rendered.ids.zip(@rendered.references).flat_map do |id, reference|
        [@links ? "[[#{id}]]#{reference}" : reference, '']
      end
    end

    private

    def read_bibliography_file(bibliography_file)
      case File.extname(bibliography_file).downcase
      when '.json' then JSON.parse(File.read(bibliography_file))
      when '.yml', '.yaml' then YAML.safe_load(File.read(bibliography_file), permitted_classes: [Date])
      else
        raise "Bibliography file must have .json, .yml, or .yaml extension, got #{File.extname(bibliography_file)}"
      end
    end

    def entries
      @entries ||= new_citeproc.tap { |citeproc| citeproc.import @bibliography.values }
    end

    def new_citeproc
      citeproc = CiteProc::Processor.new style: @style, format: :asciidoc, locale: @locale
      use_asciidoc_quotes citeproc
      citeproc
    end

    # Override the quote handling by inserting dynamic AsciiDoc quotes.
    # That way, AsciiDoc handles the quotes, and it is consistent with the rest of the document.
    def use_asciidoc_quotes(processor)
      locale = processor.engine.renderer.locale
      QUOTE_TERMS.each do |name, value|
        term = locale.terms.lookup(name)
        term ? term.set(value) : locale.store(name, value)
      end
    end
  end
end
