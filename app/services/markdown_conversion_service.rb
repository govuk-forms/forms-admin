class MarkdownConversionService
  attr_reader :text

  def initialize(text)
    @text = text
  end

  # Convert a text to HTML, using simple_format, as in the Runner. Then convert this to Markdown.
  def to_markdown
    ReverseMarkdown.convert(as_html, unknown_tags: :pass_through)
  end

  def as_html
    HTMLFormatter.new.render_text_to_html(text)
  end

  # This class renders simple text fields, like declaration_markdown to HTML.
  # These fields can have limited HTML tags, like <p> and <br>.
  # It matches the code used in the runner.

  class HTMLFormatter
    include ActionView::Helpers::TextHelper

    def render_text_to_html(text)
      scrubber = LimitedHtmlScrubber.new(allow_headings: false)
      simple_format(text, {}, sanitize: true, sanitize_options: { scrubber: })
    end

    class LimitedHtmlScrubber < Rails::Html::PermitScrubber
      def initialize(allow_headings: false)
        super()

        self.tags = ["a", "ol", "ul", "li", "p", "br", *(%w[h2 h3] if allow_headings)]

        self.attributes = %w[href class rel target title]
      end
    end
  end

  class Li < ReverseMarkdown::Converters::Li
    def prefix_for(node)
      if node.parent.name == "ol"
        index = node.parent.xpath("li").index(node)
        "#{index.to_i + 1}. "
      else
        "* "
      end
    end
  end

  ReverseMarkdown::Converters.register :li, Li.new

  # Keep the HTMLFormatter private
  private_constant :HTMLFormatter
end
