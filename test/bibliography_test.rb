# frozen_string_literal: true

require_relative 'test_helper'

class BibliographyTest < Minitest::Test
  include AsciidoctorCslTestHelper

  def test_lists_only_cited_items
    html, = convert "cite:smith2020[] cite:doe2019[]\n\nbibliography::[]", csl

    assert_equal ['Doe, B. (2019). Alpha particles. <em>Nature</em>, <em>12</em>, 3–5.',
                  'Smith, A. (2020). <em>A history of things</em>.'], bibliography_entries(html)
  end

  def test_author_date_style_sorts_entries
    html, = convert "cite:smith2020[] cite:doe2019[]\n\nbibliography::[]", csl

    assert_equal %w[doe2019 smith2020], bibliography_ids(html)
  end

  def test_numeric_style_numbers_entries_by_appearance
    html, = convert "cite:smith2020[] cite:doe2019[]\n\nbibliography::[]", csl('ieee')

    assert_equal ['[1]A. Smith, <em>A history of things</em>. 2020.',
                  '[2]B. Doe, &#8220;Alpha particles,&#8221; <em>Nature</em>, vol. 12, pp. 3–5, 2019.'],
                 bibliography_entries(html)
  end

  def test_entries_have_anchors_for_cross_references
    html, = convert "cite:smith2020[] <<smith2020,the book>>\n\nbibliography::[]", csl

    assert_includes html, '<a id="smith2020"></a>'
    assert_includes html, '<a href="#smith2020">the book</a>'
  end

  def test_block_has_bibliography_role
    html, = convert "cite:smith2020[]\n\nbibliography::[]", csl

    assert_includes html, '<div class="openblock bibliography">'
  end

  def test_no_citations_gives_empty_bibliography
    html, = convert 'bibliography::[]', csl

    assert_empty bibliography_entries(html)
  end

  def test_multiple_bibliography_blocks_get_the_same_entries
    html, = convert "cite:smith2020[]\n\nbibliography::[]\n\nbibliography::[]", csl

    assert_equal 2, html.scan('<div class="openblock bibliography">').size
    assert_equal 2, html.scan('Smith, A. (2020)').size
  end

  def test_select_all_lists_uncited_items
    html, = convert "cite:smith2020[]\n\nbibliography::[select=all]", csl

    assert_equal %w[adams2018 doe2019 smith2020], bibliography_ids(html)
  end

  def test_select_all_numbers_cited_items_first
    html, = convert "cite:doe2019[]\n\nbibliography::[select=all]", csl('ieee')

    assert_equal '[1]', paragraphs(html).first
    assert_equal %w[doe2019 smith2020 adams2018], bibliography_ids(html)
  end

  def test_select_all_without_citations
    html, = convert 'bibliography::[select=all]', csl('ieee')

    assert_equal %w[smith2020 doe2019 adams2018], bibliography_ids(html)
  end

  def test_select_all_on_any_macro_applies_to_the_document
    html, = convert "cite:smith2020[]\n\nbibliography::[select=all]\n\nbibliography::[]", csl

    assert_equal 3 * 2, bibliography_ids(html).size
  end

  def test_select_cited_is_the_default
    html, = convert "cite:smith2020[]\n\nbibliography::[select=cited]", csl

    assert_equal %w[smith2020], bibliography_ids(html)
  end

  def test_unknown_select_warns
    html, messages = convert "cite:smith2020[]\n\nbibliography::[select=everything]", csl

    assert_equal %w[smith2020], bibliography_ids(html)
    assert(messages.any? { |message| message.include?('everything') })
  end

  def test_unknown_keys_are_not_listed
    html, = convert "cite:nope[] cite:smith2020[]\n\nbibliography::[]", csl

    assert_equal %w[smith2020], bibliography_ids(html)
  end
end
