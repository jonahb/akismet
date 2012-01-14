module Akismet

  class Error < StandardError

    UNKNOWN = 1
    INVALID_API_KEY = 2

    # An error code corresponding to a constant in Akismet::Error.
    # @return [Integer]
    attr_reader :code

    # @param [String] message
    #   A human-readable description of the error.
    # @param [Integer] code
    #   An error code corresponding to a constant in Akismet::Error.
    #
    def initialize( code, message = nil )
      super( message )
      @code = code
    end
  end

end