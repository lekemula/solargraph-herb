# frozen_string_literal: true

RSpec.describe Solargraph::Herb::Reporter, '#diagnose' do
  subject(:reporter) { described_class.new }

  let(:view) { '/app/app/views/posts/show.html.erb' }

  # @param erb [String]
  # @param filename [String]
  # @return [Array<Hash>]
  def diagnose(erb, filename = view)
    reporter.diagnose(Solargraph::Source.load_string(erb, filename), nil)
  end

  # @param erb [String]
  # @return [Array<Array(String, Hash)>] each diagnostic's code and range
  def codes_and_ranges(erb)
    diagnose(erb).map { |diagnostic| [diagnostic[:code], diagnostic[:range]] }
  end

  # @param start_line [Integer]
  # @param start_character [Integer]
  # @param end_line [Integer]
  # @param end_character [Integer]
  # @return [Hash] an LSP range
  def range(start_line, start_character, end_line, end_character)
    { start: { line: start_line, character: start_character }, end: { line: end_line, character: end_character } }
  end

  it 'reports an unclosed tag' do
    expect(diagnose("<div>\n  <span>x</div>\n")).to eq [
      {
        range: range(1, 2, 1, 8),
        severity: Solargraph::Diagnostics::Severities::ERROR,
        source: 'herb',
        code: 'MissingClosingTagError',
        message: 'Opening tag `<span>` at (2:3) doesn\'t have a matching closing tag `</span>` in the same scope.'
      }
    ]
  end

  it 'reports a tag missing its %>' do
    expect(codes_and_ranges("<p><%= post.title </p>\n")).to eq [['UnclosedERBTagError', range(0, 3, 0, 18)]]
  end

  it 'reports nothing on a valid view' do
    expect(diagnose("<p><%= post.title %></p>\n")).to eq []
  end

  it 'counts columns in characters after a multibyte character' do
    expect(codes_and_ranges("<p>ok</p>\n<p>Café — <span>x</p>\n"))
      .to eq [['MissingClosingTagError', range(1, 10, 1, 16)]]
  end

  it 'reports nothing on a file the plugin does not map' do
    expect(diagnose("<div>\n", '/app/app/mailers/welcome.html.erb')).to eq []
  end

  it 'reports nothing on a source another convention transformed' do
    source = Solargraph::Source.new('', '/app/features/login.feature', 0, original_code: "<div>\n")

    expect(reporter.diagnose(source, nil)).to eq []
  end

  it 'reports an unbalanced block without the Ruby syntax errors in its tags' do
    expect(codes_and_ranges("<% if post.draft? %>\n  <p>x</p>\n")).to eq [['MissingERBEndTagError', range(0, 0, 0, 20)]]
  end

  it 'leaves a Ruby syntax error in a tag out' do
    expect(diagnose("<p><%= post_title( %></p>\n")).to eq []
  end

  it 'logs a Herb failure and reports nothing, so diagnostics stay on' do
    allow(Herb).to receive(:parse).and_raise(RuntimeError, 'boom')
    allow(Solargraph.logger).to receive(:warn)

    expect(diagnose("<div>\n")).to eq []
    expect(Solargraph.logger).to have_received(:warn).with(/show\.html\.erb.*RuntimeError: boom/)
  end
end
