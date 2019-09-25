# frozen_string_literal: true

require 'test_helper'

class SftpWrapperCurlTest < Minitest::Test
  describe '#download' do
    describe 'SftpWrapper::Errors::ConnectionError' do
      it 'raise exception' do
        wrapper = SftpWrapper::Curl.new(
          'localhost',
          2223,
          'test',
          'pass',
          curl_path: CURL_COMMAND_PATH,
          curl_args: %w[-s --insecure]
        )
        Tempfile.create('temp') do |temp|
          temp.close
          e = assert_raises(SftpWrapper::Errors::ConnectionError) do
            wrapper.download('/upload/file', temp.path)
          end
          assert_match(/\Aexit status \d+: .*/m, e.message)
        end
      end
    end

    describe 'SftpWrapper::Errors::AuthenticationFailure' do
      it 'raise exception' do
        wrapper = SftpWrapper::Curl.new(
          'localhost',
          2222,
          'test',
          'passs',
          curl_path: CURL_COMMAND_PATH,
          curl_args: %w[-s --insecure]
        )
        Tempfile.create('temp') do |temp|
          temp.close
          e = assert_raises(SftpWrapper::Errors::AuthenticationFailure) do
            wrapper.download('/upload/file', temp.path)
          end
          assert_match(/\Aexit status \d+: .*/m, e.message)
        end
      end
    end

    describe 'SftpWrapper::Errors::CommandError' do
      it 'raise exception' do
        wrapper = SftpWrapper::Curl.new(
          'localhost',
          2222,
          'test',
          'pass',
          curl_path: CURL_COMMAND_PATH,
          curl_args: %w[-s --insecure]
        )
        Tempfile.create('temp') do |temp|
          temp.close
          e = assert_raises(SftpWrapper::Errors::CommandError) do
            wrapper.download('/notfound', temp.path)
          end
          assert_match(/\Aexit status \d+: .*/m, e.message)
        end
      end
    end

    describe 'Success' do
      it 'download file' do
        ssh_options = {
          auth_methods: %w[password],
          config: false,
          non_interactive: true,
          user_known_hosts_file: IO::NULL,
          verify_host_key: :never,
          port: 2222,
          password: 'pass',
        }
        Net::SFTP.start('localhost', 'test', ssh_options) do |session|
          session.open!('/upload/file', 'w') do |res|
            raise unless res.ok?

            session.write!(res[:handle], 0, 'downloaded')
          end
        end

        wrapper = SftpWrapper::Curl.new(
          'localhost',
          2222,
          'test',
          'pass',
          curl_path: CURL_COMMAND_PATH,
          curl_args: %w[-s --insecure]
        )
        Tempfile.create('temp') do |temp|
          temp.close
          wrapper.download('/upload/file', temp.path)
          assert_equal File.read(temp.path), 'downloaded'
        end
      end
    end
  end

  describe '#upload' do
    describe 'SftpWrapper::Errors::ConnectionError' do
      it 'raise exception' do
        wrapper = SftpWrapper::Curl.new(
          'localhost',
          2223,
          'test',
          'pass',
          curl_path: CURL_COMMAND_PATH,
          curl_args: %w[-s --insecure]
        )
        Tempfile.create('temp') do |temp|
          temp.close
          e = assert_raises(SftpWrapper::Errors::ConnectionError) do
            wrapper.upload(temp.path, '/upload/file')
          end
          assert_match(/\Aexit status \d+: .*/m, e.message)
        end
      end
    end

    describe 'SftpWrapper::Errors::AuthenticationFailure' do
      it 'raise exception' do
        wrapper = SftpWrapper::Curl.new(
          'localhost',
          2222,
          'test',
          'passs',
          curl_path: CURL_COMMAND_PATH,
          curl_args: %w[-s --insecure]
        )
        Tempfile.create('temp') do |temp|
          temp.close
          e = assert_raises(SftpWrapper::Errors::AuthenticationFailure) do
            wrapper.upload(temp.path, '/upload/file')
          end
          assert_match(/\Aexit status \d+: .*/m, e.message)
        end
      end
    end

    describe 'SftpWrapper::Errors::CommandError' do
      it 'raise exception' do
        wrapper = SftpWrapper::Curl.new(
          'localhost',
          2222,
          'test',
          'pass',
          curl_path: CURL_COMMAND_PATH,
          curl_args: %w[-s --insecure]
        )

        e = assert_raises(SftpWrapper::Errors::CommandError) do
          wrapper.upload('notfound', '/upload/file')
        end
        assert_match(/\Aexit status \d+: .*/m, e.message)
      end
    end

    describe 'Success' do
      it 'upload file' do
        ssh_options = {
          auth_methods: %w[password],
          config: false,
          non_interactive: true,
          user_known_hosts_file: IO::NULL,
          verify_host_key: :never,
          port: 2222,
          password: 'pass',
        }

        Net::SFTP.start('localhost', 'test', ssh_options) do |session|
          begin
            session.remove!('/upload/file')
          rescue Net::SFTP::StatusException
            nil
          end
        end

        wrapper = SftpWrapper::Curl.new(
          'localhost',
          2222,
          'test',
          'pass',
          curl_path: CURL_COMMAND_PATH,
          curl_args: %w[-s --insecure]
        )
        Tempfile.create('temp') do |temp|
          temp.write('uploaded')
          temp.close

          wrapper.upload(temp.path, '/upload/file')
        end

        Net::SFTP.start('localhost', 'test', ssh_options) do |session|
          assert_equal session.download!('/upload/file', nil), 'uploaded'
        end
      end
    end
  end
end
