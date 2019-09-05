# frozen_string_literal: true

require 'uri'
require 'erb'
require 'open3'

module SftpWrapper
  # The wrapper for curl.
  class Curl
    attr_reader :host, :port, :username, :password, :curl_command, :curl_options

    # lookup table of curl errors.
    CURL_ERRORS = {
      # Failed to connect to host.
      7 => SftpWrapper::Errors::ConnectionError,
      # The user name, password, or similar was not accepted and curl failed to log in.
      67 => SftpWrapper::Errors::AuthenticationFailure,
    }.freeze

    # Initialize SFTP wrapper.
    #
    # @param host [String] host address of SFTP server
    # @param port [Integer] port number of SFTP server
    # @param username [String] user name of SFTP server
    # @param password [String] password of SFTP server
    # @param curl_options [Hash] curl options. (e.g. --connect-timeout 1 => connect_timeout: 1)
    #
    def initialize(host, port, username, password, curl_options = {})
      @host = host
      @port = port
      @username = username
      @password = password
      @curl_command = curl_options.key?(:command_path) ? curl_options.delete(:command_path) : 'curl'
      @curl_options = curl_options
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
      cmd = %W[#{curl_command} -s --insecure -o #{destination}] + build_curl_options + [uri.to_s]

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
      cmd = %W[#{curl_command} -s --insecure -T #{source}] + build_curl_options + [uri.to_s]

      execute(*cmd)
    end

    private

    def build_curl_options
      curl_options.map { |k, v| ["--#{k.tr('_', '-')}", v] }.flatten
    end

    def execute(*cmd)
      _, stderr, status = Open3.capture3(*cmd)

      return if status.success?

      exception_class = CURL_ERRORS[status.exitstatus] || SftpWrapper::Errors::CommandError

      raise exception_class, "exit status #{status.exitstatus}: #{stderr}"
    end
  end
end
