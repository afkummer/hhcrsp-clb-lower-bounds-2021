mutable struct Route
   veh_type::Int
   route::Array{Int}
end

mutable struct Solution
   cost::Union{Int,Float64}
   routes::Array{Route}
end

# build Solution from the variables x
function getsolution(data::DataHVRP, optimizer::VrpOptimizer, x, objval)
   E, dim, K = edges(data), dimension(data), veh_types(data)
   adj_list = [[] for i in 1:dim] 
   veh_type = Dict()
   for e in E
      for k in K
         val = get_value(optimizer, x[e,k])
         if val > 0.5
            veh_type[e[2]] = k
            push!(adj_list[e[1]+1], e[2])
            push!(adj_list[e[2]+1], e[1])
            if val > 1.5
               push!(adj_list[e[1]+1], e[2])
               push!(adj_list[e[2]+1], e[1])
            end
         end
      end
   end
   visited, routes = [false for i in 2:dim], Array{Route,1}()
   for i in adj_list[1]
      if !visited[i]
         r, prev = Route(veh_type[i],[]), 0
         push!(r.route, i)
         visited[i] = true
         length(adj_list[i+1]) != 2 && error("Problem trying to recover the route from the x values. "*
                                             "Customer $i has $(length(adj_list[i+1])) incident edges.")
         next, prev = (adj_list[i+1][1] == prev) ? adj_list[i+1][2] : adj_list[i+1][1], i
         maxit, it = dim, 0
         while next != 0 && it < maxit
            length(adj_list[next+1]) != 2 && error("Problem trying to recover the route from the x values. "* 
                                                   "Customer $next has $(length(adj_list[next+1])) incident edges.")
            push!(r.route, next)
            visited[next] = true
            aux = next
            next, prev = (adj_list[next+1][1] == prev) ? adj_list[next+1][2] : adj_list[next+1][1], aux
            it += 1
         end
         (it == maxit) && error("Problem trying to recover the route from the x values. "*
                                "Some route can not be recovered because the return to depot is never reached")
         push!(routes, r)
      end
   end 
   !isempty(findall(a->a==false,visited)) && error("Problem trying to recover the route from the x values. "*
                              "At least one customer was not visited or there are subtours in the solution x.")
   return Solution(objval, routes)
end

function print_routes(solution)
   for (i,r) in enumerate(solution.routes)
      print("Route #$i type $(r.veh_type): ") 
      for j in r.route
         print("$j ")
      end
      println()
   end
end

# write solution in a file
function writesolution(solpath, solution)
   open(solpath, "w") do f
      for (i,r) in enumerate(solution.routes)
         write(f, "Route #$i type $(r.veh_type):")
         for j in r.route
            write(f, "$j ") 
         end
         write(f, "\n")
      end
      write(f, "Cost $(solution.cost)\n")
   end
end

