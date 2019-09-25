# frozen_string_literal: true

require 'uri'
require 'erb'
require 'open3'

module SftpWrapper
  # The wrapper for curl.
  class Curl
    attr_reader :host, :port, :username, :password, :curl_path, :curl_args

    # lookup table of curl errors.
    CURL_ERRORS = {
      # URL malformed. The syntax was not correct.
      3 => SftpWrapper::Errors::ConnectionError,
      # Couldn't resolve proxy. The given proxy host could not be resolved.
      5 => SftpWrapper::Errors::ConnectionError,
      # Couldn't resolve host. The given remote host was not resolved.
      6 => SftpWrapper::Errors::ConnectionError,
      # Failed to connect to host.
      7 => SftpWrapper::Errors::ConnectionError,
      # The user name, password, or similar was not accepted and curl failed to log in.
      67 => SftpWrapper::Errors::AuthenticationFailure,
      # The resource referenced in the URL does not exist.
      78 => SftpWrapper::Errors::ResourceNotExist,
    }.freeze

    # Initialize SFTP wrapper.
    #
    # @param host [String] host address of SFTP server
    # @param port [Integer] port number of SFTP server
    # @param username [String] user name of SFTP server
    # @param password [String] password of SFTP server
    # @param options [Hash] curl options.
    # @option options [String] :curl_path path of `curl` command.
    # @option options [Array<String>] :curl_args command line arguments of `curl`.
    #
    def initialize(host, port, username, password, options = {})
      @host = host
      @port = port
      @username = username
      @password = password
      @curl_path = options[:curl_path] || 'curl'
      @curl_args = options[:curl_args] || []
    end

    # Get remote file.
    #
    # @param source [String] source file path
    # @param destination [String] destination path
    # @raise [SftpWrapper::Errors::ConnectionError]
    # @raise [SftpWrapper::Errors::AuthenticationFailure]
    # @raise [SftpWrapper::Errors::CommandError]
    #
    def download(source, destination)
      userinfo = [username, password].map(&ERB::Util.method(:url_encode)).join(':')
      uri = URI::Generic.build(scheme: 'sftp', userinfo: userinfo, host: host, port: port, path: source)
      cmd = %W[#{curl_path} -o #{destination}] + curl_args + [uri.to_s]

      execute(*cmd)
    end

    # Put local file.
    #
    # @param source [String] source file path
    # @param destination [String] destination path
    # @raise [SftpWrapper::Errors::ConnectionError]
    # @raise [SftpWrapper::Errors::AuthenticationFailure]
    # @raise [SftpWrapper::Errors::CommandError]
    #
    def upload(source, destination)
      userinfo = [username, password].map(&ERB::Util.method(:url_encode)).join(':')
      uri = URI::Generic.build(scheme: 'sftp', userinfo: userinfo, host: host, port: port, path: destination)
      cmd = %W[#{curl_path} -T #{source}] + curl_args + [uri.to_s]

      execute(*cmd)
    end

    private

    def execute(*cmd)
      _, stderr, status = Open3.capture3(*cmd)

      return if status.success?

      exception_class = CURL_ERRORS[status.exitstatus] || SftpWrapper::Errors::CommandError

      raise exception_class, "exit status #{status.exitstatus}: #{stderr}"
    end
  end
end
