# frozen_string_literal: true

# The wrapper for SFTP client CLI.
module SftpWrapper
  autoload :Errors, 'sftp_wrapper/errors'
  autoload :OpenSSH, 'sftp_wrapper/open_ssh'
  autoload :Curl, 'sftp_wrapper/curl'
end
