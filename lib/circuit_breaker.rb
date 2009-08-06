#
# CircuitBreaker is a relatively simple Ruby mixin that will wrap
# a call to a given service in a circuit breaker pattern.
#
# The circuit starts off "closed" meaning that all calls will go through.
# However, consecutive failures are recorded and after a threshold is reached,
# the circuit will "trip", setting the circuit into an "open" state.
#
# In an "open" state, every call to the service will fail by raising
# CircuitBrokenException.
#
# The circuit will remain in an "open" state until the failure timeout has
# elapsed.
#
# After the failure_timeout has elapsed, the circuit will go into
# a "half open" state and the call will go through.  A failure will
# immediately pop the circuit open again, and a success will close the
# circuit and reset the failure count.
#
# For services that can take an unmanagable amount of time to respond an
# invocation timeout threshold is provided.  If the service fails to return
# before the invocation_timeout duration has passed, the circuit will "trip",
# setting the circuit into an "open" state.
#
# require 'circuit_breaker'
# class TestService
#
#   include CircuitBreaker
#
#   def call_remote_service() ...
#
#   circuit_method :call_remote_service
#
#   # Optional
#   circuit_handler do |handler|
#     handler.logger = Logger.new(STDOUT)
#     handler.failure_threshold = 5
#     handler.failure_timeout = 5
#     handler.invocation_timeout = 10
#   end
#
#   # Optional
#   circuit_handler_class MyCustomCircuitHandler
#
# end
#
# Copyright 2009 Will Sargent
# Author: Will Sargent <will.sargent@gmail.com>
# Many thanks to Devin Mullins
#
module CircuitBreaker
  VERSION = '1.0.0'
  
  #
  # Extends the included class with CircuitBreaker
  #
  def self.included(klass)
    klass.extend ::CircuitBreaker::ClassMethods
  end

  #
  # Returns the current circuit state.  This is defined on the instance, so
  # you can have several instances of the same class with different states.
  #
  def circuit_state
    @circuit_state ||= self.class.circuit_handler.new_circuit_state
  end

  module ClassMethods

    #
    # Takes a splat of method names, and wraps them with the circuit_handler.
    #
    def circuit_method(*methods)
      circuit_handler = self.circuit_handler

      methods.each do |meth|
        m = instance_method meth
        define_method meth do |*args|
          circuit_handler.handle self.circuit_state, m.bind(self), *args
        end
      end
    end

    #
    # Returns circuit_handler.  Yields the instance back when passed a block.
    #
    def circuit_handler(&block)
      @circuit_handler ||= circuit_handler_class.new

      yield @circuit_handler if block_given?

      return @circuit_handler
    end

    #
    # Allows you to define a custom circuit_handler instead of CircuitBreaker::CircuitHandler
    #
    def circuit_handler_class(klass = nil)
      @circuit_handler_class ||= (klass || CircuitBreaker::CircuitHandler)
    end

  end

end

require 'circuit_breaker/circuit_handler'
require 'circuit_breaker/circuit_broken_exception'
require 'circuit_breaker/circuit_state'
