module Jekyll
  module Amazon
    class AmazonTag < Liquid::Tag

      def self.greet
        "Hello World!"
      end

      def render(context)
        "hoge"
      end
    end
  end
end

Liquid::Template.register_tag('amazon', Jekyll::Amazon::AmazonTag)
