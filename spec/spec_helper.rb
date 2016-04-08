TEST_DIR = File.dirname(__FILE__)
require 'rubygems'
require 'jekyll'
require File.expand_path("../lib/jekyll-amazon.rb", TEST_DIR)

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
