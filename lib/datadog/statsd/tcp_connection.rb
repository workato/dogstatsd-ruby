# frozen_string_literal: true

require_relative 'connection'

module Datadog
  class Statsd
    class TCPConnection < Connection
      # timeout in seconds for connection and packet retransmissions
      DEFAULT_TIMEOUT = 5

      # StatsD host.
      attr_reader :host

      # StatsD port.
      attr_reader :port

      def initialize(host, port, **kwargs)
        super(**kwargs)

        @host = host
        @port = port
        @socket = nil
        @timeout = kwargs[:timeout] || DEFAULT_TIMEOUT
      end

      def close
        @socket.close if @socket
        @socket = nil
      end

      private

      def connect
        @socket.flush rescue nil
        close if @socket

        @socket = Socket.tcp(host, port, connect_timeout: @timeout)

        # TCP_USER_TIMEOUT is not available on macos
        if Socket.const_defined?('TCP_USER_TIMEOUT')
          # set TCP_USER_TIMEOUT socket option to avoid long packet retransmissions, we prefer to fail fast
          @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_USER_TIMEOUT, @timeout * 1000)
        end
      end

      # send_message is writing the message in the socket, it may create the socket if nil
      # It is not thread-safe but since it is called by either the Sender bg thread or the
      # SingleThreadSender (which is using a mutex while Flushing), only one thread must call
      # it at a time.
      def send_message(message)
        connect unless @socket

        @socket.write(message.to_s + "\n")
      end
    end
  end
end
