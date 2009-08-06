require 'timeout'

#
#
# CircuitHandler is stateless,
# so the circuit_state gets mixed in with the calling object.
#
#
class CircuitBreaker::CircuitHandler

  #
  # The number of failures needed to trip the breaker.
  #
  attr_accessor :failure_threshold

  #
  # The period of time in seconds before attempting to reset the breaker.
  #
  attr_accessor :failure_timeout

  #
  # The period of time the circuit_method has to return before a timeout exception is thrown.
  #
  attr_accessor :invocation_timeout

  #
  # Optional logger.
  #
  attr_accessor :logger

  DEFAULT_FAILURE_THRESHOLD  = 5
  DEFAULT_FAILURE_TIMEOUT    = 5
  DEFAULT_INVOCATION_TIMEOUT = 30

  def initialize(logger = nil)
    @logger = logger
    @failure_threshold = DEFAULT_FAILURE_THRESHOLD
    @failure_timeout = DEFAULT_FAILURE_TIMEOUT
    @invocation_timeout = DEFAULT_INVOCATION_TIMEOUT
  end

  #
  # Returns a new CircuitState instance.
  #
  def new_circuit_state
    ::CircuitBreaker::CircuitState.new
  end
  
  #
  # Handles the method covered by the circuit breaker.
  #
  def handle(circuit_state, method, *args)
    if is_tripped(circuit_state)
      @logger.debug("handle: breaker is tripped, refusing to execute: #{circuit_state.inspect}") if @logger
      on_circuit_open(circuit_state)
    end

    begin
      out = nil
      Timeout.timeout(@invocation_timeout, CircuitBreaker::CircuitBrokenException) do
        out = method[*args]
        on_success(circuit_state)
      end
    rescue Exception
      on_failure(circuit_state)
      raise
    end
    return out
  end

  #
  # Returns true when the number of failures is sufficient to trip the breaker, false otherwise.
  #
  def is_failure_threshold_reached(circuit_state)
    out = (circuit_state.failure_count > failure_threshold)
    @logger.debug("is_failure_threshold_reached: #{circuit_state.failure_count} > #{failure_threshold} == #{out}") if @logger

    return out
  end

  #
  # Returns true if enough time has elapsed since the last failure time, false otherwise.
  #
  def is_timeout_exceeded(circuit_state)
    now = Time.now

    time_since = now - circuit_state.last_failure_time
    @logger.debug("timeout_exceeded: time since last failure = #{time_since.inspect}") if @logger
    return time_since >= failure_timeout
  end

  #
  # Returns true if the circuit breaker is still open and the timeout has
  # not been exceeded, false otherwise.
  #
  def is_tripped(circuit_state)

    if circuit_state.open? && is_timeout_exceeded(circuit_state)
      @logger.debug("is_tripped: attempting reset into half open state for #{circuit_state.inspect}") if @logger
      circuit_state.attempt_reset
    end

    return circuit_state.open?
  end

  #
  # Called when an individual success happens. 
  #
  def on_success(circuit_state)
    @logger.debug("on_success: #{circuit_state.inspect}") if @logger

    if circuit_state.closed?
      @logger.debug("on_success: reset_failure_count #{circuit_state.inspect}") if @logger
      circuit_state.reset_failure_count
    end

    if circuit_state.half_open?
      @logger.debug("on_success: reset circuit #{circuit_state.inspect}") if @logger
      circuit_state.reset
    end
  end

  #
  # Called when an individual failure happens.
  #
  def on_failure(circuit_state)
    @logger.debug("on_failure: circuit_state = #{circuit_state.inspect}") if @logger
    
    circuit_state.increment_failure_count

    if is_failure_threshold_reached(circuit_state) || circuit_state.half_open?
      # Set us into a closed state.
      @logger.debug("on_failure: tripping circuit breaker #{circuit_state.inspect}") if @logger
      circuit_state.trip
    end
  end

  #
  # Called when a call is made and the circuit is open.   Raises a CircuitBrokenException exception. 
  #
  def on_circuit_open(circuit_state)
    @logger.debug("on_circuit_open: raising for #{circuit_state.inspect}") if @logger
        
    raise CircuitBreaker::CircuitBrokenException.new("Circuit broken, please wait for timeout", circuit_state)
  end
   
end