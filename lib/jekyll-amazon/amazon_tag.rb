# coding: utf-8
require 'amazon/ecs'
require 'singleton'

module Jekyll
  module Amazon
    class AmazonResultCache
      include Singleton

      ITEM_HASH = {
        asin:             'ASIN',
        title:            'ItemAttributes/Title',
        author:           'ItemAttributes/Author',
        publisher:        'ItemAttributes/Manufacturer',
        publication_date: 'ItemAttributes/PublicationDate',
        release_date:     'ItemAttributes/ReleaseDate',
        detail_page_url:  'DetailPageURL',
        small_image_url:  'SmallImage/URL',
        medium_image_url: 'MediumImage/URL',
        large_image_url:  'LargeImage/URL'
      }.freeze

      CACHE_DIR = '.amazon-cache/'.freeze

      def initialize
        @result_cache = {}
        FileUtils.mkdir_p(CACHE_DIR)
      end

      def read_cache(asin)
        path = File.join(CACHE_DIR, asin)
        return nil unless File.exist?(path)
        File.open(path, 'r') { |f| Marshal.load(f.read) }
      end

      def write_cache(asin, obj)
        path = File.join(CACHE_DIR, asin)
        File.open(path, 'w') { |f| f.write(Marshal.dump(obj)) }
      end

      def setup(context)
        site = context.registers[:site]
        ::Amazon::Ecs.configure do |options|
          options[:associate_tag]     = site.config['amazon_associate_tag'] || 'tokzk-22'
          options[:AWS_access_key_id] = site.config['amazon_access_key_id'] || ENV['AWS_ACCESS_KEY']
          options[:AWS_secret_key]    = site.config['amazon_secret_key'] || ENV['AWS_SECRET_KEY']
          options[:response_group]    = 'Images,ItemAttributes'
          options[:country]           = site.config['amazon_country'] || 'jp'
        end
      end

      def item_lookup(asin)
        return @result_cache[asin] if @result_cache.key?(asin)
        return read_cache(asin) if read_cache(asin)

        retry_api do
          puts "ASIN: #{asin}"
          res = ::Amazon::Ecs.item_lookup(asin)
          item = res.get_element('Item')
          data = create_data(item)
          write_cache(asin, data)
          data
        end
      end

      private

      def retry_api
        yield
      rescue
        retry_count ||= 0
        retry_count += 1
        sleep retry_count
        retry if retry_count <= 5
        raise
      end

      def create_data(item)
        ITEM_HASH.each_with_object({}) do |(key, value), hash|
          hash[key] = item.get(value).to_s
        end
      end
    end

    class AmazonTag < Liquid::Tag
      attr_accessor :asin
      attr_accessor :template_type

      def initialize(tag_name, markup, tokens)
        super
        parse_options(markup)
        raise SyntaxError, "No ASIN given in #{tag_name} tag" if asin.nil? || asin.empty?
      end

      def render(context)
        type = template_type || :detail
        AmazonResultCache.instance.setup(context)
        item = AmazonResultCache.instance.item_lookup(asin.to_s)
        return unless item
        send(type, item)
      end

      private

      def parse_options(markup)
        options = (markup || '').split(' ').map(&:strip)
        self.asin = options.shift
        self.template_type = options.shift || :title
      end

      def title(item)
        url   = item[:detail_page_url]
        title = item[:title]
        format(%(<a href="%s" target="_blank">%s</a>), url, title)
      end

      def image(item)
        url       = item[:detail_page_url]
        title     = item[:title]
        image_url = item[:medium_image_url]
        str = <<-"EOS"
<a href="#{url}" target="_blank">
  <img src="#{image_url}" alt="#{title}" />
</a>
  EOS
        str.to_s
      end

      def detail(item)
        url       = item[:detail_page_url]
        image_url = item[:medium_image_url]
        title     = item[:title]
        author    = item[:author]
        publisher = item[:publisher]
        date      = item[:publication_date] || item[:release_date]
        str = <<-"EOS"
<div class="amazon_item">
  <div class="amazon_image">
    <a href="#{url}" target="_blank">
      <img src="#{image_url}" alt="#{title}" />
    </a>
  </div>
  <div class="amazon_info">
    <div class="amazon_info_title">
      <a href="#{url}" target="_blank">#{title}</a>
    </div>
    <div class="amazon_info_detail">
      <span class="amazon_info_author">#{author} </span>
      <span class="amazon_info_publisher">#{publisher} </span>
      <span class="amazon_info_date">#{date} </span>
    </div>
  </div>
</div>
  EOS
        str.to_s
      end
    end
  end
end

Liquid::Template.register_tag('amazon', Jekyll::Amazon::AmazonTag)
