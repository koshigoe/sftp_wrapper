# frozen_string_literal: true

require 'benchmark'
require 'net/sftp'
require 'sftp_wrapper'
require 'tempfile'

data = ' ' * (1024 * 1024 * 100)

ssh_options = {
  auth_methods: %w[password],
  config: false,
  non_interactive: true,
  user_known_hosts_file: IO::NULL,
  verify_host_key: :never,
  port: 2222,
  password: 'pass',
}

Tempfile.create('temp') do |temp|
  temp.write(data)
  temp.close

  Net::SFTP.start('localhost', 'test', ssh_options) do |session|
    session.upload!(temp.path, '/upload/benchmark-download')
  end
end

Benchmark.bm(16) do |x|
  x.report('OpenSSH sftp CLI') do
    Tempfile.create('temp') do |temp|
      temp.close

      wrapper = SftpWrapper::OpenSSH.new('localhost', 2222, 'test', 'pass')
      wrapper.download('/upload/benchmark-download', 'downloaded')
    end
  end

  x.report('curl CLI') do
    Tempfile.create('temp') do |temp|
      temp.close

      wrapper = SftpWrapper::Curl.new('localhost', 2222, 'test', 'pass')
      wrapper.download('/upload/benchmark-download', 'downloaded')
    end
  end

  x.report('net-sftp') do
    Tempfile.create('temp') do |temp|
      temp.close

      Net::SFTP.start('localhost', 'test', ssh_options) do |session|
        session.download!('/upload/benchmark-download', temp.path)
      end
    end
  end
end

__END__

$ ruby -v
ruby 2.6.4p104 (2019-08-28 revision 67798) [x86_64-linux]
$ bundle exec ruby benchmark_download.rb
                       user     system      total        real
OpenSSH sftp CLI   0.000382   0.003365   0.003747 (  3.044737)
curl CLI           0.015933   0.000000   2.115820 (  3.375170)
net-sftp           6.210004   0.744365   6.954369 ( 10.792968)
