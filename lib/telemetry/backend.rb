# frozen_string_literal: true

module Telemetry
  # Telemetry::Backend provides functionality for Telemetry interface
  class Backend
    class HandlerIdUsedError < RuntimeError; end

    attr_accessor :logger

    def initialize
      @handlers = Concurrent::Map.new
      @handler_ids = Concurrent::Map.new

      self.logger = Logger.new(STDERR)
      logger.level = :error
    end

    def attach(handler_id, event_key, config, &block)
      attach_many(handler_id, [event_key], config, &block)
    end

    def attach_many(handler_id, event_keys, config, &block)
      handler = Handler.new(handler_id, config, block)

      @handler_ids[handler_id] ||= Concurrent::Array.new

      # Enforce unique event keys for a given handler id
      unless (@handler_ids[handler_id] & event_keys).empty?
        raise HandlerIdUsedError, "handler_id #{handler_id} has already been used"
      end

      @handler_ids[handler_id] += event_keys

      event_keys.each do |event_key|
        @handlers[event_key] ||= Concurrent::Map.new
        @handlers[event_key][handler_id] = handler
      end
    end

    def detach(handler_id)
      (@handler_ids.delete(handler_id) || []).each do |event_key|
        @handlers[event_key].delete(handler_id)
      end
    end

    def execute(event_key, measurements, metadata, &block)
      (@handlers[event_key] || {}).each do |_handler_id, handler|
        measurements = { timing: call_with_timing(&block) }.merge(measurements) if block_given?

        begin
          handler.call(event_key, measurements, metadata)
        rescue StandardError => e
          logger.error("Detaching handler #{handler.handler_id} because it raises an error #{e.message}")

          detach(handler.handler_id)
        end
      end
    end

    private

    def call_with_timing(&block)
      start = Time.now

      block.call

      ((Time.now - start) * 1000).to_i
    end
  end
end
