require 'rspec/expectations'

RSpec::Matchers.define :eq_with_telemetry do |expected_message, telemetry_options|
  telemetry_options ||= {}

  # Appends the telemetry metrics to the metrics string passed as 'text'
  def add_telemetry(text,
                    metrics: 1,
                    events: 0,
                    service_checks: 0,
                    bytes_sent: 0,
                    bytes_dropped: 0,
                    bytes_dropped_queue: 0,
                    bytes_dropped_writer: 0,
                    packets_sent: 0,
                    packets_dropped: 0,
                    packets_dropped_queue: 0,
                    packets_dropped_writer: 0,
                    transport: 'udp')
    [
      text,
      "dogstatsd.client.metrics;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{metrics}",
      "dogstatsd.client.events;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{events}",
      "dogstatsd.client.service_checks;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{service_checks}",
      "dogstatsd.client.bytes_sent;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{bytes_sent}",
      "dogstatsd.client.bytes_dropped;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{bytes_dropped}",
      "dogstatsd.client.bytes_dropped_queue;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{bytes_dropped_queue}",
      "dogstatsd.client.bytes_dropped_writer;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{bytes_dropped_writer}",
      "dogstatsd.client.packets_sent;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{packets_sent}",
      "dogstatsd.client.packets_dropped;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{packets_dropped}",
      "dogstatsd.client.packets_dropped_queue;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{packets_dropped_queue}",
      "dogstatsd.client.packets_dropped_writer;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{packets_dropped_writer}",
    ].join("\n")
  end

  define_method(:expected) do
    @expected ||= add_telemetry(expected_message, **telemetry_options)
  end

  match do |actual|
    actual == expected
  end

  diffable
end
