# frozen_string_literal: true

require 'concurrent'

require 'telemetry/version'
require 'telemetry/handler'
require 'telemetry/backend'

# Telemetry calls attached handler functions when executed upon.
module Telemetry
  def instance
    @instance ||= Backend.new
  end

  def attach(*args, &block)
    instance.attach(*args, &block)
  end

  def attach_many(*args, &block)
    instance.attach_many(*args, &block)
  end

  def detach(*args)
    instance.detach(*args)
  end

  def execute(*args, &block)
    instance.execute(*args, &block)
  end

  module_function :instance, :attach, :attach_many, :detach, :execute
end
