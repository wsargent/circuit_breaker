class CircuitBreaker::CircuitBrokenException < StandardError

  def initialize(msg, circuit_state = :closed)
    @circuit_state = circuit_state
    super(msg)
  end

  attr_reader :circuit_state

end