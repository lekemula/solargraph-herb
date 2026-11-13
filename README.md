# Solargraph::Herb - A [Solargraph](https://solargraph.org/) plugin for Ruby in Rails ERB views

> [!WARNING]
> Work in progress: the plugin maps the Ruby of ERB views, but does not bind it to the view yet, so hover and
> go-to-definition find little in a view so far. It depends on Solargraph changes that are
> not released yet: [castwide/solargraph#1489](https://github.com/castwide/solargraph/pull/1489) and the follow-up
> `herb-source-closure` branch stacked on it. Until they are merged,
> use Solargraph from that branch, as shown below.

This gem aims to bring Solargraph go-to-definition and hover to the Ruby in Rails ERB views, using
[Herb](https://herb-tools.dev) to extract that Ruby from the templates.

## Installation

Add it to your Gemfile. Until those are released, take Solargraph from the `herb-source-closure` branch:

```ruby
group :development do
  gem 'solargraph', github: 'lekemula/solargraph', branch: 'herb-source-closure', require: false
  gem 'solargraph-herb', github: 'lekemula/solargraph-herb', require: false
end
```

Add the plugin to `.solargraph.yml`, and include the views next to the Ruby files. Solargraph only reads `.rb` files by
default, so keep `**/*.rb`:

```yaml
include:
  - "**/*.rb"
  - "app/views/**/*.erb"
plugins:
  - solargraph-herb
```

Your editor must attach Solargraph to ERB buffers (filetype `eruby`) too, e.g. in Neovim:

```lua
vim.lsp.config('solargraph', { filetypes = { 'ruby', 'eruby' } })
```

The plugin maps each `*.erb` file under `app/views/` to its Ruby: the code of its ERB tags at their original
positions, with the HTML, the comments and the tag delimiters blanked. Solargraph does not typecheck or format that
code.

### Keep RuboCop off `.erb` files

Solargraph's `rubocop` reporter lints the Ruby mapped from a view, and reports offenses such as trailing whitespace
where the HTML was blanked, unless your `.rubocop.yml` excludes ERB files:

```yaml
AllCops:
  Exclude:
    - '**/*.erb'
```

RuboCop reads this from the `.rubocop.yml` of the directory Solargraph runs in, usually the project root.

## Development

```sh
bundle install
bundle exec rake # specs and RuboCop
```

The specs in `spec/lsp` (tagged `:lsp`) start a real `solargraph stdio` server over the project in
`spec/fixtures/views_project`, which loads the plugin from its `.solargraph.yml` as a user's project does. To ask a
server what it answers at a position in any project, run
`ruby script/lsp_probe.rb <project_root> <relpath> <line0> <col0>` (`OPEN_FIRST=a.html.erb,b.rb` opens more documents
first).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
