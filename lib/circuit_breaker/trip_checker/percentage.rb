module CircuitBreaker
  module TripChecker
    class Percentage
      attr_accessor :logger, :threshold, :minimum

      def initialize(logger, threshold, minimum = 3)
        @logger    = logger
        @threshold = threshold
        @minimum   = minimum
      end

      def tripped?(circuit_state)
        perc = circuit_state.failure_count.to_f / circuit_state.call_count
        out  = (circuit_state.call_count > minimum) && (perc > threshold)

        logger.debug("tripped?: #{circuit_state.call_count} > #{minimum} && #{perc} > #{threshold} == #{out}") if logger
        out
      end
    end
  end
end
