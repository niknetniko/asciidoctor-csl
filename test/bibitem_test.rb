# frozen_string_literal: true

require_relative 'test_helper'

class BibitemTest < Minitest::Test
  include AsciidoctorCslTestHelper

  def test_renders_complete_entry
    html, = convert 'bibitem:doe2019[]', csl

    assert_equal ['Doe, B. (2019). Alpha particles. <em>Nature</em>, <em>12</em>, 3–5.'], paragraphs(html)
  end

  def test_numeric_style_entry_has_no_number
    html, = convert 'bibitem:smith2020[]', csl('ieee')

    assert_equal ['A. Smith, <em>A history of things</em>. 2020.'], paragraphs(html)
  end

  def test_uncited_item
    html, = convert 'bibitem:adams2018[]', csl

    assert_equal ['Adams, C. (2018). <em>Uncited work</em>.'], paragraphs(html)
  end

  def test_publication_list
    html, = convert "* bibitem:smith2020[]\n* bibitem:doe2019[]", csl

    assert_equal ['Smith, A. (2020). <em>A history of things</em>.',
                  'Doe, B. (2019). Alpha particles. <em>Nature</em>, <em>12</em>, 3–5.'], paragraphs(html)
  end

  def test_is_not_listed_in_bibliography
    html, = convert "cite:smith2020[] bibitem:doe2019[]\n\nbibliography::[]", csl

    assert_equal %w[smith2020], bibliography_ids(html)
  end

  def test_does_not_affect_numbering
    html, = convert "bibitem:doe2019[]\n\ncite:smith2020[]\n\nbibliography::[]", csl('ieee')

    assert_equal '[1]', paragraphs(html)[1]
    assert_equal %w[smith2020], bibliography_ids(html)
  end

  def test_cited_item_can_also_be_an_entry
    html, = convert "cite:doe2019[]\n\nbibitem:doe2019[]\n\nbibliography::[]", csl('ieee')

    assert_equal '[1]', paragraphs(html).first
    assert_equal 'B. Doe, &#8220;Alpha particles,&#8221; <em>Nature</em>, vol. 12, pp. 3–5, 2019.', paragraphs(html)[1]
    assert_equal %w[doe2019], bibliography_ids(html)
  end

  def test_has_no_anchor
    html, = convert "cite:doe2019[]\n\nbibitem:doe2019[]\n\nbibliography::[]", csl

    assert_equal 1, html.scan('id="doe2019"').size
  end

  def test_repeated_entries_render_the_same
    html, = convert "bibitem:smith2020[]\n\nbibitem:smith2020[]", csl
    first, second = paragraphs(html)

    assert_equal first, second
  end

  def test_quotes_are_converted
    html, = convert 'bibitem:doe2019[]', csl('ieee')

    assert_includes paragraphs(html).first, '&#8220;Alpha particles,&#8221;'
  end

  def test_note_style_renders_inline
    html, = convert 'bibitem:smith2020[]', csl('chicago-notes-bibliography-17th-edition')

    assert_equal ['Smith, Anna. <em>A History of Things</em>. 2020.'], paragraphs(html)
    refute_includes html, 'footnote'
  end

  def test_unknown_key_falls_back_to_the_key_and_warns
    html, messages = convert 'bibitem:nope[]', csl

    assert_equal ['[nope]'], paragraphs(html)
    assert(messages.any? { |message| message.include?('bibitem: unknown reference: nope') })
  end

  def test_without_csl_file_falls_back_to_the_key
    html, messages = convert 'bibitem:smith2020[]'

    assert_equal ['[smith2020]'], paragraphs(html)
    refute_empty messages
  end
end
