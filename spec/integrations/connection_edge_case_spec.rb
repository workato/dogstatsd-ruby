# frozen_string_literal: true

require 'spec_helper'

describe 'Connection edge cases test' do
  let(:logger) do
    Logger.new(log).tap do |logger|
      logger.level = Logger::INFO
    end
  end
  let(:log) { StringIO.new }

  describe 'when having problems with UDP communication' do
    subject do
      Datadog::Statsd::UDPConnection.new('localhost', 1234, logger: logger)
    end

    before do
      allow(UDPSocket).to receive(:new).and_return(fake_socket, fake_socket_retry)
    end

    let(:fake_socket) do
      instance_double(UDPSocket,
        connect: true,
        send: true)
    end

    let(:fake_socket_retry) do
      instance_double(UDPSocket,
        connect: true,
        send: true)
    end

    context 'when having unknown SocketError (drop strategy)'do
      before do
        allow(fake_socket)
          .to receive(:send)
          .and_raise(SocketError, 'unknown error')
      end

      it 'sends using the first socket' do
        expect(fake_socket)
          .to receive(:send)
          .with('foobar', anything)

        subject.write('foobar')
      end

      it 'ignores the writing failure (message dropped)' do
        expect do
          subject.write('foobar')
        end.not_to raise_error
      end

      it 'does not retry to send message' do
        expect(fake_socket_retry)
          .not_to receive(:send)

        subject.write('foobar')
      end

      it 'logs the error message' do
        subject.write('foobar')

        expect(log.string).to match 'Statsd error: SocketError unknown error'
      end
    end

    context 'when having closed sockets (retry strategy)'do
      before do
        allow(fake_socket)
          .to receive(:send)
          .and_raise(IOError.new('closed stream'))

        allow(fake_socket)
          .to receive(:close)
      end

      context 'when retrying is working' do
        it 'tries with the initial socket' do
          expect(fake_socket)
            .to receive(:send)
            .with('foobar', anything)

          subject.write('foobar')
        end

        it 'close the initial socket' do
          expect(fake_socket)
            .to receive(:close)

          subject.write('foobar')
        end

        it 'retries on the second opened socket' do
          expect(fake_socket_retry)
            .to receive(:send)
            .with('foobar', anything)

          subject.write('foobar')
        end
      end

      context 'when retrying fails' do
        context 'because of an unknown error' do
          before do
            allow(fake_socket_retry)
              .to receive(:send)
              .and_raise(RuntimeError, 'yolo')
          end

          it 'ignores the connection failure' do
            expect do
              subject.write('foobar')
            end.not_to raise_error
          end

          it 'logs the error message' do
            subject.write('foobar')
            expect(log.string).to match 'Statsd error: RuntimeError yolo'
          end
        end

        context 'because of a SocketError' do
          before do
            allow(fake_socket_retry)
              .to receive(:send)
              .and_raise(SocketError, 'yolo')
          end

          it 'ignores the connection failure' do
            expect do
              subject.write('foobar')
            end.not_to raise_error
          end

          it 'logs the error message' do
            subject.write('foobar')
            expect(log.string).to match 'Statsd error: SocketError yolo'
          end
        end
      end
    end

    context 'when having connection refused (retry strategy)' do
      before do
        allow(fake_socket)
          .to receive(:send)
          .and_raise(Errno::ECONNREFUSED.new('closed stream'))

        allow(fake_socket)
          .to receive(:close)
      end

      context 'when retrying is working' do
        it 'tries with the initial socket' do
          expect(fake_socket)
            .to receive(:send)
            .with('foobar', anything)

          subject.write('foobar')
        end

        it 'close the initial socket' do
          expect(fake_socket)
            .to receive(:close)

          subject.write('foobar')
        end

        it 'retries on the second opened socket' do
          expect(fake_socket_retry)
            .to receive(:send)
            .with('foobar', anything)

          subject.write('foobar')
        end
      end

      context 'when retrying fails' do
        context 'because of an unknown error' do
          before do
            allow(fake_socket_retry)
              .to receive(:send)
              .and_raise(RuntimeError, 'yolo')
          end

          it 'ignores the connection failure' do
            expect do
              subject.write('foobar')
            end.not_to raise_error
          end

          it 'logs the error message' do
            subject.write('foobar')
            expect(log.string).to match 'Statsd error: RuntimeError yolo'
          end
        end

        context 'because of connection still refused' do
          before do
            allow(fake_socket_retry)
              .to receive(:send)
              .and_raise(Errno::ECONNREFUSED, 'yolo')
          end

          it 'ignores the connection failure' do
            expect do
              subject.write('foobar')
            end.not_to raise_error
          end

          it 'logs the error message' do
            subject.write('foobar')
            expect(log.string).to match 'Errno::ECONNREFUSED Connection refused - yolo'
          end
        end
      end
    end
  end

  describe 'when having problems with UDS communication' do
    subject do
      Datadog::Statsd::UDSConnection.new('/tmp/socket', logger: logger)
    end

    before do
      allow(Socket).to receive(:new).and_return(fake_socket, fake_socket_retry)
    end

    let(:fake_socket) do
      instance_double(Socket,
        connect: true,
        sendmsg_nonblock: true
      )
    end

    let(:fake_socket_retry) do
      instance_double(Socket,
        connect: true,
        sendmsg_nonblock: true
      )
    end

    context 'when having connection resets (retry strategy)'do
      before do
        allow(fake_socket)
          .to receive(:sendmsg_nonblock)
          .and_raise(Errno::ECONNRESET)
      end

      context 'when retrying is working' do
        it 'tries with the initial socket' do
          expect(fake_socket)
            .to receive(:sendmsg_nonblock)
            .with('foobar')

          subject.write('foobar')
        end

        it 'retries on the second opened socket' # do
        #   expect(fake_socket_retry)
        #     .to receive(:sendmsg_nonblock)
        #     .with('foobar')

        #   subject.write('foobar')
        # end

        # FIXME: BadSocketError is not correctly caught by Connection class to retry
        it 'does not correctly retry (1)' do
          expect(fake_socket_retry)
            .not_to receive(:sendmsg_nonblock)

          subject.write('foobar')
        end

        it 'does not correctly retry (2)' do
          subject.write('foobar')

          expect(log.string).to match 'Statsd error: Datadog::Statsd::UDSConnection::BadSocketError Errno::ECONNRESET: Connection reset by peer'
        end
      end

      context 'when retrying fails' do
        context 'because of an unknown error' do
          before do
            allow(fake_socket_retry)
              .to receive(:sendmsg_nonblock)
              .and_raise(RuntimeError, 'yolo')
          end

          it 'ignores the connection failure' do
            expect do
              subject.write('foobar')
            end.not_to raise_error
          end

          # the mecanism to retry is broken, once it's fixed, this test should pass
          it 'logs the error message', pending: true do
            subject.write('foobar')
            expect(log.string).to match 'Statsd error: RuntimeError yolo'
          end
        end

        context 'because of a SocketError' do
          before do
            allow(fake_socket_retry)
              .to receive(:sendmsg_nonblock)
              .and_raise(SocketError, 'yolo')
          end

          it 'ignores the connection failure' do
            expect do
              subject.write('foobar')
            end.not_to raise_error
          end

          # the mecanism to retry is broken, once it's fixed, this test should pass
          it 'logs the error message', pending: true do
            subject.write('foobar')
            expect(log.string).to match 'Statsd error: SocketError yolo'
          end
        end
      end
    end

    context 'when having connection refused (retry strategy)' do
      before do
        allow(fake_socket)
          .to receive(:sendmsg_nonblock)
          .and_raise(Errno::ECONNREFUSED.new('closed stream'))
      end

      context 'when retrying is working' do
        it 'tries with the initial socket' do
          expect(fake_socket)
            .to receive(:sendmsg_nonblock)
            .with('foobar')

          subject.write('foobar')
        end

        it 'retries on the second opened socket' # do
        #   expect(fake_socket_retry)
        #     .to receive(:sendmsg_nonblock)
        #     .with('foobar')

        #   subject.write('foobar')
        # end

        # FIXME: BadSocketError is not correctly caught by Connection class to retry
        it 'does not correctly retry (1)' do
          expect(fake_socket_retry)
            .not_to receive(:sendmsg_nonblock)

          subject.write('foobar')
        end

        it 'does not correctly retry (2)' do
          subject.write('foobar')

          expect(log.string).to match 'Statsd error: Datadog::Statsd::UDSConnection::BadSocketError Errno::ECONNREFUSED: Connection refused - closed stream'
        end
      end

      context 'when retrying fails' do
        context 'because of an unknown error' do
          before do
            allow(fake_socket_retry)
              .to receive(:sendmsg_nonblock)
              .and_raise(RuntimeError, 'yolo')
          end

          it 'ignores the connection failure' do
            expect do
              subject.write('foobar')
            end.not_to raise_error
          end

          # the mecanism to retry is broken, once it's fixed, this test should pass
          it 'logs the error message', pending: true do
            subject.write('foobar')
            expect(log.string).to match 'Statsd error: RuntimeError yolo'
          end
        end

        context 'because of connection still refused' do
          before do
            allow(fake_socket_retry)
              .to receive(:sendmsg_nonblock)
              .and_raise(Errno::ECONNREFUSED, 'yolo')
          end

          it 'ignores the connection failure' do
            expect do
              subject.write('foobar')
            end.not_to raise_error
          end

          # the mecanism to retry is broken, once it's fixed, this test should pass
          it 'logs the error message', pending: true do
            subject.write('foobar')
            expect(log.string).to match 'Errno::ECONNREFUSED Connection refused - yolo'
          end
        end
      end
    end

    context 'when there is no socket (drop strategy)' do
      before do
        allow(fake_socket)
          .to receive(:sendmsg_nonblock)
          .and_raise(Errno::ENOENT)
      end

      it 'sends using the first socket' do
        expect(fake_socket)
          .to receive(:sendmsg_nonblock)
          .with('foobar')

        subject.write('foobar')
      end

      it 'ignores the writing failure (message dropped)' do
        expect do
          subject.write('foobar')
        end.not_to raise_error
      end

      it 'does not retry to send message' do
        expect(fake_socket_retry)
          .not_to receive(:sendmsg_nonblock)

        subject.write('foobar')
      end

      # TODO: FIXME: we got to exclude the Errno::ENOENT for the retry strategy
      it 'logs the error message', pending: true do
        subject.write('foobar')

        expect(log.string).to match 'Statsd error: Errno::ENOENT No such file or directory'
      end
    end

    context 'when the socket is full (drop strategy)' do
      before do
        skip if RUBY_VERSION < '2.3.0'
      end

      before do
        allow(fake_socket)
          .to receive(:sendmsg_nonblock)
          .and_raise(IO::EAGAINWaitWritable)
      end

      it 'sends using the first socket' do
        expect(fake_socket)
          .to receive(:sendmsg_nonblock)
          .with('foobar')

        subject.write('foobar')
      end

      it 'ignores the writing failure (message dropped)' do
        expect do
          subject.write('foobar')
        end.not_to raise_error
      end

      it 'does not retry to send message' do
        expect(fake_socket_retry)
          .not_to receive(:sendmsg_nonblock)

        subject.write('foobar')
      end

      it 'logs the error message' do
        subject.write('foobar')

        expect(log.string).to match 'Statsd error: IO::EAGAINWaitWritable Resource temporarily unavailable'
      end
    end
  end

  context 'when using TCP' do
    let(:timeout) { 0.1 }
    let(:sleep_seconds) { 1 }
    let(:host) { 'localhost' }
    let(:port) { 2003 }

    subject do
      Datadog::Statsd::TCPConnection.new(host, port, logger: logger, timeout: timeout)
    end

    context 'when connect takes too much time' do
      it 'raises a timeout error on connection' do
        allow(Socket).to receive(:tcp).with(host, port, connect_timeout: timeout).and_raise(Errno::ETIMEDOUT)

        expect(subject.write('foobar')).to be_nil
        expect(log.string).to match 'Statsd error: Errno::ETIMEDOUT'
      end
    end

    # should be manually run to check real performance
    # context 'without stubs' do
    #   before do
    #     skip("Benchmarks results are currently not used by CI") if ENV.key?('CI')
    #   end

    #   let(:connection) { Datadog::Statsd::TCPConnection.new('localhost', 2003, logger: logger) }

    #   it "works" do
    #     result = connection.write('foobar')

    #     expect(result).to eq(true)
    #   end

    #   context 'when checking sending performance' do
    #     before do
    #       skip("Benchmarks results are currently not used by CI") if ENV.key?('CI')
    #     end

    #     let(:connection) { Datadog::Statsd::TCPConnection.new('localhost', 2003, logger: logger, timeout: 0.1) }

    #     it 'has high ips value' do
    #       require 'benchmark/ips'

    #       Benchmark.ips do |x|
    #         x.report("ips") { connection.write('foobar') }

    #         x.compare!
    #       end
    #     end

    #     it 'does not take much memory ' do
    #       require 'benchmark-memory'

    #       Benchmark.memory do |x|
    #         x.report("memory") { connection.write('foobar') }

    #         x.compare!
    #       end
    #     end
    #   end
    # end
  end
end
