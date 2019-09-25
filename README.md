# SftpWrapper

The wrapper for sftp CLI.

_**NOTE: This is an experimental wrapper to download faster than [net-sftp](https://github.com/net-ssh/net-sftp).**_

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sftp_wrapper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sftp_wrapper

## Usage

```ruby
require 'sftp_wrapper'

SftpWrapper::OpenSSH.new('localhost', 2222, 'test', 'pass').download('/upload/file', './file')
SftpWrapper::Curl.new('localhost', 2222, 'test', 'pass', curl_args: ['--silent', '--insecure']).download('/upload/file', './file')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/koshigoe/sftp_wrapper.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
