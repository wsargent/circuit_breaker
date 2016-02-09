class CircuitBreaker::InvalidTransition < RuntimeError
  attr_reader :object, :event_name, :state_machine_name, :failures

  def initialize(object, event_name, state_machine_name, failures = [])
    @object, @event_name, @state_machine_name, @failures = object, event_name, state_machine_name, failures
  end

  def message
    "Event '#{event_name}' cannot transition from '#{object.aasm(state_machine_name).current_state}'. #{reasoning}"
  end

  def reasoning
    "Failed callback(s): #{@failures}." unless failures.empty?
  end
end
