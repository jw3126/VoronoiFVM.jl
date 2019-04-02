module OneSpeciesNonlinearPoisson

using Printf
using TwoPointFluxFVM

if isinteractive()
    using PyPlot
end



"""
    Structure containing  userdata information
"""
mutable struct Physics
    flux::Function
    source::Function
    reaction::Function
    storage::Function
    eps::Real
    Physics()=new()
end


"""
Main function for user interaction from REPL and
for test. Default physics need to generate correct
test value.
"""
function main(;n=10,pyplot=false,verbose=false)
    h=1.0/convert(Float64,n)
    grid=TwoPointFluxFVM.Grid(collect(0:h:1))
    
    
    physics=Physics()
    physics.eps=1.0e-2

    physics.flux=function(physics,edge,f,uk,ul)
        f[1]=physics.eps*(uk[1]^2-ul[1]^2)
    end 

    physics.source=function(physics,node,f)
        f[1]=1.0e-4*node.coord[1]
    end 

    physics.storage=function(physics,node, f,u)
        f[1]=u[1]
    end

    physics.reaction=function(physics,node,f,u)
        f[1]=u[1]^2
    end
    
    sys=TwoPointFluxFVM.System(grid,physics,1)
    add_species(sys,1,[1])
    sys.boundary_values[1,1]=1.0
    sys.boundary_values[1,2]=0.5
    
    sys.boundary_factors[1,1]=TwoPointFluxFVM.Dirichlet
    sys.boundary_factors[1,2]=TwoPointFluxFVM.Dirichlet
    
    inival=unknowns(sys)
    inival.=0.5


    control=TwoPointFluxFVM.NewtonControl()
    control.verbose=verbose
    tstep=1.0e-2
    times=collect(0.0:tstep:1.0)
    test_result=0
    for it=2:length(times)
        U=solve(sys,inival,control=control,tstep=tstep)
        test_result=U[5]
        inival.=U
        if verbose
            @printf("time=%g\n",times[it])
        end
        if pyplot
            PyPlot.clf()
            PyPlot.grid()
            plot(grid.nodecoord[1,:],U[1,:])
            pause(1.0e-10)
        end
    end
    return test_result
end

end
