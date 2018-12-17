require 'spec_helper'

describe CircuitBreaker::CircuitState do
  subject { described_class.new }

  describe "#initialize" do
    it "sets the state to closed" do
      expect(subject).to be_closed
    end
  end

  shared_examples_for "trip" do
    it "changes the state from :closed to :open" do
      subject.trip
      expect(subject).to be_open
    end

    it "changes the state from :half_open to :open" do
      subject.trip
      subject.attempt_reset
      subject.trip
      expect(subject).to be_open
    end

    if defined?(AASM::InvalidTransition)
      it "when AASM is defined, raises an AASM::InvalidTransition exception if invoked from :open" do
        subject.trip
        expect { subject.trip }.to raise_error(AASM::InvalidTransition)
      end
    else
      it "raises a CircuitBreaker::InvalidTransition exception if invoked from :open" do
        subject.trip
        expect { subject.trip }.to raise_error(CircuitBreaker::InvalidTransition)
      end
    end
  end

  describe "#trip" do
    include_examples "trip"
  end

  describe "#trip!" do
    include_examples "trip"
  end

  describe "#attempt_reset" do
    it "changes the state from :open to :half_open" do
      subject.trip
      subject.attempt_reset
      expect(subject).to be_half_open
    end

    it "raises an exception if invoked from :half_open" do
      subject.trip
      subject.attempt_reset
      expect { subject.attempt_reset }.to raise_error(CircuitBreaker::InvalidTransition)
    end

    it "raises an exception if invoked from :closed" do
      expect { subject.attempt_reset }.to raise_error(CircuitBreaker::InvalidTransition)
    end
  end

  describe "#reset" do
    it "changes the state from :open to :closed" do
      subject.trip
      subject.reset
      expect(subject).to be_closed
    end

    it "changes the state from :half_open to :closed" do
      subject.trip
      subject.attempt_reset
      subject.reset
      expect(subject).to be_closed
    end

    it "raises an exception if invoked from :closed" do
      expect { subject.reset }.to raise_error(CircuitBreaker::InvalidTransition)
    end

    it "resets the failure count" do
      subject.trip
      subject.reset
      expect(subject.failure_count).to eq(0)
    end
  end
end
