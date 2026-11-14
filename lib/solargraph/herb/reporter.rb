# frozen_string_literal: true

module Solargraph
  module Herb
    # Reports Herb's parse errors in ERB views, at their positions in the view.
    #
    # Herb's Ruby syntax errors are left out: they are Ruby diagnostics, Solargraph's own to report on the Shadow
    # Source, which keeps the view's positions.
    class Reporter < Solargraph::Diagnostics::Base
      # @param source [Solargraph::Source]
      # @param _api_map [Solargraph::ApiMap]
      # @return [Array<Hash>]
      def diagnose(source, _api_map)
        return [] unless source.transformed? && Convention.view?(source.filename)

        ::Herb.parse(source.original_code).errors.filter_map do |error|
          next if error.is_a?(::Herb::Errors::RubyParseError)

          diagnostic(error.location, error.error_name, error.message)
        end
      rescue StandardError => e
        # Raising would end in a DiagnosticsError, which turns diagnostics off for the whole session
        Solargraph.logger.warn "[solargraph-herb] Could not diagnose #{source.filename}: #{e.class}: #{e.message}"
        []
      end

      private

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
