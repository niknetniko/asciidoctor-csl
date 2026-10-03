# frozen_string_literal: true

require_relative 'test_helper'

# Printed URLs and DOIs, as opposed to links on the title (see title_links_test.rb).
class UrlTest < Minitest::Test
  include AsciidoctorCslTestHelper

  NOTE_STYLE = 'chicago-notes-bibliography-17th-edition'

  def test_url_with_brackets_is_linked
    assert_equal 'Doe, B. (2019). <em>Linked by URL</em>. ' \
                 '<a href="https://example.org/page_1?q=[1]" class="bare">https://example.org/page_1?q=[1]</a>',
                 entry_for('url')
  end

  def test_doi_prefix_becomes_part_of_the_link
    assert_equal 'Smith, A. (2020). Linked by DOI. <em>Nature</em>. ' \
                 '<a href="https://doi.org/10.1000/xyz_1" class="bare">https://doi.org/10.1000/xyz_1</a>',
                 entry_for('both')
  end

  def test_doi_that_is_already_a_url_is_not_prefixed
    assert_includes entry_for('full-doi'),
                    '<a href="https://doi.org/10.1000/full" class="bare">https://doi.org/10.1000/full</a>'
  end

  def test_doi_without_url_prefix_is_text
    assert_equal '[1]C. Roe, <em>Nature</em>, 2018, doi: 10.1000/untitled.', entry_for('untitled', 'ieee')
  end

  def test_note_citation_keeps_its_cross_reference
    html, = convert "Text.cite:both[]\n\nbibliography::[]", csl_online(NOTE_STYLE)

    assert_includes footnotes(html),
                    '<a href="#both">Anna Smith, &#8220;Linked by DOI,&#8221; <em>Nature</em>, ahead of print, 2020, ' \
                    'https://doi.org/10.1000/xyz_1</a>.'
  end

  def test_note_citation_without_bibliography_links_the_url
    html, = convert 'Text.cite:url[]', csl_online(NOTE_STYLE)

    assert_includes footnotes(html),
                    '2019, <a href="https://example.org/page_1?q=[1]" class="bare">https://example.org/page_1?q=[1]</a>.'
  end

  def test_note_citation_with_brackets
    html, = convert "Text.cite:brackets[]\n\nbibliography::[]", csl_online(NOTE_STYLE)

    assert_includes footnotes(html), '&#8220;A [Draft] Report,&#8221;'
  end

  def test_bibitem_links_url_once
    html, = convert 'bibitem:url[]', csl_online('apa')

    assert_includes paragraphs(html).first,
                    '<a href="https&#58;//example.org/page_1?q=[1]" class="bare">' \
                    'https&#58;//example.org/page_1?q=[1]</a>'
    assert_equal 1, html.scan('<a ').size
  end

  def test_url_with_plus_signs
    html, = convert "cite:url[]\n\nbibliography::[]", { 'csl-file' => 'plus.json', 'csl-style' => 'apa' }

    assert_includes bibliography_entries(html).first,
                    '<a href="https://example.org/c++/a+++b" class="bare">https://example.org/c++/a+++b</a>'
  end

  private

  def csl_online(style)
    { 'csl-file' => 'online.json', 'csl-style' => style }
  end

  def footnotes(html)
    html[/<div id="footnotes">.*/m]
  end

  def entry_for(key, style = 'apa')
    html, = convert "cite:#{key}[]\n\nbibliography::[]", csl_online(style)
    bibliography_entries(html).first
  end
end
