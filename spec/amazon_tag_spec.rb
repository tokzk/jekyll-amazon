require 'spec_helper'

describe Jekyll::Amazon::AmazonTag do
  let(:doc) { doc_with_content(content) }
  let(:content) { "{% amazon #{asin} %}" }
  let(:output) do
    doc.content = content
    doc.output  = Jekyll::Renderer.new(doc.site, doc).run
  end

  context 'valid no asin' do
    let(:asin) { '' }

    it 'raise Liquid SyntaxError' do
      expect { output }.to raise_error(SyntaxError)
    end
  end

  context 'valid asin' do
    let(:asin) { '4797386290' }

    it 'match asin' do
      expect(output).to match('4797386290')
    end
  end

  it 'has a version number' do
    expect(Jekyll::Amazon::VERSION).not_to be nil
  end
end
