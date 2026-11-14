# frozen_string_literal: true

require 'solargraph'
require 'herb'

require_relative 'herb/version'
require_relative 'herb/convention'
require_relative 'herb/reporter'

Solargraph::Convention.register Solargraph::Herb::Convention
Solargraph::Diagnostics.register 'herb', Solargraph::Herb::Reporter
