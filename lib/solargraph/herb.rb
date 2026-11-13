# frozen_string_literal: true

require 'solargraph'
require 'herb'

require_relative 'herb/version'
require_relative 'herb/convention'

Solargraph::Convention.register Solargraph::Herb::Convention
