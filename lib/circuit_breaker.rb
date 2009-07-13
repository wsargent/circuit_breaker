
#
#
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
