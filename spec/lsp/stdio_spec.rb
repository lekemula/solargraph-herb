# frozen_string_literal: true

require_relative '../../script/lsp_probe'

# Runs the real `solargraph stdio` server over the fixture project, which loads the plugin through its own
# .solargraph.yml as a user's project does.
RSpec.describe 'solargraph stdio with the plugin', :lsp do
  root = File.expand_path('../fixtures/views_project', __dir__)
  view = 'app/views/posts/show.html.erb'
  broken_view = 'app/views/posts/_byline.html.erb'

  before(:all) do
    @probe = LspProbe.start(
      root,
      env: {
        'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__),
        'SOLARGRAPH_GLOBAL_CONFIG' => File.join(root, 'no-global-config.yml')
      }
    )
    @probe.open(view)
  end

  after(:all) { @probe&.stop }

  it 'reports no diagnostics on the view' do
    expect(@probe.diagnostics(view)).to eq []
  end

  it 'reports the Herb parse error of a broken view at its range' do
    @probe.open(broken_view)

    expect(@probe.diagnostics(broken_view)).to eq [
      {
        'range' => { 'start' => { 'line' => 0, 'character' => 25 }, 'end' => { 'line' => 0, 'character' => 31 } },
        'severity' => 1,
        'source' => 'herb',
        'code' => 'MissingClosingTagError',
        'message' => "Opening tag `<span>` at (1:26) doesn't have a matching closing tag `</span>` in the same scope."
      }
    ]
  end

  it 'formats the view without edits' do
    expect(@probe.formatting(view)).to eq []
  end

  it 'logs no plugin failure, exception or backtrace' do
    @probe.hover(view, 1, 16)
    expect(@probe.stderr).not_to match(/Failed to load plugin|Error|Exception|\.rb:\d+:in /)
  end
end
