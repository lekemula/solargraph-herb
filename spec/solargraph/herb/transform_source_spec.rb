# frozen_string_literal: true

RSpec.describe Solargraph::Herb::Convention, '#transform_source' do
  subject(:convention) { described_class.new }

  let(:view) { '/app/app/views/posts/show.html.erb' }

  # @param erb [String]
  # @param filename [String]
  # @return [String, nil]
  def shadow(erb, filename = view)
    convention.transform_source(filename, erb)
  end

  it 'keeps the Ruby of an output tag at its column' do
    expect(shadow('<p><%= post.title %></p>')).to eq '       post.title  ;    '
  end

  it 'ends each statement tag with a semicolon, so tags on one line parse' do
    expect(shadow('<% x = 1 %><%= x %>')).to eq '   x = 1  ;    x  ;'
  end

  it 'blanks comments' do
    expect(shadow('<p><%# a comment %></p>')).to eq ' ' * 23
  end

  it 'keeps strict locals out of the Ruby' do
    expect(shadow("<%# locals: (post:) %>\n<%= post %>")).to eq "#{" " * 22}\n    post  ;"
  end

  it 'handles whitespace-trimming tags' do
    expect(shadow("<%- if a -%>\n  <%= b %>\n<%- end -%>")).to eq "    if a  ; \n      b  ;\n    end  ; "
  end

  it 'handles unescaped output tags' do
    expect(shadow('<%== raw @footer %>')).to eq '     raw @footer  ;'
  end

  it 'keeps the lines of a multi-line tag' do
    erb = "<%= render partial: 'p',\n           locals: { a: 1 } %>"

    expect(shadow(erb)).to eq "    render partial: 'p',\n           locals: { a: 1 }  ;"
  end

  it 'joins a block opened in one tag and closed in another into valid Ruby' do
    erb = "<% @posts.each do |post| %>\n  <p><%= post.title %></p>\n<% end %>"

    expect(shadow(erb)).to eq "   @posts.each do |post|  ;\n         post.title  ;    \n   end  ;"
    expect(Prism.parse(shadow(erb)).errors).to be_empty
  end

  it 'keeps the line count and every line length of the view' do
    erb = File.read(File.expand_path('../../fixtures/views_project/app/views/posts/show.html.erb', __dir__))

    expect(shadow(erb).lines.map(&:length)).to eq erb.lines.map(&:length)
  end

  context 'when Herb breaks the line lengths' do
    before { allow(Herb).to receive(:extract_ruby).and_return("x\n") }

    it 'returns a blank shadow and logs it' do
      expect(Solargraph.logger).to receive(:warn).with(/line lengths/)

      expect(shadow("<%= a %>\n<%= b %>")).to eq "        \n        "
    end
  end

  context 'when Herb raises' do
    before { allow(Herb).to receive(:extract_ruby).and_raise(RuntimeError, 'boom') }

    it 'returns a blank shadow and logs it' do
      expect(Solargraph.logger).to receive(:warn).with(/boom/)

      expect(shadow("<p>\r\n<%= a %>")).to eq "   \r\n        "
    end

    it 'blanks a view with invalid UTF-8' do
      allow(Solargraph.logger).to receive(:warn)

      expect(shadow("<p>caf\xC3</p>\n<%= a %>")).to eq "#{" " * 11}\n        "
    end
  end

  it 'keeps the Ruby at its character column after multibyte text' do
    erb = '<p>Café — <%= post_title(@post) %></p>'

    expect(shadow(erb)).to eq "#{" " * 14}post_title(@post)  ;    "
    expect(shadow(erb).index('post_title')).to eq erb.index('post_title')
  end

  it 'keeps multibyte text inside Ruby' do
    expect(shadow("<%= t('Grüße') %> ·")).to eq "    t('Grüße')  ;  "
  end

  it 'leaves ERB outside app/views alone' do
    expect(shadow('<%= 1 %>', '/app/app/mailers/welcome.html.erb')).to be_nil
  end

  it 'leaves other files in app/views alone' do
    expect(shadow('<%= 1 %>', '/app/app/views/posts/show.json.jbuilder')).to be_nil
  end
end
