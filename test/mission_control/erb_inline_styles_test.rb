# frozen_string_literal: true

require "test_helper"
require "better_html"
require "better_html/parser"
require "better_html/tree/tag"

class MissionControl::ErbInlineStylesTest < ActiveSupport::TestCase
  ERB_GLOB = Rails.root.join(
    "..", "..", "app", "views", "**", "{*.htm,*.html,*.htm.erb,*.html.erb,*.html+*.erb}"
  )

  Dir[ERB_GLOB].each do |filename|
    pathname = Pathname.new(filename).relative_path_from(Rails.root)

    test "No inline styles in /#{pathname.relative_path_from('../..')}" do
      buffer = Parser::Source::Buffer.new("")
      buffer.source = File.read(filename)
      parser = BetterHtml::Parser.new(buffer)

      parser.nodes_with_type(:tag).each do |tag_node|
        tag = BetterHtml::Tree::Tag.from_node(tag_node)
        assert_nil tag.attributes["style"]
      end
    end
  end
end
