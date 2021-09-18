function build_model(data::DataVRPTW)

   A = arcs_all(data)
   n = length(data.node_map)-1
   V = nodes_all(data) # set of vertices of the graphs G′ and G
   V⁺ = V[2:end] # set of customers of the input graph G′
   K = [k for k in 1:data.inst.num_vehicles]

   function getub(k::Int, a::Tuple{Int64,Int64})
      id_pat, id_svc = data.node_rev[a[2]]
      if data.inst.vehi_qualification[k,id_svc]
         return 1.0
      end
      return 0.0
   end

   # Formulation
   vrptw = VrpModel()
   @variable(vrptw.formulation, x[a in A, k in K], Int, upperbound=1)
   @objective(vrptw.formulation, Min, sum(arc_cost(data, k, a) * x[a, k] for a in A, k in K))
   @constraint(vrptw.formulation, indeg[i in V⁺], sum(x[a, k] for k in K, a in arcsK(data, k) if a[2] == i) == 1.0)

   function generate_distinct_vehi_constraints()
      # Returns a list of tuples of nodes representing double service patients.
      ds_nodes = Tuple{Int,Int}[]
      for p in data.inst.ds_nodes
         svcs = Int[]
         for s in 1:data.inst.num_services
            if data.inst.svc_reqs[p,s]
               push!(svcs, s)
            end
         end

         i = data.node_map[(p, svcs[1])]
         j = data.node_map[(p, svcs[2])]

         push!(ds_nodes, (i,j))
      end

      function both_req(k, i, j)
         has_i = data.inst.vehi_qualification[k, data.node_rev[i][2]]
         has_j = data.inst.vehi_qualification[k, data.node_rev[j][2]]
         if has_i && has_j
            return true
         end
         return false
      end

      println("Constraint for distinct vehicles on double services set.")
      @constraint(vrptw.formulation, distinct_vehi[k in K, (i,j) in ds_nodes; both_req(k, i, j) && i < j],
       sum(x[a,k] for a in A if a[2] == i || a[2] == j) <= 1.0)
   end

   # generate_distinct_vehi_constraints()

   # Build the model directed graph G=(V,A)
   function build_graph(k)

      v_source = v_sink = 1
      L, U = lowerBoundNbVehicles(data), upperBoundNbVehicles(data)

      # node ids of G from 0 to n
      G = VrpGraph(vrptw, V, v_source, v_sink, (L, U))

      time_res_id = add_resource!(G, main = true)

      for v in V
         #set_resource_bounds!(G, v, time_res_id, l(data, v), u(data, v))
         set_resource_bounds!(G, v, time_res_id, l(data, v), 10000.0)
      end

      for (i,j) in A
         arc_id = add_arc!(G, i, j)
         add_arc_var_mapping!(G, arc_id, x[(i,j), k])
         set_arc_consumption!(G, arc_id, time_res_id, travel_and_svc_time(data, i, j))
      end

      return G
   end

   graphs = []
   for k in K
      G = build_graph(k)
      add_graph!(vrptw, G)
      #println(G)
      push!(graphs, G)
   end

   set_vertex_packing_sets!(vrptw, [[(G,i) for G in graphs] for i in V⁺])
   for G in graphs
      define_elementarity_sets_distance_matrix!(vrptw, G, [[distance(data, i, j) for j in V⁺] for i in V⁺])
   end

   # We can only branch on decision variables `x`.
   set_branching_priority!(vrptw, "x", 1)

   return (vrptw, x)
end
