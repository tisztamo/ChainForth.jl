# ChainForth.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.com/tisztamo/ChainForth.jl.svg?branch=master)](https://travis-ci.com/tisztamo/ChainForth.jl)
[![codecov.io](http://codecov.io/github/tisztamo/ChainForth.jl/coverage.svg?branch=master)](http://codecov.io/github/tisztamo/ChainForth.jl?branch=master)
<!--
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://tisztamo.github.io/ChainForth.jl/stable)
[![Documentation](https://img.shields.io/badge/docs-master-blue.svg)](https://tisztamo.github.io/ChainForth.jl/dev)
-->

ChainForth.jl is an embedded virtual machine that helps you provide a highly secure but programmable, Turing-complete API layer at the edge of your Julia projects.

## What isa programmable API?

A Programmable API is a communication interface that allows
efficient communication across incompatible programming environments by providing a common language that the parties use to script each other.

Imagine a simple (frontend\_client, backend\_server) pair with the twist that instead of issuing REST requests, the client sends small scripts to the server for execution.

The scripts communicate with an embedded interface provided by the server, and run their logic on the received data instead of just forwarding it to the client.

This separation allows the server to provide a lower-level API, thus instead of defining a high-level, rigid API endpoint structure, it exports small building blocks that the client can use to build its own (query) language.

## Why not just simply program the API in Julia?

- Julia execution is unsafe.
- Measuring and restricting resource use is hard if not impossible in Julia
- Sending quoted scripts back-and-forth between the communication parties would be impossible if one of them is programmed in Julia.
