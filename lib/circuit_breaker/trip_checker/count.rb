module CircuitBreaker
  module TripChecker
    class Count
      attr_accessor :logger, :threshold

      def initialize(logger, threshold)
        @logger    = logger
        @threshold = threshold
      end

      def tripped?(circuit_state)
        out = (circuit_state.failure_count > threshold)
        logger.debug("tripped?: #{circuit_state.failure_count} > #{threshold} == #{out}") if logger
        out
      end
    end
  end
end
