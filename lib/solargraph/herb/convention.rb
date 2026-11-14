# frozen_string_literal: true

module Solargraph
  module Herb
    # Maps the Ruby in ERB views.
    #
    # An ERB view becomes its Shadow Source: the Ruby of its tags at their positions in the view, with everything else
    # blanked, so it keeps the view's line count and every line's character length.
    class Convention < Solargraph::Convention::Base
      # @param filename [String]
      # @return [Boolean] whether the plugin maps the file, an ERB template under app/views/
      def self.view?(filename)
        filename.end_with?('.erb') && filename.include?('app/views/')
      end

      # @param filename [String]
      # @param code [String]
      # @return [String, nil] the Shadow Source of an ERB view
      def transform_source(filename, code)
        return unless Convention.view?(filename)

        ruby = character_aligned(code, ::Herb.extract_ruby(code, preserve_positions: true, semicolons: true))
        return ruby if ruby.lines.map(&:length) == code.lines.map(&:length)

        blank(filename, code, 'Herb changed the line lengths')
      rescue StandardError => e
        blank(filename, code, "#{e.class}: #{e.message}")
      end

      private

      # Herb keeps byte offsets, so it blanks a multibyte character into one space per byte, while Solargraph
      # positions count characters. Each blanked character becomes a single space.
      #
      # @param code [String]
      # @param ruby [String] Herb's Ruby, byte-aligned with the code
      # @return [String] the Ruby, character-aligned with the code
      def character_aligned(code, ruby)
        offset = 0
        code.each_char.map do |char|
          bytes = ruby.byteslice(offset, char.bytesize)
          offset += char.bytesize
          bytes == char || char.bytesize == 1 ? bytes : ' '
        end.join
      end

      # A view whose Ruby could not be extracted still maps as an empty Shadow Source rather than as Ruby.
      #
      # @param filename [String]
      # @param code [String]
      # @param reason [String]
      # @return [String] the code with every character but line breaks blanked
      def blank(filename, code, reason)
        Solargraph.logger.warn "[solargraph-herb] Blanked #{filename}: #{reason}"
        code.each_char.map { |char| "\r\n".include?(char) ? char : ' ' }.join
      end
    end
  end
end
