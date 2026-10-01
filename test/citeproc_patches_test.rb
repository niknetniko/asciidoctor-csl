# frozen_string_literal: true

require_relative 'test_helper'

class CiteprocPatchesTest < Minitest::Test
  def test_copies_do_not_share_suppressed_variables
    item = CiteProc::Item.new(id: 'a')
    item.suppressed?('author')
    copy = item.dup
    copy.suppress!('author')

    assert_empty item.suppressed
    assert_equal ['author'], copy.suppressed
  end

  def test_bibliography_does_not_affect_later_citations
    processor = CiteProc::Processor.new style: 'apa', format: 'text', locale: 'en-US'
    processor << { 'id' => 'a', 'type' => 'book', 'title' => 'Title',
                   'author' => [{ 'family' => 'Smith', 'given' => 'A' }], 'issued' => { 'date-parts' => [[2020]] } }
    processor << { 'id' => 'b', 'type' => 'book', 'title' => 'Other',
                   'author' => [{ 'family' => 'Doe', 'given' => 'B' }], 'issued' => { 'date-parts' => [[2019]] } }
    first = processor.bibliography.references

    assert_equal first, processor.bibliography.references
    assert_equal '(Smith, 2020)', processor.render(:citation, id: 'a')
  end
end
