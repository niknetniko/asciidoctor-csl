require_relative 'test_helper'

class CitationTest < Minitest::Test
  include AsciidoctorCslTestHelper

  def test_author_date_citation
    html, = convert 'See cite:smith2020[].', csl
    assert_equal ['See (Smith, 2020).'], paragraphs(html)
  end

  def test_locator_defaults_to_page
    html, = convert 'cite:smith2020[12]', csl
    assert_equal ['(Smith, 2020, p. 12)'], paragraphs(html)
  end

  def test_locator_with_label
    html, = convert 'cite:smith2020[3, chapter]', csl
    assert_equal ['(Smith, 2020, Chapter 3)'], paragraphs(html)
  end

  def test_locator_with_comma_must_be_quoted
    html, = convert 'cite:smith2020["12, 14"]', csl
    assert_equal ['(Smith, 2020, pp. 12, 14)'], paragraphs(html)
  end

  def test_unknown_label_warns
    html, messages = convert 'cite:smith2020[12, pg]', csl
    assert_equal ['(Smith, 2020, 12)'], paragraphs(html)
    assert(messages.any? { |message| message.include?("unknown locator label 'pg'") })
  end

  def test_multiple_keys_form_one_citation
    html, = convert 'cite:smith2020,doe2019[]', csl
    citation = paragraphs(html).first
    assert_match(/\A\(.*\)\z/, citation)
    assert_includes citation, 'Smith, 2020'
    assert_includes citation, 'Doe, 2019'
    assert_includes citation, '; '
  end

  def test_prefix_and_suffix
    html, = convert 'cite:smith2020,doe2019[prefix=see, suffix=for details]', csl
    citation = paragraphs(html).first
    assert citation.start_with?('(see '), citation
    assert citation.end_with?(', for details)'), citation
  end

  def test_locator_applies_to_last_key
    html, = convert 'cite:smith2020,doe2019[12]', csl
    assert_equal ['(Smith, 2020; Doe, 2019, p. 12)'], paragraphs(html)
  end

  # citeproc 1.1.0 leaks suppressed variables between renders,
  # see citeproc_patches.rb.
  def test_repeated_citations_keep_the_author
    html, = convert 'cite:smith2020[] cite:smith2020,doe2019[] cite:smith2020[] cite:doe2019[]' \
                    "\n\nbibliography::[]", csl
    assert_equal '(Smith, 2020) (Smith, 2020; Doe, 2019) (Smith, 2020) (Doe, 2019)', paragraphs(html).first
  end

  def test_numeric_citations_are_numbered_by_appearance
    html, = convert "cite:doe2019[] cite:smith2020[12] cite:doe2019[]\n\nbibliography::[]", csl('ieee')
    assert_equal '[1] [2, p. 12] [1]', paragraphs(html).first
    assert_equal %w[doe2019 smith2020], bibliography_ids(html)
  end

  def test_numeric_citations_without_bibliography_macro
    html, = convert 'cite:doe2019[] cite:smith2020[]', csl('ieee')
    assert_equal ['[1] [2]'], paragraphs(html)
  end

  def test_formatting_is_converted
    html, = convert "cite:smith2020[]\n\nbibliography::[]", csl
    assert_includes bibliography_entries(html), 'Smith, A. (2020). <em>A history of things</em>.'
  end

  def test_unknown_key_falls_back_to_the_key_and_warns
    html, messages = convert 'cite:nope[]', csl
    assert_equal ['[nope]'], paragraphs(html)
    assert(messages.any? { |message| message.include?('unknown references: nope') })
  end

  def test_unknown_keys_are_left_out_of_a_citation
    html, messages = convert 'cite:nope,smith2020[]', csl
    assert_equal ['(Smith, 2020)'], paragraphs(html)
    assert(messages.any? { |message| message.include?('nope') })
  end

  def test_escaped_citation_is_not_rendered_or_collected
    html, = convert "\\cite:smith2020[] cite:doe2019[]\n\nbibliography::[]", csl('ieee')
    assert_equal 'cite:smith2020[] [1]', paragraphs(html).first
    assert_equal %w[doe2019], bibliography_ids(html)
  end

  def test_citation_in_listing_block_is_not_rendered_or_collected
    html, = convert "----\ncite:smith2020[]\n----\n\ncite:doe2019[]\n\nbibliography::[]", csl('ieee')
    assert_includes html, '<pre>cite:smith2020[]</pre>'
    assert_equal %w[doe2019], bibliography_ids(html)
  end

  def test_citations_are_collected_from_all_kinds_of_text
    source = <<~ADOC
      .Block title cite:adams2018[]
      Paragraph.

      * List item cite:doe2019[]

      |===
      | Cell cite:smith2020[]
      |===
    ADOC
    html, = convert source, csl('ieee')
    assert_includes html, 'Block title [1]'
    assert_includes html, 'List item [2]'
    assert_includes html, 'Cell [3]'
  end

  # Not supported at the moment because AsciiDoctor is not nice.
  def test_citation_in_section_title_is_not_supported
    html, messages = convert "== Section cite:smith2020[]\n\nText.\n\nbibliography::[]", csl
    assert_includes html, 'Section [smith2020]'
    assert_includes messages, 'cite: unknown references: smith2020'
    assert_equal %w[smith2020], bibliography_ids(html)
  end

  def test_citation_in_nested_document
    source = <<~ADOC
      cite:doe2019[]

      |===
      a| Nested cite:smith2020[]
      |===

      bibliography::[]
    ADOC
    html, = convert source, csl('ieee')
    assert_includes html, 'Nested [2]'
    assert_equal %w[doe2019 smith2020], bibliography_ids(html)
  end

  def test_note_style_renders_footnotes
    html, = convert "Text.cite:smith2020[12]\n\nbibliography::[]", csl('chicago-notes-bibliography-17th-edition')
    assert_match(/Text\.<sup class="footnote">/, html)
    footnote = html[%r{<div class="footnote" id="_footnotedef_1">.*?</div>}m]
    refute_nil footnote
    assert_includes footnote, 'Anna Smith'
    assert_includes footnote, '12'
    assert_equal ['Smith, Anna. <em>A History of Things</em>. 2020.'], bibliography_entries(html)
  end

  def test_without_csl_file_citations_fall_back_to_keys
    html, messages = convert 'cite:smith2020[]'
    assert_equal ['[smith2020]'], paragraphs(html)
    refute_empty messages
  end

  def test_document_without_csl_file_and_citations_is_untouched
    html, messages = convert 'Just text.'
    assert_equal ['Just text.'], paragraphs(html)
    assert_empty messages
  end

  def test_state_does_not_leak_between_documents
    first, = convert 'cite:smith2020[]', csl
    second, = convert 'cite:smith2020[]', csl('ieee')
    third, = convert 'cite:smith2020[]'
    assert_equal ['(Smith, 2020)'], paragraphs(first)
    assert_equal ['[1]'], paragraphs(second)
    assert_equal ['[smith2020]'], paragraphs(third)
  end
end
