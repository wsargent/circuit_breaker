
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
# require 'circuit_breaker'
# class TestService
#
#   include CircuitBreaker
#
#   def call_remote_service() ...
#
#   circuit_method :call_remote_service
#
#   circuit_handler do |handler|
#     handler.logger = Logger.new(STDOUT)
#     handler.failure_threshold = 5
#     handler.failure_timeout = 5
#   end
# end

#
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

  def circuit_state
    @circuit_state ||= self.class.circuit_handler.new_circuit_state
  end

  module ClassMethods
  
    def circuit_method(meth)
      circuit_handler = self.circuit_handler

      m = instance_method meth
      define_method meth do |*args|
        circuit_handler.handle self.circuit_state, m.bind(self), *args
      end
    end

    def circuit_handler(&block)
      @circuit_handler ||= CircuitBreaker::CircuitHandler.new

      yield @circuit_handler if block_given?

      return @circuit_handler
    end

  end

end

require 'circuit_breaker/circuit_handler'
require 'circuit_breaker/circuit_broken_exception'
require 'circuit_breaker/circuit_state'
