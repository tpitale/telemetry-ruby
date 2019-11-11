# frozen_string_literal: true

module Telemetry
  Handler = Struct.new(:handler_id, :config, :block) do
    def call(event_key, measurements, metadata)
      block.call(event_key, measurements, metadata, config)
    end
  end
end
