# frozen_string_literal: true

require_relative 'test_helper'

class LinksTest < Minitest::Test
  include AsciidoctorCslTestHelper

  def test_citation_links_to_bibliography_entry
    html, = convert "cite:smith2020[12]\n\nbibliography::[]", csl

    assert_includes html, '<p>(<a href="#smith2020">Smith, 2020, p. 12</a>)</p>'
    assert_includes html, '<a id="smith2020"></a>'
  end

  def test_each_key_links_to_its_own_entry
    html, = convert "cite:smith2020,doe2019[prefix=see, suffix=for details]\n\nbibliography::[]", csl

    assert_includes html,
                    '<p>(see <a href="#smith2020">Smith, 2020</a>; <a href="#doe2019">Doe, 2019</a>, for details)</p>'
  end

  def test_numeric_citation_links_the_number
    html, = convert "cite:doe2019[] cite:smith2020[]\n\nbibliography::[]", csl('ieee')

    assert_includes html, '<p><a href="#doe2019">[1]</a> <a href="#smith2020">[2]</a></p>'
  end

  def test_link_can_be_disabled_per_citation
    html, = convert "cite:smith2020[link=false] cite:doe2019[]\n\nbibliography::[]", csl

    assert_includes html, '<p>(Smith, 2020) (<a href="#doe2019">Doe, 2019</a>)</p>'
  end

  def test_no_links_without_bibliography
    html, = convert 'cite:smith2020[]', csl

    refute_includes html, '<a href='
  end

  def test_note_style_links_inside_footnote
    html, = convert "Text.cite:smith2020[12]\n\nbibliography::[]", csl('chicago-notes-bibliography-17th-edition')
    footnotes = html[/<div id="footnotes">.*/m]

    assert_includes footnotes, '<a href="#smith2020">'
  end

  def test_bibliography_entries_always_have_anchors
    html, = convert "cite:smith2020[link=false]\n\nbibliography::[]", csl

    assert_equal %w[smith2020], bibliography_ids(html)
  end
end
