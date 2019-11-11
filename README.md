# Telemetry

Telemetry is a ruby port of the Erlang BEAM library `telemetry`. The purpose of
this library is to provide a generalized notification/subscriber library for use
with other Ruby libraries in collecting "stats" or bits of `telemetry` information
gathered by instrumenting that code.

This should function similar to `ActiveSupport::Notifications`, but without Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'telemetry-ruby', require: 'telemetry'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install telemetry-ruby

## Dependencies

Telemetry has one major dependency: `concurrent-ruby`. This is to provide
thread-safe access to a map of all attached handlers.

## Usage

### Subscribing

As a handler (subscriber) of events, you'll want to start by writing your handler:

```ruby
class YourHandler
  def self.some_function(key, measurements, metadata, config)
    # ...
  end
end
```

Next, you can attach this handler with a unique name, for the configured event keys.

The event keys will be defined by the instrumented code, either yours or from a
library you're using.

Extra information in the third argument will be passed to your handler function.

```ruby
Telemetry.attach('unique-name-for-your-handler', [:keys, :for, :event], {extra: 'info', you: 'provide'}, &YourHandler.method(:some_function))

# or with a block
Telemetry.attach('unique-name-for-your-handler', [:keys, :for, :event], {extra: 'info', you: 'provide'}) do |key, measurements, metadata, config|
end
```

Any method or block you provide should be thread safe, as we cannot guarantee that
multiple instrumented threads will not call `Telemetry.execute` at the same time.

### Instrumenting

```ruby
Telemetry.execute(
  [:keys, :for, :event],
  {hash: 'of', measurement: 'data'},
  {event: 'metadata'}
)

# or, with a block, which will add timing to measurements
Telemetry.execute(
  [:keys, :for, :event],
  {hash: 'of', measurement: 'data'},
  {event: 'metadata'}
) do
  # Do some stuff here
end
```

#### Measurements

Should be used to contain analytical or statistical values such as timing or counts.

#### Metadata

Should be used to provide contextual information about the call such as user id,
route, path, etc.

#### Timing with blocks

Calling `Telemetry.execute` with a block will add the `:timing` key to the
`measurements` hash. It will not overwrite an existing `:timing` key used in the
call to `execute`.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tpitale/telemetry-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Telemetry project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tpitale/telemetry-ruby/blob/master/CODE_OF_CONDUCT.md).
