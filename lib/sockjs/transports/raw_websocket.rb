# encoding: utf-8

require "forwardable"
require "sockjs/faye"
require "sockjs/transport"

# Raw WebSocket url: /websocket
# -------------------------------
#
# SockJS protocol defines a bit of higher level framing. This is okay
# when the browser using SockJS-client establishes the connection, but
# it's not really appropriate when the connection is being established
# from another program. Although SockJS focuses on server-browser
# communication, it should be straightforward to connect to SockJS
# from command line or some any programming language.
#
# In order to make writing command-line clients easier, we define this
# `/websocket` entry point. This entry point is special and doesn't
# use any additional custom framing, no open frame, no
# heartbeats. Only raw WebSocket protocol.

module SockJS
  module Transports
    module WSDebuggingMixin
      def send_data(*args)
        if args.length == 1
          data = args.first
        else
          data = fix_buggy_input(*args)
        end

        SockJS.debug "WS#send #{data.inspect}"

        super(data)
      end

      def fix_buggy_input(*args)
        data = 'c[3000,"Go away!"]'
        SockJS.debug "[ERROR] Incorrect input: #{args.inspect}, changing to #{data} for now"
        return data
      end

      def close(*args)
        SockJS.debug "WS#close(#{args.inspect[1..-2]})"
        super(*args)
      end
    end


    class RawWebSocket < Transport
      # Settings.
      self.prefix = /^websocket$/
      self.method = "GET"

      def session_class
        SockJS::WebSocketSession
      end

      def check_invalid_request_or_disabled_websocket(request)
        if not @options[:websocket]
          raise HttpError.new(404, "WebSockets Are Disabled")
        elsif request.env["HTTP_UPGRADE"].to_s.downcase != "websocket"
          raise HttpError.new(400, 'Can "Upgrade" only to "WebSocket".')
        elsif not ["Upgrade", "keep-alive, Upgrade"].include?(request.env["HTTP_CONNECTION"])
          raise HttpError.new(400, '"Connection" must be "Upgrade".')
        end
      end

      # Handlers.
      def handle(request)
        check_invalid_request_or_disabled_websocket(request)

        SockJS.debug "Upgrading to WebSockets ..."

        @ws = Faye::WebSocket.new(request.env)

        @ws.extend(WSDebuggingMixin)

        @ws.onopen = lambda do |event|
          self.handle_open(request)
        end

        @ws.onmessage = lambda do |event|
          SockJS.debug "WS data received: #{event.data.inspect}"
          self.handle_message(request, event)
        end

        @ws.onclose = lambda do |event|
          SockJS.debug "Closing WebSocket connection (code: #{event.code}, reason: #{event.reason.inspect})"
          self.handle_close(request, event)
        end
      rescue SockJS::HttpError => error
        error.to_response(self, request)
      end

      # Here we need to open a new session, so we
      # can run the custom app. No opening frame.
      def handle_open(request)
        SockJS.debug "Opening WS connection."
        # Here, the session_id is not important at all,
        # it's all about the actual connection object.
        @session = self.connection.create_session(@ws.object_id.to_s, self)
        @session.ws = @ws
        @session.buffer = RawBuffer.new # This is a hack for the bloody API. Rethinking and refactoring required!
        @session.transport = self

        # Send the opening frame.
        @session.open!
        @session.buffer = RawBuffer.new(:open)
        @session.check_status

        @session.process_buffer # Run the app (connection.session_open hook).
      end

      # Run the app. Messages shall be send
      # without frames. This might need another
      # buffer class or another session class.
      def handle_message(request, event)
        message = [event.data].to_json

        # Unlike other transports, the WS one is supposed to ignore empty messages.
        unless message.empty?
          SockJS.debug "WS message received: #{message.inspect}"
          @session.receive_message(request, message)

          # Send encoded messages in an array frame.
          messages = @session.process_buffer
          if messages && messages.start_with?("a[") # We don't have any framing, this is obviously utter bollocks
            SockJS.debug "Messages to be sent: #{messages.inspect}"
            @session.send_data(messages)
          end
        end
      rescue SockJS::InvalidJSON => error
        # @ws.send(error.message) # TODO: frame it ... although ... is it required? The tests do pass, but it would be inconsistent if we'd send it for other transports and not for WS, huh?
        @ws.close # Close the connection abruptly, no closing frame.
      end

      # Close the connection without sending the closing frame.
      def handle_close(request, event)
        SockJS.debug "Closing WS connection."
        @session.close
      end

      def format_frame(payload)
        raise TypeError.new("Payload must not be nil!") if payload.nil?

        payload
      end
    end
  end
end
