require_relative 'test_helper'

class FormatTest < Minitest::Test
  def setup
    @format = AsciidoctorCsl::Asciidoc.new
    @locale = CSL::Locale.load('en-US')
  end

  def apply(text, **formatting)
    node = CSL::Style::Text.new(formatting.transform_keys { |key| key.to_s.tr('_', '-') })
    @format.apply(text.dup, node, @locale)
  end

  def test_format_is_found_by_name
    assert_instance_of AsciidoctorCsl::Asciidoc, CiteProc::Ruby::Format.load('asciidoc')
  end

  def test_italic
    assert_equal '__text__', apply('text', font_style: 'italic')
  end

  def test_oblique_is_italic
    assert_equal '__text__', apply('text', font_style: 'oblique')
  end

  def test_normal_font_style
    assert_equal 'text', apply('text', font_style: 'normal')
  end

  def test_bold
    assert_equal '**text**', apply('text', font_weight: 'bold')
  end

  def test_light_and_normal_font_weight
    assert_equal 'text', apply('text', font_weight: 'light')
    assert_equal 'text', apply('text', font_weight: 'normal')
  end

  def test_small_caps
    assert_equal '[.small-caps]##text##', apply('text', font_variant: 'small-caps')
  end

  def test_underline
    assert_equal '[.underline]##text##', apply('text', text_decoration: 'underline')
  end

  def test_superscript_and_subscript
    assert_equal '^1^', apply('1', vertical_align: 'sup')
    assert_equal '~2~', apply('2', vertical_align: 'sub')
    assert_equal 'text', apply('text', vertical_align: 'baseline')
  end

  # AsciiDoc superscript and subscript cannot contain spaces.
  def test_spaces_in_superscript_become_non_breaking
    assert_equal '^1,{nbsp}2^', apply('1, 2', vertical_align: 'sup')
    assert_equal '~a{nbsp}b~', apply('a b', vertical_align: 'sub')
  end

  def test_combined_formatting
    assert_equal '**__text__**', apply('text', font_style: 'italic', font_weight: 'bold')
  end

  def test_text_case
    assert_equal 'THE HISTORY OF THINGS', apply('the history of things', text_case: 'uppercase')
    assert_equal 'The History of Things', apply('the history of things', text_case: 'title')
    assert_equal 'The history of things', apply('the history of things', text_case: 'capitalize-first')
  end

  def test_text_case_keeps_asciidoc_syntax
    text = 'the {product} of link:https://example.org[in vitro] and [.role]##smith## on +iPhone+ use'
    assert_equal 'THE {product} OF link:https://example.org[in vitro] AND [.role]##SMITH## ON +iPhone+ USE',
                 apply(text, text_case: 'uppercase')
    assert_equal 'The {product} of link:https://example.org[in vitro] and [.role]##Smith## on +iPhone+ Use',
                 apply(text, text_case: 'title')
  end

  def test_bibliography_entries_are_separate_paragraphs
    bibliography = CiteProc::Bibliography.new
    @format.bibliography(bibliography)
    assert_equal "\n\n", bibliography.connector
  end
end

# Quotes use AsciiDoc dynamic quotes
class QuotesTest < Minitest::Test
  include AsciidoctorCslTestHelper

  def article(title)
    [{ 'id' => 'a', 'type' => 'article-journal', 'title' => title, 'container-title' => 'Nature',
       'author' => [{ 'family' => 'Doe', 'given' => 'B' }], 'issued' => { 'date-parts' => [[2019]] } }]
  end

  def render(title, locale)
    Tempfile.create(['references', '.json']) do |file|
      file.write JSON.generate(article(title))
      file.flush
      processor = AsciidoctorCsl::Processor.new file.path, false, 'ieee', locale
      processor.add_citations ['a']
      processor.finalize_macro_processing
      processor.build_bibliography_list.first
    end
  end

  def test_punctuation_inside_quotes_for_us_english
    assert_includes render('Alpha', 'en-US'), '"`Alpha,`"'
  end

  def test_punctuation_outside_quotes_for_british_english
    assert_includes render('Alpha', 'en-GB'), '"`Alpha`",'
  end

  def test_quotes_in_title_become_inner_quotes
    assert_includes render('The "`beta`" decay', 'en-US'), %q("`The '`beta`' decay,`")
  end

  def test_quotes_are_converted_by_asciidoctor
    html, = convert "cite:doe2019[]\n\nbibliography::[]", csl('ieee')
    assert_includes bibliography_entries(html).first, '&#8220;Alpha particles,&#8221;'
  end
end
