require 'minitest/autorun'
require 'tmpdir'
require 'tempfile'
require 'asciidoctor'
require 'asciidoctor-csl/extensions'

module AsciidoctorCslTestHelper
  FIXTURES_DIR = File.expand_path('fixtures', __dir__)

  def convert(source, attributes = {})
    logger = Asciidoctor::MemoryLogger.new
    previous = Asciidoctor::LoggerManager.logger
    Asciidoctor::LoggerManager.logger = logger
    html = Asciidoctor.convert source,
                               safe: :safe,
                               standalone: false,
                               base_dir: FIXTURES_DIR,
                               attributes: attributes
    [html, logger.messages.map { |message| message[:message].to_s }]
  ensure
    Asciidoctor::LoggerManager.logger = previous
  end

  def paragraphs(html)
    html.scan(%r{<p>(.*?)</p>}m).flatten
  end

  def bibliography_entries(html)
    bibliography = html[%r{<div class="openblock bibliography">.*}m] || ''
    paragraphs(bibliography).map { |entry| entry.sub(%r{\A<a id="[^"]*"></a>}, '') }
  end

  def bibliography_ids(html)
    bibliography = html[%r{<div class="openblock bibliography">.*}m] || ''
    bibliography.scan(%r{<p><a id="([^"]*)"></a>}).flatten
  end

  def csl(style = 'apa', **attributes)
    { 'csl-file' => 'references.json', 'csl-style' => style }.merge(attributes.transform_keys { |key| key.to_s.tr('_', '-') })
  end
end
