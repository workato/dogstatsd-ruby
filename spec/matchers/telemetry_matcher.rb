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
      "telemetry_metrics;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{metrics}",
      "telemetry_events;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{events}",
      "telemetry_service_checks;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{service_checks}",
      "telemetry_bytes_sent;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{bytes_sent}",
      "telemetry_bytes_dropped;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{bytes_dropped}",
      "telemetry_bytes_dropped_queue;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{bytes_dropped_queue}",
      "telemetry_bytes_dropped_writer;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{bytes_dropped_writer}",
      "telemetry_packets_sent;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{packets_sent}",
      "telemetry_packets_dropped;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{packets_dropped}",
      "telemetry_packets_dropped_queue;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{packets_dropped_queue}",
      "telemetry_packets_dropped_writer;client=ruby;client_version=#{Datadog::Statsd::VERSION};client_transport=#{transport} #{packets_dropped_writer}",
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
