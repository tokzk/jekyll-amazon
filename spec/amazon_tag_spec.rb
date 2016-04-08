require 'spec_helper'

describe Jekyll::Amazon::AmazonTag do
  it 'has a version number' do
    expect(Jekyll::Amazon::VERSION).not_to be nil
  end

  describe '#greet' do
    it 'returns "Hello World!"' do
      expect(Jekyll::Amazon::AmazonTag.greet).to eq('Hello World!')
    end
  end
end

