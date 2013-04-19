# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'circuit_breaker/version'

Gem::Specification.new do |s|
  s.name        = %q{circuit_breaker}
  s.version     = CircuitBreaker::VERSION
  s.date        = %q{2013-04-13}

  s.authors     = ["Will Sargent"]
  s.email       = ["will.sargent@gmail.com"]
  s.homepage    = %q{http://github.com/wsargent/circuit_breaker}
  s.summary     = %q{CircuitBreaker is a relatively simple Ruby mixin that will wrap a call to a given service in a circuit breaker pattern}
  s.description = %q{CircuitBreaker is a relatively simple Ruby mixin that will wrap
 a call to a given service in a circuit breaker pattern.

 The circuit starts off "closed" meaning that all calls will go through.
 However, consecutive failures are recorded and after a threshold is reached,
 the circuit will "trip", setting the circuit into an "open" state.

 In an "open" state, every call to the service will fail by raising
 CircuitBrokenException.

 The circuit will remain in an "open" state until the failure timeout has
 elapsed.

 After the failure_timeout has elapsed, the circuit will go into
 a "half open" state and the call will go through.  A failure will
 immediately pop the circuit open again, and a success will close the
 circuit and reset the failure count.

     require 'circuit_breaker'
     class TestService

       include CircuitBreaker

       def call_remote_service() ...

       circuit_method :call_remote_service

       # Optional
       circuit_handler do |handler|
         handler.logger = Logger.new(STDOUT)
         handler.failure_threshold = 5
         handler.failure_timeout = 5
       end

       # Optional
       circuit_handler_class MyCustomCircuitHandler
     end}

  s.rubyforge_project = %q{will_sargent}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.extra_rdoc_files = ["History.txt", "README.txt"]
  s.rdoc_options = ["--main", "README.txt", "--charset=UTF-8"]

  s.add_runtime_dependency "aasm"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end
