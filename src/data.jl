#!/usr/bin/env julia

import Base.show, Base.print

#
# Structures and funtions for handling Mankowksa instance data.
#

@enum SvcType depot single simult predec

mutable struct MankowkaInstance
   num_nodes::Int
   num_vehicles::Int
   num_services::Int

   svc_reqs::Array{Bool, 2}
   ds_nodes::Array{Int,1}
   vehi_qualification::Array{Bool, 2}

   node_types::Array{SvcType, 1}
   node_pos::Array{Tuple{Int,Int}, 1}
   distances::Array{Float64, 2}
   proc_times::Array{Float64, 3}

   separation_delta::Array{Tuple{Int,Int}, 1}
   node_tw::Array{Tuple{Int,Int}, 1}
end

function mankowska_instance_init(num_nodes::Int, num_vehicles::Int, num_services::Int)
   svc_reqs = fill(false, num_nodes, num_services)
   ds_nodes = Array{Int, 1}()
   vehi_qualification = fill(false, num_vehicles, num_services)

   node_types = fill(depot, num_nodes)
   node_pos = fill((0, 0), num_nodes)
   distances = fill(Inf64, num_nodes, num_nodes)
   proc_times = fill(Inf64, num_nodes, num_vehicles, num_services)

   separation_delta = fill((0, 0), num_nodes)
   node_tw = fill((0, 0), num_nodes)

   MankowkaInstance(
      num_nodes,
      num_vehicles,
      num_services,
      svc_reqs,
      ds_nodes,
      vehi_qualification,
      node_types,
      node_pos,
      distances,
      proc_times,
      separation_delta,
      node_tw
   )
end

function mankowska_instance_read(filename::AbstractString)
   inst = nothing
   num_nodes = nothing
   num_vehicles = nothing
   num_services = nothing
   pos_x = Array{Int, 1}()
   pos_y = Array{Int, 1}()
   mind = Array{Int, 1}()
   maxd = Array{Int, 1}()
   tmin = Array{Int, 1}()
   tmax = Array{Int, 1}()

   open(filename, "r") do io
      while eof(io) == false
         sect = readline(io)
         if sect == "nbNodes"
            num_nodes = parse(Int, readline(io))
         elseif sect == "nbVehi"
            num_vehicles = parse(Int, readline(io))
         elseif sect == "nbServi"
            num_services = parse(Int, readline(io))
            inst = mankowska_instance_init(num_nodes, num_vehicles, num_services)
         elseif sect == "r"
            for i in 1:inst.num_nodes
               tks = split(readline(io), " ", keepempty=false)
               for s in 1:inst.num_services
                  inst.svc_reqs[i,s] = parse(Bool, tks[s])
               end
            end
         elseif sect == "DS"
            tks = split(readline(io), " ", keepempty=false)
            for i in tks
               inst.ds_nodes = push!(inst.ds_nodes, parse(Int, i))
            end
         elseif sect == "a"
            for v in 1:inst.num_vehicles
               tks = split(readline(io), " ", keepempty=false)
               for s in 1:inst.num_services
                  inst.vehi_qualification[v,s] = parse(Bool, tks[s])
               end
            end
         elseif sect == "x"
            tks = split(readline(io), " ", keepempty=false)
            for i in 1:inst.num_nodes
               pos_x = push!(pos_x, parse(Int, tks[i]))
            end
         elseif sect == "y"
            tks = split(readline(io), " ", keepempty=false)
            for i in 1:inst.num_nodes
               pos_y = push!(pos_y, parse(Int, tks[i]))
            end
            for i in 1:inst.num_nodes
               inst.node_pos[i] = (pos_x[i], pos_y[i])
            end
         elseif sect == "d"
            for i in 1:inst.num_nodes
               tks = split(readline(io), " ", keepempty=false)
               for j in 1:inst.num_nodes
                  inst.distances[i,j] = parse(Float64, tks[j])
               end
            end
         elseif sect == "p"
            for i in 1:inst.num_nodes
               for v in 1:inst.num_vehicles
                  tks = split(readline(io), " ", keepempty=false)
                  for s in 1:inst.num_services
                     inst.proc_times[i,v,s] = parse(Float64, tks[s])
                  end
               end
            end
         elseif sect == "mind"
            tks = split(readline(io), " ", keepempty=false)
            for i in 1:inst.num_nodes
               mind = push!(mind, parse(Int, tks[i]))
            end
         elseif sect == "maxd"
            tks = split(readline(io), " ", keepempty=false)
            for i in 1:inst.num_nodes
               maxd = push!(maxd, parse(Int, tks[i]))
            end
            for i in 1:inst.num_nodes
               inst.separation_delta[i] = (mind[i], maxd[i])
            end
         elseif sect == "e"
            tks = split(readline(io), " ", keepempty=false)
            for i in 1:inst.num_nodes
               tmin = push!(tmin, parse(Int, tks[i]))
            end
         elseif sect == "l"
            tks = split(readline(io), " ", keepempty=false)
            for i in 1:inst.num_nodes
               tmax = push!(tmax, parse(Int, tks[i]))
            end
            for i in 1:inst.num_nodes
               inst.node_tw[i] = (tmin[i], tmax[i])
            end
         else
            println("ERROR: Problem during instance parsing.")
            error("Unknown data section: $(sect)")
         end
      end
   end
   return inst
end

function show(io::IO, inst::MankowkaInstance)
   println("nbNodes\n$(inst.num_nodes)")
   println("nbVehi\n$(inst.num_vehicles)")
   println("nbServi\n$(inst.num_services)")

   println("r")
   for i in 1:inst.num_nodes
      for s in 1:inst.num_services
         print("$(Int(inst.svc_reqs[i,s])) ")
      end
      println()
   end

   println("DS")
   for i in inst.ds_nodes
      print("$(i) ")
   end
   println()

   println("a")
   for v in 1:inst.num_vehicles
      for s in 1:inst.num_services
         print("$(Int(inst.vehi_qualification[v,s])) ")
      end
      println()
   end

   println("x")
   for i in 1:inst.num_nodes
      print("$(inst.node_pos[i][1]) ")
   end
   println("\ny")
   for i in 1:inst.num_nodes
      print("$(inst.node_pos[i][2]) ")
   end

   println("\nd")
   for i in 1:inst.num_nodes
      for j in 1:inst.num_nodes
         print("$(inst.distances[i,j]) ")
      end
      println()
   end

   println("p")
   for i in 1:inst.num_nodes
      for v in 1:inst.num_vehicles
         for s in 1:inst.num_services
            print("$(inst.proc_times[i,v,s]) ")
         end
         println()
      end
   end

   println("mind")
   for i in 1:inst.num_nodes
      print("$(inst.separation_delta[i][1]) ")
   end

   println("\nmaxd")
   for i in 1:inst.num_nodes
      print("$(inst.separation_delta[i][2]) ")
   end

   println("\ne")
   for i in 1:inst.num_nodes
      print("$(inst.node_tw[i][1]) ")
   end

   println("\nl")
   for i in 1:inst.num_nodes
      print("$(inst.node_tw[i][2]) ")
   end
end

#
# Structures and conversion routines for the VRPTW.
#

mutable struct Vertex
   id_patient::Int
   id_vertex::Int
   svc::Int
   service_time::Int
   start_tw::Int
   end_tw::Int
end

# Directed graph
mutable struct InputGraph
   V::Array{Vertex} # set of vertices
   A::Array{Tuple{Int64,Int64}} # set of edges
end

mutable struct DataVRPTW
   inst::MankowkaInstance
   G::InputGraph

   # (node,skill) -> plain index
   node_map::Dict{Tuple{Int, Int}, Int}

   # plain index -> (node,skill)
   node_rev::Dict{Int, Tuple{Int, Int}}
end

function readVRPTWData(path_file::String)
   inst = mankowska_instance_read(path_file)

   function build_mapping()
      # (node,skill) -> plain index
      node_map = Dict{Tuple{Int, Int}, Int}()

      # plain index -> (node,skill)
      node_rev = Dict{Int, Tuple{Int, Int}}()

      # Add the depot node.
      node_map[(1,1)] = 1
      node_rev[1] = (1,1)

      # Duplicate double service nodes.
      id_gen = 2
      for i in 2:inst.num_nodes-1
         for s in 1:inst.num_services
            if inst.svc_reqs[i,s]
               node_map[(i,s)] = id_gen
               node_rev[id_gen] = (i,s)
               id_gen += 1
            end
         end
      end

      return node_map, node_rev
   end

   # Create the mapping of HHCRSP nodes to VRPTW nodes.
   node_map, node_rev = build_mapping()

   function build_graph()
      V = Array{Vertex, 1}()
      A = Array{Tuple{Int64,Int64}, 1}()
      push!(A, (1,1))

      for i in 1:length(node_map)
         id_patient, svc = node_rev[i]
         vtx = Vertex(id_patient, i, svc, inst.proc_times[id_patient, 1, svc], inst.node_tw[id_patient][1], inst.node_tw[id_patient][2])
         push!(V, vtx)
      end

      # Create the arcs of the graph, including sink and source.
      for i in 2:length(node_map)
         push!(A, (1, i))
         push!(A, (i, 1))

         for j in 2:length(node_map)
            if i != j
               push!(A, (i,j))
            end
         end
      end

      G = InputGraph(V,A)
      return G
   end

   # Create the graph used by all vehicles.
   G = build_graph()

   # Returns the complete data structure that models the VRPTW.
   return DataVRPTW(inst, G, node_map, node_rev)
end

# service type-sensible query functions
# all vehicles share the arc IDs
function nodesK(data::DataVRPTW, k::Int)
   nodes = Int[1]
   for i in 2:length(data.node_map)
      id_patient, svc = data.node_rev[i]
      if data.inst.vehi_qualification[k,svc]
         push!(nodes, i)
      end
   end
   return nodes
end

function arcsK(data::DataVRPTW, k::Int)
   nodes = nodesK(data, k)
   arcs = Tuple{Int64,Int64}[(1,1)]
   for i in nodes[2:end]
      push!(arcs, (1,i))
      push!(arcs, (i,1))
      for j in nodes[2:end]
         if i != j
            push!(arcs, (i,j))
         end
      end
   end

   return arcs
end

function nodes_all(data::DataVRPTW)
   nodes = Int[1]
   for i in 2:length(data.node_map)
      id_patient, svc = data.node_rev[i]
      push!(nodes, i)
   end
   return nodes
end

function arcs_all(data::DataVRPTW)
   nodes = nodes_all(data)
   arcs = Tuple{Int64,Int64}[(1,1)]
   for i in nodes[2:end]
      push!(arcs, (1,i))
      push!(arcs, (i,1))
      for j in nodes[2:end]
         if i != j
            push!(arcs, (i,j))
         end
      end
   end

   return arcs
end

# helper functions with more meaningful names

function arc_cost(data::DataVRPTW, k::Int, i::Int, j::Int)
   patient_i, _ = data.node_rev[i]
   patient_j, svc_j = data.node_rev[j]

   if patient_j != 1 && !data.inst.vehi_qualification[k,svc_j]
      #error("Querying cost for a vehicle without qualification: arc=($(i),$(j)) vehi=$(k)")
      return 1e6
   end

   # return 1.0
   return 1.0/3.0 * data.inst.distances[patient_i, patient_j]
end

function arc_cost(data::DataVRPTW, k::Int, a::Tuple{Int64,Int64})
   return arc_cost(data ,k, a[1], a[2])
end

function travel_and_svc_time(data::DataVRPTW, i::Int, j::Int)
   patient_i, svc_i = data.node_rev[i]
   patient_j, svc_j = data.node_rev[j]
   return Float64(data.inst.distances[patient_i, patient_j] + data.inst.proc_times[patient_j,1,svc_j])
end

function travel_and_svc_time(data::DataVRPTW, a::Tuple{Int64,Int64})
   return travel_and_svc_time(data, a[1], a[2])
end

arcs(data::DataVRPTW) = data.G.A # return set of arcs

function distance(data::DataVRPTW, i::Int64, j::Int64)
   a = data.G.V[i]
   b = data.G.V[j]

   return data.inst.distances[a.id_patient, b.id_patient]
end

function distance(data::DataVRPTW, a::Tuple{Int64,Int64})
   return distance(data, a[1], a[2])
end

function c(data::DataVRPTW, k::Int, a::Tuple{Int64, Int64})
   # if !(haskey(data.G.A, a))
   #    return Inf
   # end

   i = data.G.V[a[1]]
   j = data.G.V[a[2]]

   if !data.inst.vehi_qualification[k, j.svc]
      return 1e6
   end

   # 1/3 is the fixed coeficient used by Mankowska and others with the HHCRSP dataset.
   return 1.0/3.0 * data.inst.distances[i.id_patient, j.id_patient]
end

function t(data::DataVRPTW, a::Tuple{Int64, Int64})
   # if !(haskey(data.G.A, a))
   #    return Inf
   # end

   i = data.G.V[a[1]]
   j = data.G.V[a[2]]

   return data.inst.distances[i.id_patient, j.id_patient] + data.inst.proc_times[j.id_patient, 1, j.svc]
end

n(data::DataVRPTW) = length(data.G.V) # return number of requests

d(data::DataVRPTW, i::Int) = Int(1) # return demand of i

tw_min(data::DataVRPTW, i::Int) = data.inst.node_tw[data.G.V[i].id_patient][1]

tw_max(data::DataVRPTW, i::Int) = data.inst.node_tw[data.G.V[i].id_patient][2]

l(data::DataVRPTW, i::Int) = data.inst.node_tw[data.G.V[i].id_patient][1]

u(data::DataVRPTW, i::Int) = data.inst.node_tw[data.G.V[i].id_patient][2]

veh_capacity(data::DataVRPTW) = length(data.G.V)

function lowerBoundNbVehicles(data::DataVRPTW)
   return 0
   # return data.inst.num_vehicles #???
end

function upperBoundNbVehicles(data::DataVRPTW)
   return 1
   return data.inst.num_vehicles
end

# mutable struct Node
#    id_patient::Int
#    id_vertex::Int
#    svc::Int
#    proc_time::Int
#    separation_delta::Tuple{Int, Int}
#    tw::Tuple{Int, Int}
# end

# function show(io::IO, n::Node)
#    print("Node [id_patient=$(n.id_patient) id_vertex=$(n.id_vertex) svc=$(n.svc) proc_time=$(n.proc_time) ")
#    print("separation_delta=($(n.separation_delta[1]),$(n.separation_delta[2])), ")
#    println("tw=($(n.tw[1]),$(n.tw[2]))]")
# end

# mutable struct InputGraph
#    V::Array{Node} # set of nodes/patients
#    E::Array{Tuple{Node,Node}} # set of edges
# end

# function show(io::IO, graph::InputGraph)
#    println("Graph edges: ")
#    for e in graph.E
#       println("$(e[1].id_patient)--$(e[2].id_patient)")
#    end
# end

# mutable struct DataHHCRSP
#    inst::MankowkaInstance
#    G::InputGraph
#    node_map::Dict{Tuple{Int, Int}, Int}
#    node_rev::Dict{Int, Tuple{Int, Int}}
# end

# function readHHCRSPData(filename::AbstractString)
#    inst = mankowska_instance_read(filename)
#    nodes = Array{Node, 1}()
#    push!(nodes, Node(1, 1, 1, 0, (0,0), (0,1000)))

#    # First we need to duplicate double service patients, to then
#    # create the so-called InputGraph used in the models.
#    id_gen = 2

#    # (node,skill) -> plain index
#    node_map = Dict{Tuple{Int, Int}, Int}()

#    # plain index -> (node,skill)
#    node_rev = Dict{Int, Tuple{Int, Int}}()

#    for i in 2:inst.num_nodes-1
#       dup = false
#       for s in 1:inst.num_services
#          if inst.svc_reqs[i,s]
#             n = Node(i, 99999, s, inst.proc_times[i,1,s], inst.separation_delta[i], inst.node_tw[i])
#             n.id_vertex = id_gen
#             node_map[(i,s)] = id_gen
#             node_rev[id_gen] = (i,s)
#             push!(nodes, n)
#             id_gen += 1
#          end
#       end
#    end

#    edges = Array{Tuple{Node,Node}, 1}()
#    for i in nodes
#       for j in nodes
#          if i.id_patient == 1 || i.id_patient != j.id_patient
#             push!(edges, (i, j))
#             if j.id_patient != 1
#                push!(edges, (j, i))
#             end
#          end
#       end
#    end

#    graph = InputGraph(nodes, edges)
#    data = DataHHCRSP(inst, graph, node_map, node_rev)

#    return data
# end