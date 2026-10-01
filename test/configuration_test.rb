require_relative 'test_helper'

class ConfigurationTest < Minitest::Test
  include AsciidoctorCslTestHelper

  def test_style_defaults_to_ieee
    html, = convert 'cite:smith2020[]', 'csl-file' => 'references.json'
    assert_equal ['[1]'], paragraphs(html)
  end

  def test_attributes_in_document_header
    source = <<~ADOC
      = Document
      :csl-file: references.json
      :csl-style: apa

      cite:smith2020[]
    ADOC
    html, = convert source
    assert_equal ['(Smith, 2020)'], paragraphs(html)
  end

  def test_csl_lang_sets_the_locale
    html, = convert 'cite:smith2020[12]', csl(csl_lang: 'de')
    assert_equal ['(Smith, 2020, S. 12)'], paragraphs(html)
  end

  def test_falls_back_to_document_lang
    html, = convert 'cite:smith2020[12]', csl(lang: 'de')
    assert_equal ['(Smith, 2020, S. 12)'], paragraphs(html)
  end

  def test_csl_lang_takes_precedence_over_lang
    html, = convert 'cite:smith2020[12]', csl(lang: 'de', csl_lang: 'en')
    assert_equal ['(Smith, 2020, p. 12)'], paragraphs(html)
  end

  def test_yaml_bibliography
    html, = convert "cite:smith2020[]\n\nbibliography::[]", csl('apa', csl_file: 'references.yaml')
    assert_equal ['(Smith, 2020)'], paragraphs(html).take(1)
    assert_equal %w[smith2020], bibliography_ids(html)
  end

  def test_file_is_resolved_relative_to_the_document
    Dir.chdir(Dir.tmpdir) do
      html, = convert 'cite:smith2020[]', csl
      assert_equal ['(Smith, 2020)'], paragraphs(html)
    end
  end

  def test_missing_file_raises
    error = assert_raises(RuntimeError) { convert 'cite:smith2020[]', csl('apa', csl_file: 'missing.json') }
    assert_includes error.message, 'missing.json'
  end

  def test_unsupported_file_extension_raises
    error = assert_raises(RuntimeError) { convert 'cite:smith2020[]', csl('apa', csl_file: 'references.bib') }
    assert_includes error.message, '.bib'
  end
end
