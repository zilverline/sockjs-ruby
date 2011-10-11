# encoding: utf-8

require_relative "../adapter"

module SockJS
  module Adapters
    class XHRPost < Adapter
      # Settings.
      self.prefix  = "xhr"
      self.method  = "POST"
      self.filters = [:h_sid, :xhr_cors, :xhr_poll]

      # Handler.
      def self.handle(env, options)
        raise NotImplementedError.new
      end
    end

    class XHROptions < Adapter
      # Settings.
      self.prefix  = "xhr"
      self.method  = "OPTIONS"
      self.filters = [:h_sid, :xhr_cors, :cache_for, :xhr_options, :expose]

      # Handler.
      def self.handle(env, options)
        raise NotImplementedError.new
      end
    end

    class XHRSendPost < Adapter
      # Settings.
      self.prefix  = "xhr_send"
      self.method  = "POST"
      self.filters = [:h_sid, :xhr_cors, :expect_xhr, :xhr_send]

      # Handler.
      def self.handle(env, options)
        raise NotImplementedError.new
      end
    end

    class XHRSendOptions < Adapter
      # Settings.
      self.prefix  = "xhr_streaming"
      self.method  = "OPTIONS"
      self.filters = [:h_sid, :xhr_cors, :cache_for, :xhr_options, :expose]

      # Handler.
      def self.handle(env, options)
        raise NotImplementedError.new
      end
    end

    class XHRStreamingPost < Adapter
      # Settings.
      self.prefix  = "xhr_streaming"
      self.method  = "POST"
      self.filters = [:h_sid, :xhr_cors, :xhr_streaming]

      # Handler.
      def self.handle(env, options)
        raise NotImplementedError.new
      end
    end

    class XHRStreamingOptions < Adapter
      # Settings.
      self.prefix  = "xhr_send"
      self.method  = "OPTIONS"
      self.filters = [:h_sid, :xhr_cors, :cache_for, :xhr_options, :expose]

      # Handler.
      def self.handle(env, options)
        raise NotImplementedError.new
      end
    end
  end
end
