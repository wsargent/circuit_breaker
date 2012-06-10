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
        raise SpecificException.new "SPECIFC FAIL"
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
    lambda { @test_object.second_method() }.should raise_error("EPIC FAIL")
    @test_object.circuit_state.closed?.should == true
    @test_object.circuit_state.failure_count.should == 1
  end

  describe "when closed" do

    it "should execute without failing" do
      @test_object.call_external_method().should == 'hello world!'
      @test_object.circuit_state.closed?.should == true
      @test_object.circuit_state.failure_count.should == 0
    end

    it 'should increment the failure count when a failure occurs' do
      @test_object.fail!

      lambda { @test_object.call_external_method() }.should raise_error
      @test_object.circuit_state.closed?.should == true
      @test_object.circuit_state.failure_count.should == 1
    end

    it 'should trip the circuit when too many failures occur' do
      @test_object.fail!

      lambda { @test_object.call_external_method() }.should raise_error
      lambda { @test_object.call_external_method() }.should raise_error
      lambda { @test_object.call_external_method() }.should raise_error
      lambda { @test_object.call_external_method() }.should raise_error
      lambda { @test_object.call_external_method() }.should raise_error
      lambda { @test_object.call_external_method() }.should raise_error

      @test_object.circuit_state.open?.should == true
      @test_object.circuit_state.failure_count.should == 6
    end

    it 'should reset the failure count if closed after a successful call.' do
      @test_object.fail!

      lambda { @test_object.call_external_method() }.should raise_error("FAIL")

      @test_object.succeed!
      @test_object.call_external_method()

      @test_object.circuit_state.failure_count.should == 0
      @test_object.circuit_state.closed?.should == true
    end

    it 'should trip immediately when the failure threshold is set to zero' do
      @test_object.fail!

      TestClass.circuit_handler.failure_threshold = 0
      lambda { @test_object.call_external_method() }.should raise_error
      @test_object.circuit_state.open?.should == true
      @test_object.circuit_state.failure_count.should == 1
    end

    it 'should increment the failure count when the method takes too long to return' do
      lambda { @test_object.unresponsive_method }.should raise_error(CircuitBreaker::CircuitBrokenException)
      @test_object.circuit_state.closed?.should == true
      @test_object.circuit_state.failure_count.should == 1
    end

    describe "and some exceptions not indicates a circuit problem" do
      it 'should not increment the failure count when a failure of a specific type occurs' do
        @test_object.fail!

        lambda { @test_object.raise_specific_error_method }.should raise_error(SpecificException)
        @test_object.circuit_state.closed?.should == true
        @test_object.circuit_state.failure_count.should == 1

        @test_object.succeed!

        lambda { @test_object.raise_specific_error_method }.should raise_error(NotFoundException)
        @test_object.circuit_state.closed?.should == true
        @test_object.circuit_state.failure_count.should == 1
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
      lambda { @test_object.call_external_method() }.should raise_error(::CircuitBreaker::CircuitBrokenException)

      # Failure count should not be open
      @test_object.circuit_state.failure_count.should == 5
      @test_object.circuit_state.open?.should == true
    end

    it 'should not reset the circuit when not enough time has passed' do
      now = Time.now

      failure_threshold = 4
      @test_object.circuit_state.trip
      @test_object.circuit_state.last_failure_time = now - failure_threshold
      @test_object.circuit_state.failure_count = 5

      lambda { @test_object.call_external_method() }.should raise_error(::CircuitBreaker::CircuitBrokenException)

      @test_object.circuit_state.failure_count.should == 5
      @test_object.circuit_state.open?.should == true
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
      @test_object.circuit_state.failure_count.should == 0
      @test_object.circuit_state.closed?.should == true
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
      lambda { @test_object.call_external_method() }.should raise_error("FAIL")

      @test_object.circuit_state.failure_count.should == 6

      # The circuit should immediately pop open again.
      @test_object.circuit_state.open?.should == true
    end

  end

end
