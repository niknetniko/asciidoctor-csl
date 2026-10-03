# frozen_string_literal: true

require_relative 'test_helper'

class TitleLinksTest < Minitest::Test
  include AsciidoctorCslTestHelper

  KEYS = %w[both url full-doi brackets untitled plain].freeze

  def test_title_links_to_doi_instead_of_url
    entry = entry_for 'both'

    assert_equal 'Smith, A. (2020). <a href="https://doi.org/10.1000/xyz_1">Linked by DOI</a>. <em>Nature</em>.', entry
  end

  def test_title_links_to_url_without_doi
    entry = entry_for 'url'

    assert_equal 'Doe, B. (2019). <em><a href="https://example.org/page_1?q=[1]">Linked by URL</a></em>.', entry
  end

  def test_doi_that_is_already_a_url_is_not_prefixed
    entry = entry_for 'full-doi'

    assert_equal 'Evans, D. (2017). <a href="https://doi.org/10.1000/full">Full DOI</a>. <em>Nature</em>.', entry
  end

  def test_brackets_in_title_are_escaped
    entry = entry_for 'brackets'

    assert_equal 'Fox, E. (2016). <a href="https://doi.org/10.1000/draft">A [draft] report</a>. <em>Nature</em>.', entry
  end

  def test_formatting_and_quotes_stay_inside_the_link
    entry = entry_for 'both', style: 'ieee'

    assert_includes entry, '<a href="https://doi.org/10.1000/xyz_1">&#8220;Linked by DOI&#8221;</a>, <em>Nature</em>'
  end

  def test_entry_without_title_keeps_its_doi
    assert_equal 'Roe, C. (2018). <em>Nature</em>. <a href="https://doi.org/10.1000/untitled" class="bare">https://doi.org/10.1000/untitled</a>',
                 entry_for('untitled')
    assert_equal '[5]C. Roe, <em>Nature</em>, 2018, doi: 10.1000/untitled.', entry_for('untitled', style: 'ieee')
  end

  def test_entry_without_doi_or_url_is_unchanged
    assert_equal 'Adams, F. (2015). <em>No links</em>.', entry_for('plain')
  end

  def test_off_by_default
    html, = convert "#{cite_all}\n\nbibliography::[]", attributes

    refute_includes html, '<a href="https://doi.org/10.1000/xyz_1">Linked by DOI</a>'
    assert_includes bibliography_entries(html),
                    'Smith, A. (2020). Linked by DOI. <em>Nature</em>. ' \
                    '<a href="https://doi.org/10.1000/xyz_1" class="bare">https://doi.org/10.1000/xyz_1</a>'
  end

  def test_citations_are_not_linked
    html, = convert "cite:both[]\n\nbibliography::[]", attributes(link: true)

    assert_equal '(Smith, 2020)', paragraphs(html).first
  end

  def test_note_style_citations_are_not_linked
    html, = convert "Text.cite:plain[]\n\nbibliography::[]",
                    attributes('chicago-notes-bibliography-17th-edition', link: true)
    footnotes = html[/<div id="footnotes">.*/m]

    refute_includes footnotes, 'https://'
  end

  def test_bibliography_can_disable_links
    html, = convert "#{cite_all}\n\nbibliography::[link-title=false]", attributes(link: true)

    refute_includes html, '>Linked by DOI</a>'
  end

  def test_bibliography_can_enable_links
    html, = convert "#{cite_all}\n\nbibliography::[link-title=true]", attributes

    assert_includes html, '<a href="https://doi.org/10.1000/xyz_1">Linked by DOI</a>'
  end

  def test_bibliographies_can_differ
    html, = convert "cite:both[]\n\nbibliography::[]\n\nbibliography::[link-title=false]", attributes(link: true)
    linked, plain = bibliography_entries(html)

    assert_includes linked, '<a href="https://doi.org/10.1000/xyz_1">Linked by DOI</a>'
    assert_includes plain, 'Linked by DOI. <em>Nature</em>.'
  end

  def test_bibitem_is_linked
    html, = convert 'bibitem:both[]', attributes(link: true)

    assert_equal ['Smith, A. (2020). <a href="https://doi.org/10.1000/xyz_1">Linked by DOI</a>. <em>Nature</em>.'],
                 paragraphs(html)
  end

  def test_bibitem_can_disable_links
    html, = convert 'bibitem:both[link-title=false]', attributes(link: true)

    refute_includes html, '>Linked by DOI</a>'
  end

  def test_bibitem_can_enable_links
    html, = convert 'bibitem:both[link-title=true]', attributes

    assert_includes html, '<a href="https://doi.org/10.1000/xyz_1">Linked by DOI</a>'
  end

  def test_bibitem_override_does_not_leak_into_later_entries
    html, = convert "bibitem:both[link-title=true]\n\nbibitem:both[]", attributes
    linked, plain = paragraphs(html)

    assert_includes linked, '>Linked by DOI</a>'
    refute_includes plain, '>Linked by DOI</a>'
  end

  def test_bibitem_url_with_brackets
    skip 'bibitem: substitutes its output twice, which breaks URLs containing brackets'

    html, = convert 'bibitem:url[]', attributes(link: true)

    assert_includes html, '<a href="https://example.org/page_1?q=[1]">Linked by URL</a>'
  end

  def test_repeated_entries_stay_linked
    html, = convert "bibitem:both[]\n\nbibitem:both[]", attributes(link: true)
    first, second = paragraphs(html)

    assert_includes first, '<a href="https://doi.org/10.1000/xyz_1">'
    assert_equal first, second
  end

  def test_repeated_entries_do_not_substitute_the_author
    html, = convert "bibitem:both[]\n\nbibitem:both[]",
                    attributes('chicago-notes-bibliography-17th-edition', link: true)

    entry = 'Smith, Anna. <a href="https://doi.org/10.1000/xyz_1">&#8220;Linked by DOI&#8221;</a>. ' \
            '<em>Nature</em>, 2020.'

    assert_equal [entry, entry], paragraphs(html)
  end

  private

  def attributes(style = 'apa', link: false)
    attributes = { 'csl-file' => 'online.json', 'csl-style' => style }
    attributes['csl-link-title'] = '' if link
    attributes
  end

  def cite_all
    KEYS.map { |key| "cite:#{key}[]" }.join(' ')
  end

  # The bibliography entry for the key, with title links on.
  def entry_for(key, style: 'apa')
    html, = convert "#{cite_all}\n\nbibliography::[]", attributes(style, link: true)
    bibliography_entries(html)[bibliography_ids(html).index(key)]
  end
end
