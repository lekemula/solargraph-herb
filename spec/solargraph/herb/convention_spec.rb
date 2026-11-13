# frozen_string_literal: true

RSpec.describe Solargraph::Herb::Convention do
  it 'loads Herb' do
    expect(Herb.extract_ruby('<%= 1 %>')).to include('1')
  end

  it 'is registered as a Solargraph convention' do
    registered = Solargraph::Convention.class_variable_get(:@@conventions).map(&:class)

    expect(registered).to include(described_class)
  end
end
