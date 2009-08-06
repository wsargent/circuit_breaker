= circuit_breaker

* http://github.com/wsargent/circuit_breaker
* http://rdoc.info/projects/wsargent/circuit_breaker
* Will Sargent <will.sargent@gmail.com>

== DESCRIPTION:

 CircuitBreaker is a relatively simple Ruby mixin that will wrap
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

 For services that can take an unmanagable amount of time to respond an
 invocation timeout threshold is provided.  If the service fails to return
 before the invocation_timeout duration has passed, the circuit will "trip",
 setting the circuit into an "open" state.
 
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
         handler.invocation_timeout = 10
       end

       # Optional
       circuit_handler_class MyCustomCircuitHandler
     end

== FEATURES/PROBLEMS:

* Can run out of the box with minimal dependencies and a couple of lines of code.
* Easy to extend: add your own circuit breakers or states or extend the existing ones.
* Does not currently handle static class methods.

== SYNOPSIS:

  An implementation of Michael Nygard's Circuit Breaker pattern.

== REQUIREMENTS:

  circuit_breaker has a dependency on AASM @ http://github.com/rubyist/aasm/tree/master

== INSTALL:

* gem sources -a http://gems.github.com
* gem install rubyist-aasm
* gem install wsargent_circuit-breaker

== LICENSE:

Copyright (c) 2009, Will Sargent
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following
    disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
    disclaimer in the documentation and/or other materials provided with the distribution.
  * The names of its contributors may not be used to endorse or promote products derived from this software without
    specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.