# frozen_string_literal: true

module SftpWrapper
  # Exceptions.
  module Errors
    # Base class for exceptions.
    class Error < StandardError; end

    # Can't establish connection.
    class ConnectionError < Error; end

    # Can't authenticate user.
    class AuthenticationFailure < Error; end

    # Command timed out.
    class TimeoutError < Error; end

    # Command failed.
    class CommandError < Error; end

    # Resource does not exist.
    class ResourceNotExist < Error; end
  end
end
