# Solargraph::Herb - A [Solargraph](https://solargraph.org/) plugin for Ruby in Rails ERB views

> [!WARNING]
> Work in progress: the plugin only loads so far and adds no behaviour yet. It depends on Solargraph changes that are
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

Add the plugin to `.solargraph.yml`, and include the views next to the Ruby files:

```yaml
include:
  - "**/*.rb"
  - "app/views/**/*.erb"
plugins:
  - solargraph-herb
```

Your editor must send ERB buffers to Solargraph too, e.g. in Neovim:

```lua
vim.lsp.config('solargraph', { filetypes = { 'ruby', 'eruby' } })
```

## Development

```sh
bundle install
bundle exec rake # specs and RuboCop
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
