using VrpSolver, JuMP, ArgParse
using JuMP, ArgParse

include("data.jl")
include("model.jl")
# include("solution.jl")

# function parse_commandline(args_array::Array{String,1}, appfolder::String)
#    s = ArgParseSettings(usage="##### VRPSolver #####\n\n"*
# 	   "  On interactive mode, call main([\"arg1\", ..., \"argn\"])", exit_after_help=false)
#    @add_arg_table s begin
#       "instance"
#          help = "Instance file path"
#    end
#    return parse_args(args_array, s)
# end

# function run_hhcrsp(app::Dict{String,Any})

#    println("Application parameters:");
#    for (arg,val) in app
#       println("  $arg  =>  $(repr(val))")
#    end
#    flush(stdout)

#    instance_name = split(basename(app["instance"]), ".")[1]
#    data = readVRPTWData(app["instance"])


#    (model, x) = build_model(data)
#    optimizer = VrpOptimizer(model, app["cfg"], instance_name)
#    set_cutoff!(optimizer, app["ub"])

#    (status, solution_found) = optimize!(optimizer)

#    println("########################################################")
#    if solution_found
#       # sol = getsolution(data, optimizer, x, get_objective_value(optimizer))
#       # print_routes(sol)
#       println("Cost: $(get_objective_value(optimizer))")
#       # if app["out"] != nothing
#          # writesolution(app["out"], sol)
#       # end
#    else
#       if status == :Optimal
#          println("Problem infeasible")
#       else
#          println("Solution not found")
#       end
#    end
#    println("########################################################")
# end

# function main(args)
#    appfolder = dirname(@__FILE__)
#    app = parse_commandline(args, appfolder)
#    isnothing(app) && return
#    run_hhcrsp(app)
# end

# if isempty(ARGS)
#    main(["--help"])
# else
#    main(ARGS)
# end

function runVRPSolver(data_path::String, ub::Float64 = Inf64)
   println("--- VRPSolver-based algorithm for VRPTW (HHCRSP) ---")
   println("Data path: $data_path")
   println("Upper bound known: $ub")
   data = readVRPTWData(data_path)

   println("Number of patients: $(data.inst.num_nodes-2)")
   println("Number of vehicles: $(data.inst.num_vehicles)")
   println("Expanded number of nodes: $(length(data.node_map)-1)")

   println("\nBuilding VRPTW model...")
   (model, x) = build_model(data)
   optimizer = VrpOptimizer(model, "./config/HHCRSP.cfg", "mankowska")

   println()
   if ub < Inf64
      println("Set cutoff of $(ub).")
      set_cutoff!(optimizer, ub)
   end
   println("\nOptimizing the problem...")

   runtime = @elapsed begin
      (status, solution_found) = optimize!(optimizer)
   end

   println("\nOptimization finished!")
   println("Time consumed (build+solve): $runtime secs")
   println("Solver status: $status")
   println("A solutions was found? $(solution_found)")
   if solution_found
      cost = get_objective_value(optimizer)
      println("Solution value: $(cost)")
   end

   println("\n\n# Solution for $data_path")
   println("# Cost = $(get_objective_value(optimizer))")
   println("# <vehicle>")
   println("# <node ID> <patient ID> <svc ID>")
   println("# Routes finish with '-1'")
   for k in 1:data.inst.num_vehicles
      id_last = 1
      nk = nodesK(data, k)
      ak = arcsK(data, k)

      println(k)
      println("1 1 1")
      while true
         for i in nk
            arc = (id_last, i)
            if arc in ak
               val = get_value(optimizer, x[arc,k])
               if val > 0.5
                  print("$i ")
                  (p,s) = data.node_rev[i]
                  println("$p $s")
                  id_last = i
                  break
               end
            end
         end

         id_last != 1 || break
      end
      println("-1")

      # for a in arcsK(data, k)
      #    val = get_value(optimizer, x[a,k])
      #    if val > 0.5
      #       println("   $(a[1]-1) -> $(a[2]-1)")
      #    end
      # end
   end


end
