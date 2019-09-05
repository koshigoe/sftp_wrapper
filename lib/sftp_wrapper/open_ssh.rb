# frozen_string_literal: true

require 'pty'
require 'expect'
require 'shellwords'

module SftpWrapper
  # The wrapper for OpenSSH's sftp command.
  class OpenSSH
    attr_reader :host,
                :port,
                :username,
                :password,
                :ssh_options,
                :ssh_config,
                :open_timeout,
                :read_timeout,
                :command_timeout,
                :debug

    # Default value of open timeout.
    DEFAULT_OPEN_TIMEOUT = 10
    # Default value of read timeout.
    DEFAULT_READ_TIMEOUT = 10
    # Default value of command timeout.
    DEFAULT_COMMAND_TIMEOUT = 9_999_999
    # Default value of ssh options
    DEFAULT_SSH_OPTIONS = {
      PasswordAuthentication: 'yes',
      PreferredAuthentications: 'password',
      PubkeyAuthentication: 'no',
      NumberOfPasswordPrompts: 1,
      StrictHostKeyChecking: 'no',
      UserKnownHostsFile: '/dev/null',
      TCPKeepAlive: 'yes',
      ServerAliveInterval: 60,
      ServerAliveCountMax: 3,
    }.freeze
    # Default value of ssh config file path.
    DEFAULT_SSH_CONFIG = '/dev/null'
    # pattern of password prompt.
    PASSWORD_PROMPT_RE = / password: /.freeze
    # sftp prompt.
    SFTP_PROMPT = 'sftp> '
    # pattern of sftp prompt.
    SFTP_PROMPT_RE = /^#{SFTP_PROMPT}/.freeze

    # Initialize SFTP wrapper.
    #
    # @param host [String] host address of SFTP server
    # @param port [Integer] port number of SFTP server
    # @param username [String] user name of SFTP server
    # @param password [String] password of SFTP server
    # @param ssh_options [Hash] SSH options (set as -o options)
    # @param ssh_config [String] path of SSH config file (set as -F option unless nil)
    # @param open_timeout [Integer, Float]
    # @param read_timeout [Integer, Float]
    # @param command_timeout [Integer, Float]
    # @param debug [Boolean]
    #
    # rubocop:disable Metrics/ParameterLists
    def initialize(host, port, username, password,
                   ssh_options: {},
                   ssh_config: DEFAULT_SSH_CONFIG,
                   open_timeout: DEFAULT_OPEN_TIMEOUT,
                   read_timeout: DEFAULT_READ_TIMEOUT,
                   command_timeout: DEFAULT_COMMAND_TIMEOUT,
                   debug: false)
      @host = host
      @port = port
      @username = username
      @password = password
      @ssh_options = DEFAULT_SSH_OPTIONS.merge(ssh_options)
      @ssh_config = ssh_config
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @command_timeout = command_timeout
      @debug = debug
    end
    # rubocop:enable Metrics/ParameterLists

    # Get remote file.
    #
    # @param source [String] source file path
    # @param destination [String] destination path
    # @raise [SftpWrapper::Errors::ConnectionError]
    # @raise [SftpWrapper::Errors::AuthenticationFailure]
    # @raise [SftpWrapper::Errors::TimeoutError]
    # @raise [SftpWrapper::Errors::CommandError]
    #
    def download(source, destination)
      execute(%W[get #{source} #{destination}].shelljoin)
    end

    # Put local file.
    #
    # @param source [String] source file path
    # @param destination [String] destination path
    # @raise [SftpWrapper::Errors::ConnectionError]
    # @raise [SftpWrapper::Errors::AuthenticationFailure]
    # @raise [SftpWrapper::Errors::TimeoutError]
    # @raise [SftpWrapper::Errors::CommandError]
    #
    def upload(source, destination)
      execute(%W[put #{source} #{destination}].shelljoin)
    end

    private

    # Execute sftp command.
    #
    # @param command [String] SFTP command
    # @raise [SftpWrapper::Errors::ConnectionError]
    # @raise [SftpWrapper::Errors::AuthenticationFailure]
    # @raise [SftpWrapper::Errors::TimeoutError]
    # @raise [SftpWrapper::Errors::CommandError]
    #
    def execute(command) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      cli = %w[sftp] + build_cli_args + [host]
      PTY.getpty(cli.shelljoin) do |r, w, _pid|
        w.sync = true

        unless safe_expect(r, PASSWORD_PROMPT_RE, open_timeout)
          raise SftpWrapper::Errors::ConnectionError, 'connection error.'
        end

        w.puts(password)

        unless safe_expect(r, SFTP_PROMPT_RE, read_timeout)
          raise SftpWrapper::Errors::AuthenticationFailure, 'authentication failure'
        end

        w.puts(command)

        res = safe_expect(r, SFTP_PROMPT_RE, command_timeout)
        raise SftpWrapper::Errors::TimeoutError, 'command timed out' unless res

        skip = command.bytesize + 2
        error_message = res[0].byteslice(skip..-1).chomp.sub(/#{SFTP_PROMPT}\z/, '').chomp
        raise SftpWrapper::Errors::CommandError, error_message unless error_message.empty?

        w.puts('quit')
      end
    end

    def build_cli_args
      args = []
      args << '-q'
      args += %W[-F #{ssh_config}] if ssh_config
      args += %W[-P #{port} -o User=#{username}]
      args += ssh_options.map { |k, v| %W[-o #{k}=#{v}] }.flatten
      args
    end

    # @see https://github.com/ruby/ruby/blob/13b692200dba1056fa9033f2c64c43453f6d6a98/ext/pty/pty.c#L716-L723
    def safe_expect(io, pattern, timeout)
      expect_verbose = $expect_verbose # rubocop:disable Style/GlobalVars
      $expect_verbose = debug # rubocop:disable Style/GlobalVars
      io.expect(pattern, timeout)
    rescue Errno::EIO
      nil
    ensure
      $expect_verbose = expect_verbose # rubocop:disable Style/GlobalVars
    end
  end
end
