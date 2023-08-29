require "spec_helper"

describe "Delayed serialization mode" do
  it "defers serialization to message buffer" do
    buffer = double(Datadog::Statsd::MessageBuffer)
    # expects an Array is passed and not a String
    expect(buffer)
      .to receive(:add)
      .with([["boo", 1, "c"], {tags: nil, sample_rate: 1}])
    # and then expect no more adds!
    expect(buffer).to receive(:add).exactly(0).times
    expect(buffer)
      .to receive(:flush)

    allow(Datadog::Statsd::MessageBuffer).to receive(:new).and_return(buffer)
    dogstats = Datadog::Statsd.new("localhost", 1234, delay_serialization: true, transport_type: :udp)

    dogstats.increment("boo")
    dogstats.flush(sync: true)
  end

  it "serializes messages normally" do
    socket = FakeUDPSocket.new(copy_message: true)
    allow(UDPSocket).to receive(:new).and_return(socket)
    dogstats = Datadog::Statsd.new("localhost", 1234, delay_serialization: true, transport_type: :udp)

    dogstats.increment("boo")
    dogstats.increment("oob", tags: {tag1: "val1"})
    dogstats.increment("pow", tags: {tag1: "val1"}, sample_rate: 2)
    dogstats.flush(sync: true)

    expect(socket.recv[0]).to eq([
      "boo 1",
      "oob;tag1=val1 1",
      "pow;tag1=val1 1"
    ].join("\n"))
  end
end
