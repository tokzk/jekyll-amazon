# coding: utf-8
require 'spec_helper'

describe Jekyll::Amazon::AmazonTag do
  let(:doc) { doc_with_content(content) }
  let(:content) { "{% amazon #{asin} %}" }
  let(:output) do
    doc.content = content
    doc.output  = Jekyll::Renderer.new(doc.site, doc).run
  end

  context 'when the asin is valid' do
    let(:asin) { '0974514055' }

    it 'match asin' do
      expect(output).to match(/Programming Ruby: The Pragmatic Programmer’s Guide/)
    end
  end

  context 'amazon tag' do
    let(:content) { "{% amazon #{asin} detail %}" }
    let(:asin) { 'B00FZLOYEM' }

    it '#br2nl' do
      expect(output).not_to match '<br/>'
    end
  end

  context 'no asin' do
    let(:asin) { '' }

    it 'raises an error' do
      expect(-> { output }).to raise_error(SyntaxError)
    end
  end

  context 'invalid asin' do
    let(:asin) { '111111111A' }

    it 'raises an error' do
      expect(-> { output }).to raise_error(ArgumentError)
    end
  end

  it 'has a version number' do
    expect(Jekyll::Amazon::VERSION).not_to be nil
  end
end
