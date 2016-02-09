require 'spec_helper'
require 'logger'

describe CircuitBreaker do

  class SpecificException < Exception; end
  class NotFoundException < Exception; end

  class TestClass

   include CircuitBreaker

   def initialize()
      @failure = false
    end

    def fail!
      @failure = true
    end

    def succeed!
      @failure = false
    end

    def call_external_method()
      if @failure == true
        raise "FAIL"
      end

      "hello world!"
    end

    def second_method()
      raise 'EPIC FAIL'
    end

    def unresponsive_method
      sleep 1.1
      "unresponsive method returned"
    end

    def raise_specific_error_method
      if @failure == true
        raise SpecificException.new "SPECIFIC FAIL"
      end

      raise NotFoundException.new "NOT FOUND FAIL"
    end

    # Register this method with the circuit breaker...
    #
    circuit_method :call_external_method, :second_method, :unresponsive_method, :raise_specific_error_method

    #
    # Define what needs to be set for configuration...
    #
    circuit_handler do |handler|
      handler.logger = Logger.new(STDOUT)
      handler.failure_threshold = 5
      handler.failure_timeout = 5
      handler.invocation_timeout = 1
      handler.excluded_exceptions = [NotFoundException]
    end

  end

  before(:each) do
    TestClass.circuit_handler.failure_threshold = 5
    @test_object = TestClass.new()
  end

  it 'should call second_method and have it run through the circuit breaker' do
    expect { @test_object.second_method() }.to raise_error("EPIC FAIL")
    expect(@test_object.circuit_state).to be_closed
    expect(@test_object.circuit_state.failure_count).to eq(1)
  end

  it 'should not raise warning about method redefined' do
    orig_stderr = $stderr
    $stderr = StringIO.new

    TestClass.circuit_method :second_method

    $stderr.rewind
    expect($stderr.string.chomp).to_not match(/warning: previous definition of second_method was here/)
    $stderr = orig_stderr
  end

  describe "when closed" do

    it "should execute without failing" do
      expect(@test_object.call_external_method()).to eq('hello world!')
      expect(@test_object.circuit_state).to be_closed
      expect(@test_object.circuit_state.failure_count).to eq(0)
    end

    it 'should increment the failure count when a failure occurs' do
      @test_object.fail!

      expect { @test_object.call_external_method() }.to raise_error(RuntimeError)
      expect(@test_object.circuit_state).to be_closed
      expect(@test_object.circuit_state.failure_count).to eq(1)
    end

    it 'should trip the circuit when too many failures occur' do
      @test_object.fail!

      expect { @test_object.call_external_method() }.to raise_error(RuntimeError)
      expect { @test_object.call_external_method() }.to raise_error(RuntimeError)
      expect { @test_object.call_external_method() }.to raise_error(RuntimeError)
      expect { @test_object.call_external_method() }.to raise_error(RuntimeError)
      expect { @test_object.call_external_method() }.to raise_error(RuntimeError)
      expect { @test_object.call_external_method() }.to raise_error(RuntimeError)

      expect(@test_object.circuit_state).to be_open
      expect(@test_object.circuit_state.failure_count).to eq(6)
    end

    it 'should reset the failure count if closed after a successful call.' do
      @test_object.fail!

      expect { @test_object.call_external_method() }.to raise_error("FAIL")

      @test_object.succeed!
      @test_object.call_external_method()

      expect(@test_object.circuit_state.failure_count).to eq(0)
      expect(@test_object.circuit_state).to be_closed
    end

    it 'should trip immediately when the failure threshold is set to zero' do
      @test_object.fail!

      TestClass.circuit_handler.failure_threshold = 0
      expect { @test_object.call_external_method() }.to raise_error(RuntimeError)
      expect(@test_object.circuit_state).to be_open
      expect(@test_object.circuit_state.failure_count).to eq(1)
    end

    it 'should increment the failure count when the method takes too long to return' do
      expect { @test_object.unresponsive_method }.to raise_error(CircuitBreaker::CircuitBrokenException)
      expect(@test_object.circuit_state).to be_closed
      expect(@test_object.circuit_state.failure_count).to eq(1)
    end

    describe "and some exceptions not indicates a circuit problem" do
      it 'should not increment the failure count when a failure of a specific type occurs' do
        @test_object.fail!

        expect { @test_object.raise_specific_error_method }.to raise_error(SpecificException)
        expect(@test_object.circuit_state).to be_closed
        expect(@test_object.circuit_state.failure_count).to eq(1)

        @test_object.succeed!

        expect { @test_object.raise_specific_error_method }.to raise_error(NotFoundException)
        expect(@test_object.circuit_state).to be_closed
        expect(@test_object.circuit_state.failure_count).to eq(1)
      end
    end

  end

  describe "when open" do

    it 'should fail immediately if the circuit is open' do
      now = Time.now
      @test_object.circuit_state.trip!
      @test_object.circuit_state.last_failure_time = now
      @test_object.circuit_state.failure_count = 5

      # Should return CircuitBrokenException explicitly
      expect { @test_object.call_external_method() }.to raise_error(::CircuitBreaker::CircuitBrokenException)

      # Failure count should not be open
      expect(@test_object.circuit_state.failure_count).to eq(5)
      expect(@test_object.circuit_state).to be_open
    end

    it 'should not reset the circuit when not enough time has passed' do
      now = Time.now

      failure_threshold = 4
      @test_object.circuit_state.trip
      @test_object.circuit_state.last_failure_time = now - failure_threshold
      @test_object.circuit_state.failure_count = 5

      expect { @test_object.call_external_method() }.to raise_error(::CircuitBreaker::CircuitBrokenException)

      expect(@test_object.circuit_state.failure_count).to eq(5)
      expect(@test_object.circuit_state).to be_open
    end

  end

  describe "when half open" do

    it 'should reset the circuit when enough time has passed' do
      now = Time.now

      failure_threshold = 5
      @test_object.circuit_state.trip
      @test_object.circuit_state.attempt_reset
      @test_object.circuit_state.last_failure_time = now - failure_threshold
      @test_object.circuit_state.failure_count = 5

      @test_object.call_external_method()

      # After a successful call, the failure count is reset.
      expect(@test_object.circuit_state.failure_count).to eq(0)
      expect(@test_object.circuit_state).to be_closed
    end

    it 'should trip the circuit immediately if in a half open state' do
      now = Time.now

      @test_object.circuit_state.trip

      # Set to half open...
      @test_object.circuit_state.attempt_reset
      @test_object.circuit_state.last_failure_time = now - 5
      @test_object.circuit_state.failure_count = 5

      # Have an unsuccessful call...
      @test_object.fail!
      expect { @test_object.call_external_method() }.to raise_error("FAIL")

      expect(@test_object.circuit_state.failure_count).to eq(6)

      # The circuit should immediately pop open again.
      expect(@test_object.circuit_state).to be_open
    end

  end

end
