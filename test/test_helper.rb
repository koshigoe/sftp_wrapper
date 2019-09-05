# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'sftp_wrapper'

require 'minitest/autorun'
require 'tempfile'
require 'net/sftp'

CURL_COMMAND_PATH = ENV['CURL_PREFIX'] ? File.join(ENV['CURL_PREFIX'], 'curl') : 'curl'
