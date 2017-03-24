module CircuitBreaker
  # Base exception for all CircuitBreaker exceptions.
  class CircuitBrokenException < StandardError
    def initialize(msg = nil, circuit_state = :closed)
      @circuit_state = circuit_state
      super(msg)
    end

    attr_reader :circuit_state
  end

  # Raised when the circuit method takes too long to return.
  class InvocationTimeoutException < CircuitBrokenException
  end

  # Raised when calling a method while the circuit is open.
  class CircuitOpenException < CircuitBrokenException
  end
end
