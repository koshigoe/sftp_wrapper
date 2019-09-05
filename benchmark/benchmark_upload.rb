# frozen_string_literal: true

require 'benchmark'
require 'net/sftp'
require 'sftp_wrapper'
require 'tempfile'

data = ' ' * (1024 * 1024 * 100)

Tempfile.create('temp') do |temp|
  temp.write(data)
  temp.close

  Benchmark.bm(16) do |x|
    x.report('OpenSSH sftp CLI') do
      wrapper = SftpWrapper::OpenSSH.new('localhost', 2222, 'test', 'pass')
      wrapper.upload(temp.path, '/upload/benchmark-download')
    end

    x.report('curl CLI') do
      wrapper = SftpWrapper::Curl.new('localhost', 2222, 'test', 'pass')
      wrapper.upload(temp.path, '/upload/benchmark-download')
    end

    x.report('net-sftp') do
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
        session.upload!(temp.path, '/upload/benchmark-upload')
      end
    end
  end
end

__END__

$ ruby -v
ruby 2.6.4p104 (2019-08-28 revision 67798) [x86_64-linux]
$ bundle exec ruby benchmark_upload.rb
                       user     system      total        real
OpenSSH sftp CLI   0.004058   0.000321   0.004379 (  1.749079)
curl CLI           0.007233   0.003560   0.676544 (  2.184746)
net-sftp           0.852571   0.099383   0.951954 (  2.413606)
