# frozen_string_literal: true

require 'herb/engine/validators'

module Solargraph
  module Herb
    # Reports Herb's parse errors in ERB views, at their positions in the view.
    #
    # Ruby syntax errors inside tags are reported once each, at their narrowest range, and only while the template
    # itself parses: a template error explains them. The `herb:nesting` reporter arg adds the HTML nesting checks of
    # Herb's engine, such as a block element inside a `<p>`.
    class Reporter < Solargraph::Diagnostics::Base
      # @param source [Solargraph::Source]
      # @param _api_map [Solargraph::ApiMap]
      # @return [Array<Hash>]
      def diagnose(source, _api_map)
        return [] unless source.transformed? && Convention.view?(source.filename)

        result = ::Herb.parse(source.original_code)
        parse_errors(result) + nesting_errors(result)
      rescue StandardError => e
        # Raising would end in a DiagnosticsError, which turns diagnostics off for the whole session
        Solargraph.logger.warn "[solargraph-herb] Could not diagnose #{source.filename}: #{e.class}: #{e.message}"
        []
      end

      private

      # @param result [::Herb::ParseResult]
      # @return [Array<Hash>]
      def parse_errors(result)
        ruby, template = result.errors.partition { |error| error.is_a?(::Herb::Errors::RubyParseError) }
        # A template error such as an unclosed `<% if %>` breaks the Ruby too, so its Ruby errors are only echoes
        reported = template.empty? ? narrowest_per_message(ruby) : template
        reported.map { |error| diagnostic(error.location, error.error_name, error.message) }
      end

      # Herb can report a Ruby syntax error twice, at the tag and at the token
      #
      # @param errors [Array<::Herb::Errors::RubyParseError>]
      # @return [Array<::Herb::Errors::RubyParseError>]
      def narrowest_per_message(errors)
        errors.group_by(&:message).values.map do |same|
          same.min_by { |error| [error.location.end.line - error.location.start.line, span(error.location)] }
        end
      end

      # @param location [::Herb::Location]
      # @return [Integer]
      def span(location)
        location.end.column - location.start.column
      end

      # @param result [::Herb::ParseResult]
      # @return [Array<Hash>]
      def nesting_errors(result)
        return [] unless args.include?('nesting')

        validator = ::Herb::Engine::Validators::NestingValidator.new(fatal: false)
        result.visit(validator)
        validator.diagnostics.map do |found|
          diagnostic(found.location, found.code, found.message)
        end
      end

      # @param location [::Herb::Location]
      # @param code [String]
      # @param message [String]
      # @return [Hash]
      def diagnostic(location, code, message)
        {
          range: Solargraph::Range.from_to(location.start.line - 1, location.start.column,
                                           location.end.line - 1, location.end.column).to_hash,
          severity: Solargraph::Diagnostics::Severities::ERROR,
          source: 'herb',
          code: code,
          message: message
        }
      end
    end
  end
end
