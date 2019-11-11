# frozen_string_literal: true

RSpec.describe Telemetry do
  context 'with a block' do
    it 'notifies an attached handler on execution' do
      capture = []

      Telemetry.attach(
        'test-handler-1',
        [:test, :key, :one],
        {extra: 'information'}
      ) do |event_key, measurements, metadata, config|
        capture = [event_key, measurements, metadata, config]
      end

      Telemetry.execute(
        [:test, :key, :one],
        {some: 'measurements'},
        {some: 'metadata'}
      )

      expect(capture).to eq([
        [:test, :key, :one],
        {some: 'measurements'},
        {some: 'metadata'},
        {extra: 'information'}
      ])
    end
  end

  class TestHandler
    attr_reader :capture

    def initialize
      @capture = []
    end

    def handle(event_key, measurements, metadata, config)
      @capture = [event_key, measurements, metadata, config]
    end
  end

  context 'with a method reference' do
    it 'notifies an attached handler on execution' do
      test_handler = TestHandler.new

      Telemetry.attach(
        'test-handler-2',
        [:test, :key, :two],
        {extra: 'information'},
        &test_handler.method(:handle)
      )

      Telemetry.execute(
        [:test, :key, :two],
        {some: 'measurements'},
        {some: 'metadata'}
      )

      expect(test_handler.capture).to eq([
        [:test, :key, :two],
        {some: 'measurements'},
        {some: 'metadata'},
        {extra: 'information'}
      ])
    end
  end

  context 'executing with a block' do
    it 'adds timing (in ms) of the block to measurements' do
      call_count = 0
      test_handler = TestHandler.new
      Telemetry.attach('test-handler-3', [:test, :key, :three], {}, &test_handler.method(:handle))

      Telemetry.execute([:test, :key, :three], {}, {}) do
        call_count += 1
        sleep 0.01
      end

      expect(call_count).to eq(1)
      expect(test_handler.capture[1][:timing]).to be >= 10
    end
  end

  it 'does not call detached handlers on execute' do
    call_count = 0

    Telemetry.attach(
      'test-handler-4',
      [:test, :key, :four],
      {extra: 'information'}
    ) do |_event_key, _measurements, _metadata, _config|
      call_count += 1
    end

    Telemetry.execute(
      [:test, :key, :four],
      {some: 'measurements'},
      {some: 'metadata'}
    )

    expect(call_count).to eq(1)

    Telemetry.detach('test-handler-4')

    Telemetry.execute(
      [:test, :key, :four],
      {some: 'measurements'},
      {some: 'metadata'}
    )

    expect(call_count).to eq(1)
  end

  class BrokenTestHandler
    def handle(_event_key, _measurements, _metadata, _config)
      raise "I'm broken"
    end
  end

  it 'detaches a handler when its function raises' do
    test_handler = BrokenTestHandler.new

    Telemetry.attach(
      'test-handler-5', [:test, :key, :five], {},
      &test_handler.method(:handle)
    )

    expect do
      Telemetry.execute(
        [:test, :key, :five],
        {some: 'measurements'},
        {some: 'metadata'}
      )
    end.not_to raise_error
  end
end
