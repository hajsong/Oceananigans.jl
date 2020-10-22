# # Eady turbulence example
#
# In this example, we initialize a random velocity field and observe its viscous,
# turbulent decay in a two-dimensional domain. This example demonstrates:
#
#   * How to use a tuple of turbulence closures
#   * How to use biharmonic diffusivity
#   * How to implement background velocity and tracer distributions
#   * How to use `ComputedField`s for output
#
# ## The Eady problem 
#
# The "Eady problem" simulates the baroclinic instability problem proposed by Eric Eady in
# the classic paper
# ["Long waves and cyclone waves," Tellus (1949)](https://www.tandfonline.com/doi/abs/10.3402/tellusa.v1i3.8507).
# The Eady problem is a simple, canonical model for the generation of mid-latitude
# atmospheric storms and the ocean eddies that permeate the world sea.
#
# In the Eady problem, baroclinic motion and turublence is generated by the interaction
# between turbulent motions and a stationary, geostrophically-balanced basic state that
# is unstable to baroclinic instability. In this example, the baroclinic generation of
# turbulence due to extraction of energy from the geostrophic basic state
# is balanced by a bottom boundary condition that extracts momentum from turbulent motions
# and serves as a crude model for the drag associated with an unresolved and small-scale
# turbulent bottom boundary layer.
# 
# ### The geostrophic basic state
#
# The geostrophic basic state in the Eady problem is represented by the streamfunction,
#
# $ ψ(y, z) = - α y (z + L_z) \, ,$
#
# where $α$ is the geostrophic shear and $L_z$ is the depth of the domain.
# The background buoyancy includes both the geostrophic flow component,
# $f ∂_z ψ$, where $f$ is the Coriolis parameter, and a background stable stratification
# component, $N^2 z$, where $N$ is the buoyancy frequency:
#
# $ B(y, z) = f ∂_z ψ + N^2 z = - α f y + N^2 z \, .$
#
# The background velocity field is related to the geostrophic streamfunction via
# $ U = - ∂_y ψ$ such that
#
# $ U(z) = α (z + L_z) \, .$
#
# ### Boundary conditions
#
# All fields are periodic in the horizontal directions.
# We use "insulating", or zero-flux boundary conditions on the buoyancy perturbation
# at the top and bottom. We thus implicitly assume that the background vertical density
# gradient, $N^2 z$, is maintained by a process external to our simulation.
# We use free-slip, or zero-flux boundary conditions on $u$ and $v$ at the surface
# where $z=0$. At the bottom, we impose a momentum flux that extracts momentum and
# energy from the flow.
#
# #### Bottom boundary condition: quadratic bottom drag
#
# We model the effects of a turbulent bottom boundary layer on the eddy momentum budget
# with quadratic bottom drag. A quadratic cottom drag is introduced by imposing a vertical flux
# of horizontal momentum that removes momentum from the layer immediately above: in other words,
# the flux is negative (downwards) when the velocity at the bottom boundary is positive, and 
# positive (upwards) with the velocity at the bottom boundary is negative.
# This drag term is "quadratic" because the rate at which momentum is removed is proportional
# to $\boldsymbol{u}_h |\boldsymbol{u}_h|$, where 
# $\boldsymbol{u}_h = u \boldsymbol{\hat{x}} + v \boldsymbol{\hat{y}}$ is the horizontal velocity.
#
# The $x$-component of the quadratic bottom drag is thus
# 
# ```math
# \tau_{xz}(z=L_z) = - c^D u \sqrt{u^2 + v^2} \, ,
# ```
#
# while the $y$-component is
#
# ```math
# \tau_{yz}(z=L_z) = - c^D v \sqrt{u^2 + v^2} \, , 
# ```
#
# where $c^D$ is a dimensionless drag coefficient and $\tau_{xz}(z=L_z)$ and $\tau_{yz}(z=L_z)$
# denote the flux of $u$ and $v$ momentum at $z = L_z$, the bottom of the domain.
#
# ### Vertical and horizontal viscosity and diffusivity
#
# Vertical and horizontal viscosties and diffusivities are required
# to stabilize the Eady problem and can be idealized as modeling the effect of
# turbulent mixing below the grid scale. For both tracers and velocities we use
# a Laplacian vertical diffusivity $κ_z ∂_z^2 c$ and a biharmonic horizontal
# diffusivity $ϰ_h (∂_x^4 + ∂_y^4) c$. 
#
# ### Eady problem summary and parameters
#
# To summarize, the Eady problem parameters along with the values we use in this example are
#
# | Parameter name | Description | Value | Units |
# | -------------- | ----------- | ----- | ----- | 
# | $ f $          | Coriolis parameter | $ 10^{-4} $ | $ \mathrm{s^{-1}} $ |
# | $ N $          | Buoyancy frequency (square root of $\partial_z B$) | $ 10^{-3} $ | $ \mathrm{s^{-1}} $ |
# | $ \alpha $     | Background vertical shear $\partial_z U$ | $ 10^{-3} $ | $ \mathrm{s^{-1}} $ |
# | $ c^D $        | Bottom quadratic drag coefficient | $ 10^{-4} $ | none |
# | $ κ_z $    | Laplacian vertical diffusivity | $ 10^{-2} $ | $ \mathrm{m^2 s^{-1}} $ |
# | $ \varkappa_h $    | Biharmonic horizontal diffusivity | $ 10^{-2} \times \Delta x^4 / \mathrm{day} $ | $ \mathrm{m^4 s^{-1}} $ |
#
# We start off by importing `Oceananigans`, some convenient aliases for dimensions, and a function
# that generates a pretty string from a number that represents 'time' in seconds:

using Oceananigans, Printf
using Oceananigans.Utils: hour, day, prettytime

# ## The grid
#
# We use a three-dimensional grid with a depth of 4000 m and a 
# horizontal extent of 1000 km, appropriate for mesoscale ocean dynamics
# with characteristic scales of 50-200 km.

grid = RegularCartesianGrid(size=(48, 48, 16), x=(0, 1e6), y=(0, 1e6), z=(-4e3, 0))

# ## Rotation
#
# The classical Eady problem is posed on an $f$-plane. We use a Coriolis parameter
# typical to mid-latitudes on Earth,

coriolis = FPlane(f=1e-4) # [s⁻¹]
                            
# ## The background flow
#
# We build a `NamedTuple` of parameters that describe the background flow,

background_parameters = ( α = 10 * coriolis.f, # s⁻¹, geostrophic shear
                          f = coriolis.f,      # s⁻¹, Coriolis parameter
                          N = 1e-3,            # s⁻¹, buoyancy frequency
                         Lz = grid.Lz)         # m, ocean depth

# and then construct the background fields $U$ and $B$

using Oceananigans.Fields: BackgroundField

## Background fields are defined via functions of x, y, z, t, and optional parameters
U(x, y, z, t, p) = + p.α * (z + p.Lz)
B(x, y, z, t, p) = - p.α * p.f * y + p.N^2 * z

U_field = BackgroundField(U, parameters=background_parameters)
B_field = BackgroundField(B, parameters=background_parameters)

# ## Boundary conditions
#
# These boundary conditions prescribe a quadratic drag at the bottom as a flux
# condition. We also fix the surface and bottom buoyancy to enforce a buoyancy
# gradient `N^2`.

drag_coefficient = 1e-4

@inline drag_u(u, v, cᴰ) = - cᴰ * sqrt(u^2 + v^2) * u
@inline drag_v(u, v, cᴰ) = - cᴰ * sqrt(u^2 + v^2) * v

@inline bottom_drag_u(i, j, grid, clock, f, cᴰ) = @inbounds drag_u(f.u[i, j, 1], f.v[i, j, 1], cᴰ)
@inline bottom_drag_v(i, j, grid, clock, f, cᴰ) = @inbounds drag_v(f.u[i, j, 1], f.v[i, j, 1], cᴰ)
    
drag_bc_u = BoundaryCondition(Flux, bottom_drag_u, discrete_form=true, parameters=drag_coefficient)
drag_bc_v = BoundaryCondition(Flux, bottom_drag_v, discrete_form=true, parameters=drag_coefficient)

u_bcs = UVelocityBoundaryConditions(grid, bottom = drag_bc_u) 
v_bcs = VVelocityBoundaryConditions(grid, bottom = drag_bc_v)

# ## Turbulence closures
#
# We use a horizontal biharmonic diffusivity and a Laplacian vertical diffusivity
# to dissipate energy in the Eady problem.
# To use both of these closures at the same time, we set the keyword argument
# `closure` to a tuple of two closures.

κ₂z = 1e-2 # [m² s⁻¹] Laplacian vertical viscosity and diffusivity
κ₄h = 1e-1 / day * grid.Δx^4 # [m⁴ s⁻¹] biharmonic horizontal viscosity and diffusivity

Laplacian_vertical_diffusivity = AnisotropicDiffusivity(νh=0, κh=0, νz=κ₂z, κz=κ₂z)
biharmonic_horizontal_diffusivity = AnisotropicBiharmonicDiffusivity(νh=κ₄h, κh=κ₄h)

# ## Model instantiation
#
# We instantiate the model with the fifth-order WENO advection scheme, a 3rd order
# Runge-Kutta time-stepping scheme, and a `BuoyancyTracer`.

using Oceananigans.Advection: WENO5

model = IncompressibleModel(
           architecture = CPU(),
                   grid = grid,
              advection = WENO5(),
            timestepper = :RungeKutta3,
               coriolis = coriolis,
                tracers = :b,
               buoyancy = BuoyancyTracer(),
      background_fields = (b=B_field, u=U_field),
                closure = (Laplacian_vertical_diffusivity, biharmonic_horizontal_diffusivity),
    boundary_conditions = (u=u_bcs, v=v_bcs)
)

# ## Initial conditions
#
# We use non-trivial initial conditions consisting of an array of vortices superposed
# with large-amplitude noise to (hopefully) stimulate the rapid growth of
# baroclinic instability.

## A noise function, damped at the top and bottom
Ξ(z) = randn() * z/grid.Lz * (z/grid.Lz + 1)

## Scales for the initial velocity and buoyancy
Ũ = 1e-1 * background_parameters.α * grid.Lz
B̃ = 1e-2 * background_parameters.α * coriolis.f

uᵢ(x, y, z) = Ũ * Ξ(z)
vᵢ(x, y, z) = Ũ * Ξ(z)
bᵢ(x, y, z) = B̃ * Ξ(z)

set!(model, u=uᵢ, v=vᵢ, b=bᵢ)

# We subtract off any residual mean velocity to avoid exciting domain-scale
# inertial oscillations. We use a `sum` over the entire `parent` arrays or data
# to ensure this operation is efficient on the GPU (set `architecture = GPU()`
# in `IncompressibleModel` constructor to run this problem on the GPU if one
# is available).

Ū = sum(model.velocities.u.data.parent) / (grid.Nx * grid.Ny * grid.Nz)
V̄ = sum(model.velocities.v.data.parent) / (grid.Nx * grid.Ny * grid.Nz)

model.velocities.u.data.parent .-= Ū
model.velocities.v.data.parent .-= V̄
nothing # hide

# ## Simulation set-up
#
# We set up a simulation that runs for 10 days with a `JLD2OutputWriter` that saves the
# vertical vorticity and divergence every 2 hours.
#
# ### The `TimeStepWizard`
#
# The TimeStepWizard manages the time-step adaptively, keeping the CFL close to a
# desired value.

## Calculate absolute limit on time-step using diffusivities and 
## background velocity.
Ū = background_parameters.α * grid.Lz

max_Δt = min(grid.Δx / Ū, grid.Δx^4 / κ₄h, grid.Δz^2 / κ₂z)

wizard = TimeStepWizard(cfl=1.0, Δt=0.1*max_Δt, max_change=1.1, max_Δt=max_Δt)

# ### A progress messenger
#
# We write a function that prints out a helpful progress message while the simulation runs.

using Oceananigans.Diagnostics: AdvectiveCFL

CFL = AdvectiveCFL(wizard)

start_time = time_ns()

progress(sim) = @printf("i: % 6d, sim time: % 10s, wall time: % 10s, Δt: % 10s, CFL: %.2e\n",
                        sim.model.clock.iteration,
                        prettytime(sim.model.clock.time),
                        prettytime(1e-9 * (time_ns() - start_time)),
                        prettytime(sim.Δt.Δt),
                        CFL(sim.model))

# ### Build the simulation
#
# We're ready to build and run the simulation. We ask for a progress message and time-step update
# every 20 iterations,

simulation = Simulation(model, Δt = wizard, iteration_interval = 20,
                                                     stop_time = 10day,
                                                      progress = progress)

# ### Output
#
# To visualize the baroclinic turbulence ensuing in the Eady problem,
# we use `ComputedField`s to diagnose and output vertical vorticity and divergence.
# Note that `ComputedField`s take "AbstractOperations" on `Field`s as input:

using Oceananigans.AbstractOperations
using Oceananigans.Fields: ComputedField

u, v, w = model.velocities # unpack velocity `Field`s

## Vertical vorticity [s⁻¹]
ζ = ComputedField(∂x(v) - ∂y(u))

## Horizontal divergence, or ∂x(u) + ∂y(v) [s⁻¹]
δ = ComputedField(-∂z(w))
nothing # hide

# With the vertical vorticity, `ζ`, and the horizontal divergence, `δ` in hand,
# we create a `JLD2OutputWriter` that saves `ζ` and `δ` and add it to 
# `simulation`.

using Oceananigans.OutputWriters: JLD2OutputWriter, TimeInterval

simulation.output_writers[:fields] = JLD2OutputWriter(model, (ζ=ζ, δ=δ),
                                                      schedule = TimeInterval(2hour),
                                                        prefix = "eady_turbulence",
                                                         force = true)
nothing # hide

# All that's left is to press the big red button:

run!(simulation)

# ## Visualizing Eady turbulence
#
# We animate the results by opening the JLD2 file, extracting data for
# the iterations we ended up saving at, and ploting slices of the saved
# fields. We prepare for animating the flow by creating coordinate arrays,
# opening the file, building a vector of the iterations that we saved
# data at, and defining a function for computing colorbar limits: 

using JLD2, Plots

using Oceananigans.Grids: nodes, x_domain, y_domain, z_domain # for nice domain limits

## Coordinate arrays
xζ, yζ, zζ = nodes(ζ)
xδ, yδ, zδ = nodes(δ)

## Open the file with our data
file = jldopen(simulation.output_writers[:fields].filepath)

## Extract a vector of iterations
iterations = parse.(Int, keys(file["timeseries/t"]))

# This utility is handy for calculating nice contour intervals:

function nice_divergent_levels(c, clim, nlevels=30)
    levels = range(-clim, stop=clim, length=nlevels)

    cmax = maximum(abs, c)
    if clim < cmax # add levels on either end
        levels = vcat([-cmax], range(-clim, stop=clim, length=nlevels), [cmax])
    end

    return levels
end

# Now we're ready to animate.

@info "Making an animation from saved data..."

anim = @animate for (i, iter) in enumerate(iterations)

    ## Load 3D fields from file
    t = file["timeseries/t/$iter"]
    R = file["timeseries/ζ/$iter"] ./ coriolis.f
    δ = file["timeseries/δ/$iter"]

    surface_R = R[:, :, grid.Nz]
    surface_δ = δ[:, :, grid.Nz]

    slice_R = R[:, 1, :]
    slice_δ = δ[:, 1, :]

    Rlim = 0.5 * maximum(abs, R) + 1e-9
    δlim = 0.5 * maximum(abs, δ) + 1e-9

    Rlevels = nice_divergent_levels(R, Rlim)
    δlevels = nice_divergent_levels(δ, δlim)

    @info @sprintf("Drawing frame %d from iteration %d: max(ζ̃ / f) = %.3f \n",
                   i, iter, maximum(abs, surface_R))

    R_xy = contourf(xζ, yζ, surface_R';
                    aspectratio = 1,
                      linewidth = 0,
                          color = :balance,
                         legend = false,
                          clims = (-Rlim, Rlim),
                         levels = Rlevels,
                          xlims = (0, grid.Lx),
                          ylims = (0, grid.Lx),
                         xlabel = "x (m)",
                         ylabel = "y (m)")
    
    δ_xy = contourf(xδ, yδ, surface_δ';
                    aspectratio = 1,
                      linewidth = 0,
                          color = :balance,
                         legend = false,
                          clims = (-δlim, δlim),
                         levels = δlevels,
                          xlims = (0, grid.Lx),
                          ylims = (0, grid.Lx),
                         xlabel = "x (m)",
                         ylabel = "y (m)")

    R_xz = contourf(xζ, zζ, slice_R';
                    aspectratio = grid.Lx / grid.Lz * 0.5,
                      linewidth = 0,
                          color = :balance,
                         legend = false,
                          clims = (-Rlim, Rlim),
                         levels = Rlevels,
                          xlims = (0, grid.Lx),
                          ylims = (-grid.Lz, 0),
                         xlabel = "x (m)",
                         ylabel = "z (m)")

    δ_xz = contourf(xδ, zδ, slice_δ';
                    aspectratio = grid.Lx / grid.Lz * 0.5,
                      linewidth = 0,
                          color = :balance,
                         legend = false,
                          clims = (-δlim, δlim),
                         levels = δlevels,
                          xlims = (0, grid.Lx),
                          ylims = (-grid.Lz, 0),
                         xlabel = "x (m)",
                         ylabel = "z (m)")

    plot(R_xy, δ_xy, R_xz, δ_xz,
           size = (1000, 800),
           link = :x,
         layout = Plots.grid(2, 2, heights=[0.5, 0.5, 0.2, 0.2]),
          title = [@sprintf("ζ(t=%s)/f", prettytime(t)) @sprintf("δ(t=%s) (s⁻¹)", prettytime(t)) "" ""])

    iter == iterations[end] && close(file)
end

mp4(anim, "eady_turbulence.mp4", fps = 8) # hide
