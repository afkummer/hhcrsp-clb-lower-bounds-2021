#!/usr/bin/env julia

using CPLEX, JuMP

include("data.jl")

function build_model_cplex(data::DataVRPTW)
   # Prepare the model data.
   K = [k for k in 1:data.inst.num_vehicles]
   svc = [i for i in 2:length(data.node_map)]
   vehi_nodes = [nodesK(data,k) for k in K]
   vehi_arcs = [arcsK(data, k) for k in K]

   # Create model variables.
   m = Model(solver = CplexSolver())
   @variable(m, x[k in K, (i,j) in vehi_arcs[k]], Bin)
   @variable(m, t[k in K, i in vehi_nodes[k]], lowerbound=tw_min(data, i), upperbound=tw_max(data, i))

   # Add variable names
   for k in K
      for (i,j) in vehi_arcs[k]
         p_i, s_i = data.node_rev[i]
         p_j, s_j = data.node_rev[j]
         setname(x[k,(i,j)], "x#$(i-1)#$(j-1)#$(k-1)")
      end
      for i in vehi_nodes[k]
         p_i, s_i = data.node_rev[i]
         setname(t[k,i], "t#$(i-1)#$(k-1)")
      end
   end

   # Add objective function
   @objective(m, Min, sum(arc_cost(data, k, a) * x[k,a] for k in K, a in vehi_arcs[k]))

   # Source and sink flow constraints.
   @constraint(m, source[k in K], sum(x[k,a] for a in vehi_arcs[k] if a[1] == 1) == 1.0)
   @constraint(m, sink[k in K], sum(x[k,a] for a in vehi_arcs[k] if a[2] == 1) == 1.0)

   # Flow conservation constraints.
   @constraint(m, flow_cons[k in K, i in vehi_nodes[k][2:end]],
      sum(x[k,a] for a in vehi_arcs[k] if a[2] == i) == sum(x[k,a] for a in vehi_arcs[k] if a[1] == i)
   )

   # Assignment constraints
   @constraint(m, asg[j in svc], sum(x[k,a] for k in K, a in vehi_arcs[k] if a[2] == j) == 1.0)

   # Sub tour elimination constraints.
   @constraint(m, subtour_elim[k in K, i in vehi_nodes[k], j in vehi_nodes[k][2:end]; i != j],
      t[k,i] + travel_and_svc_time(data, i, j) <= t[k,j] + 5e5*(1-x[k, (i,j)])
   )

   writeLP(m, "model_cplex.lp", genericnames=false)
   solve(m)

   return m
end

function runCPLEXSolver(file_path::String)
   data = readVRPTWData(file_path)
   m = build_model_cplex(data)
   println("Objective value: ", getobjectivevalue(m))
end
