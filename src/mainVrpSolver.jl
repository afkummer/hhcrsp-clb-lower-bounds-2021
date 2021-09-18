#!/usr/bin/env julia

cd("/HHCRSP")
include("run.jl")

if length(ARGS) != 2
   println("Usage: VRPSolver <input instance> <upper bound>")
   exit(1)
end

runVRPSolver(ARGS[1], 0.1+parse(Float64, ARGS[2]))
