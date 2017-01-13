# coding: utf-8
require 'amazon/ecs'
require 'singleton'
require 'i18n'
require 'erb'

module Jekyll
  module Amazon
    class AmazonResultCache
      include Singleton

      CACHE_DIR = '.amazon-cache/'.freeze
      RESPONSE_GROUP = 'SalesRank,Images,ItemAttributes,EditorialReview'.freeze

      ITEM_HASH = {
        asin:             'ASIN',
        salesrank:        'SalesRank',
        title:            'ItemAttributes/Title',
        author:           'ItemAttributes/Author',
        publisher:        'ItemAttributes/Manufacturer',
        publication_date: 'ItemAttributes/PublicationDate',
        release_date:     'ItemAttributes/ReleaseDate',
        detail_page_url:  'DetailPageURL',
        small_image_url:  'SmallImage/URL',
        medium_image_url: 'MediumImage/URL',
        large_image_url:  'LargeImage/URL',
        description:      'EditorialReviews/EditorialReview/Content'
      }.freeze

      def initialize
        @result_cache = {}
        FileUtils.mkdir_p(CACHE_DIR)
      end

      def setup(country)
        ::Amazon::Ecs.debug = debug?
        ::Amazon::Ecs.configure do |options|
          options[:associate_tag]     = ENV.fetch('ECS_ASSOCIATE_TAG')
          options[:AWS_access_key_id] = ENV.fetch('AWS_ACCESS_KEY_ID')
          options[:AWS_secret_key]    = ENV.fetch('AWS_SECRET_KEY')
          options[:response_group]    = RESPONSE_GROUP
          options[:country]           = country
        end
      end

      def item_lookup(asin)
        return @result_cache[asin] if @result_cache.key?(asin)
        return read_cache(asin) if read_cache(asin)
        item = retry_api do
          res = ::Amazon::Ecs.item_lookup(asin)
          res.first_item
        end
        raise ArgumentError unless item
        save(asin, item)
      end

      private

      def save(asin, item)
        data = create_data(item)
        write_cache(asin, data)
        @result_cache[asin] = data
        @result_cache[asin]
      end

      def debug?
        ENV.fetch('JEKYLL_AMAZON_DEBUG', 'false') == 'true'
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
        return unless item
        ITEM_HASH.each_with_object({}) do |(key, value), hash|
          hash[key] = item.get(value).to_s
        end
      end
    end

    class AmazonTag < Liquid::Tag
      DEFAULT_LOCALE  = 'en'
      DEFAULT_COUNTRY = 'us'

      def initialize(tag_name, markup, tokens)
        super
        parse_options(markup)
        error "No ASIN given in #{tag_name} tag" if @asin.nil? || @asin.empty?
      end

      def render(context)
        setup(context)
        setup_i18n
        item = AmazonResultCache.instance.item_lookup(@asin.to_s)
        return unless item
        render_from_file(@template_type, item)
      end

      private

      def setup(context)
        @site   = context.registers[:site]
        @config = @site.config['jekyll-amazon'] || {}
        country = @config['country'] || DEFAULT_COUNTRY
        @template_dir = @config['template_dir']
        AmazonResultCache.instance.setup(country)
      end

      def setup_i18n
        locale = @config['locale'] || DEFAULT_LOCALE
        I18n.enforce_available_locales = false
        I18n.locale = locale.to_sym
        file = File.expand_path("../../locales/#{locale}.yml", __dir__)
        I18n.load_path = [file]
      end

      def parse_options(markup)
        options = (markup || '').split(' ').map(&:strip)
        @asin = options.shift
        @template_type = options.shift || :title
      end

      def render_from_file(type, item)
        if @template_dir
          template_file = File.expand_path("#{type}.erb", @template_dir)
          file = template_file if File.exist? template_file
        end
        file ||= File.expand_path("../../templates/#{type}.erb", __dir__)
        ERB.new(open(file).read).result(binding)
      end

      def br2nl(text)
        text.gsub(%r{&lt;br\s*/?&gt;}, "\n") unless text.nil?
      end

      def error(message)
        raise SyntaxError, message
      end
    end
  end
end

Liquid::Template.register_tag('amazon', Jekyll::Amazon::AmazonTag)
