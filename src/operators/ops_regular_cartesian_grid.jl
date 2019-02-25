using Oceananigans:
    RegularCartesianGrid,
    Field, CellField, FaceField, FaceFieldX, FaceFieldY, FaceFieldZ, EdgeField,
    VelocityFields, TracerFields, PressureFields, SourceTerms, ForcingFields,
    OperatorTemporaryFields

# Increment and decrement integer a with periodic wrapping. So if n == 10 then
# incmod1(11, n) = 1 and decmod1(0, n) = 10.
@inline incmod1(a, n) = a == n ? one(a) : a + 1
@inline decmod1(a, n) = a == 1 ? n : a - 1


# function δx!(g::RegularCartesianGrid, f::CellField, δxf::FaceField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δxf.data[i, j, k] =  f.data[i, j, k] - f.data[decmod1(i, g.Nx), j, k]
#     end
#     nothing
# end

"""
    δx!(g::RegularCartesianGrid, f::CellField, δxf::FaceField)

Compute the difference \$\\delta_x(f) = f_E - f_W\$ between the eastern and
western cells of a cell-centered field `f` and store it in a face-centered
field `δxf`, assuming both fields are defined on a regular Cartesian grid `g`
with periodic boundary condition in the \$x\$-direction.
"""
function δx!(g::RegularCartesianGrid, f::CellField, δxf::FaceField)
    @views @. δxf.data[1,     :, :] = f.data[1,     :, :] - f.data[end,     :, :]
    @views @. δxf.data[2:end, :, :] = f.data[2:end, :, :] - f.data[1:end-1, :, :]
    nothing
end

# function δx!(g::RegularCartesianGrid, f::FaceField, δxf::CellField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δxf.data[i, j, k] =  f.data[incmod1(i, g.Nx), j, k] - f.data[i, j, k]
#     end
#     nothing
# end

"""
    δx!(g::RegularCartesianGrid, f::FaceField, δxf::CellField)

Compute the difference \$\\delta_x(f) = f_E - f_W\$ between the eastern and
western faces of a face-centered field `f` and store it in a cell-centered
field `δxf`, assuming both fields are defined on a regular Cartesian grid `g`
with periodic boundary conditions in the \$x\$-direction.
"""
function δx!(g::RegularCartesianGrid, f::FaceField, δxf::CellField)
    @views @. δxf.data[1:end-1, :, :] = f.data[2:end, :, :] - f.data[1:end-1, :, :]
    @views @. δxf.data[end,     :, :] = f.data[1,     :, :] - f.data[end,     :, :]
    nothing
end

# function δx!(g::RegularCartesianGrid, f::EdgeField, δxf::FaceField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δxf.data[i, j, k] =  f.data[incmod1(i, g.Nx), j, k] - f.data[i, j, k]
#     end
#     nothing
# end

function δx!(g::RegularCartesianGrid, f::EdgeField, δxf::FaceField)
    @views @. δxf.data[1:end-1, :, :] = f.data[2:end, :, :] - f.data[1:end-1, :, :]
    @views @. δxf.data[end,     :, :] = f.data[1,     :, :] - f.data[end,     :, :]
    nothing
end

# function δx!(g::RegularCartesianGrid, f::FaceField, δxf::EdgeField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δxf.data[i, j, k] =  f.data[i, j, k] - f.data[decmod1(i, g.Nx), j, k]
#     end
#     nothing
# end

function δx!(g::RegularCartesianGrid, f::FaceField, δxf::EdgeField)
    @views @. δxf.data[1,     :, :] = f.data[1,     :, :] - f.data[end,     :, :]
    @views @. δxf.data[2:end, :, :] = f.data[2:end, :, :] - f.data[1:end-1, :, :]
    nothing
end

# function δy!(g::RegularCartesianGrid, f::CellField, δyf::FaceField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δyf.data[i, j, k] =  f.data[i, j, k] - f.data[i, decmod1(j, g.Ny), k]
#     end
#     nothing
# end

"""
    δy!(g::RegularCartesianGrid, f::CellField, δyf::FaceField)

Compute the difference \$\\delta_y(f) = f_N - f_S\$ between the northern and
southern cells of a cell-centered field `f` and store it in a face-centered
field `δyf`, assuming both fields are defined on a regular Cartesian grid `g`
with periodic boundary condition in the \$y\$-direction.
"""
function δy!(g::RegularCartesianGrid, f::CellField, δyf::FaceField)
    @views @. δyf.data[:,     1, :] = f.data[:,     1, :] - f.data[:,     end, :]
    @views @. δyf.data[:, 2:end, :] = f.data[:, 2:end, :] - f.data[:, 1:end-1, :]
    nothing
end

# function δy!(g::RegularCartesianGrid, f::FaceField, δyf::CellField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δyf.data[i, j, k] =  f.data[i, incmod1(j, g.Ny), k] - f.data[i, j, k]
#     end
#     nothing
# end

"""
    δy!(g::RegularCartesianGrid, f::FaceField, δyf::CellField)

Compute the difference \$\\delta_y(f) = f_N - f_S\$ between the northern and
southern faces of a face-centered field `f` and store it in a cell-centered
field `δyf`, assuming both fields are defined on a regular Cartesian grid `g`
with periodic boundary condition in the \$y\$-direction.
"""
function δy!(g::RegularCartesianGrid, f::FaceField, δyf::CellField)
    @views @. δyf.data[:, 1:end-1, :] = f.data[:, 2:end, :] - f.data[:, 1:end-1, :]
    @views @. δyf.data[:, end,     :] = f.data[:, 1,     :] - f.data[:, end,     :]
    nothing
end

# function δy!(g::RegularCartesianGrid, f::EdgeField, δyf::FaceField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δyf.data[i, j, k] =  f.data[i, incmod1(j, g.Ny), k] - f.data[i, j, k]
#     end
#     nothing
# end

function δy!(g::RegularCartesianGrid, f::EdgeField, δyf::FaceField)
    @views @. δyf.data[:, 1:end-1, :] = f.data[:, 2:end, :] - f.data[:, 1:end-1, :]
    @views @. δyf.data[:, end,     :] = f.data[:, 1,     :] - f.data[:, end,     :]
    nothing
end

# function δy!(g::RegularCartesianGrid, f::FaceField, δyf::EdgeField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δyf.data[i, j, k] =  f.data[i, j, k] - f.data[i, decmod1(j, g.Ny), k]
#     end
#     nothing
# end

function δy!(g::RegularCartesianGrid, f::FaceField, δyf::EdgeField)
    @views @. δyf.data[:,     1, :] = f.data[:,     1, :] - f.data[:,     end, :]
    @views @. δyf.data[:, 2:end, :] = f.data[:, 2:end, :] - f.data[:, 1:end-1, :]
    nothing
end

# function δz!(g::RegularCartesianGrid, f::CellField, δzf::FaceField)
#     for k in 2:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δzf.data[i, j, k] = f.data[i, j, k-1] - f.data[i, j, k]
#     end
#     @. δzf.data[:, :, 1] = 0
#     nothing
# end

"""
    δz!(g::RegularCartesianGrid, f::CellField, δzf::FaceField)

Compute the difference \$\\delta_z(f) = f_T - f_B\$ between the top and
bottom cells of a cell-centered field `f` and store it in a face-centered
field `δzf`, assuming both fields are defined on a regular Cartesian grid `g`
with Neumann boundary condition in the \$z\$-direction.
"""
function δz!(g::RegularCartesianGrid, f::CellField, δzf::FaceField)
    @views @. δzf.data[:, :, 2:end] = f.data[:, :, 1:end-1] - f.data[:, :, 2:end]
    @views @. δzf.data[:, :,     1] = 0
    nothing
end

# function δz!(g::RegularCartesianGrid, f::FaceField, δzf::CellField)
#     for k in 1:(g.Nz-1), j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δzf.data[i, j, k] =  f.data[i, j, k] - f.data[i, j, k+1]
#     end
#     for j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δzf.data[i, j, g.Nz] = f.data[i, j, g.Nz]
#     end
#
#     # For some reason broadcasting causes 3 memory allocations (78.27 KiB) for
#     # Nx, Ny, Nz = 100, 100, 100.
#     # @. δzf.data[:, :, end] = f.data[:, :, end]
#
#     nothing
# end

"""
    δz!(g::RegularCartesianGrid, f::FaceField, δzf::CellField)

Compute the difference \$\\delta_z(f) = f_T - f_B\$ between the top and
bottom faces of a face-centered field `f` and store it in a cell-centered
field `δzf`, assuming both fields are defined on a regular Cartesian grid `g`
with Neumann boundary condition in the \$z\$-direction.
"""
function δz!(g::RegularCartesianGrid, f::FaceField, δzf::CellField)
    @views @. δzf.data[:, :, 1:end-1] = f.data[:, :, 1:end-1] - f.data[:, :, 2:end]
    @views @. δzf.data[:, :,     end] = f.data[:, :,     end]
    nothing
end

# function δz!(g::RegularCartesianGrid, f::EdgeField, δzf::FaceField)
#     for k in 1:(g.Nz-1), j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δzf.data[i, j, k] =  f.data[i, j, k] - f.data[i, j, k+1]
#     end
#     for j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δzf.data[i, j, g.Nz] = f.data[i, j, g.Nz]
#     end
#
#     # For some reason broadcasting causes 3 memory allocations (78.27 KiB) for
#     # Nx, Ny, Nz = 100, 100, 100.
#     # @. δzf.data[:, :, end] = f.data[:, :, end]
#
#     nothing
# end

function δz!(g::RegularCartesianGrid, f::EdgeField, δzf::FaceField)
    @views @. δzf.data[:, :, 1:end-1] = f.data[:, :, 1:end-1] - f.data[:, :, 2:end]
    @views @. δzf.data[:, :,     end] = f.data[:, :,     end]
    nothing
end

# function δz!(g::RegularCartesianGrid, f::FaceField, δzf::EdgeField)
#     for k in 2:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds δzf.data[i, j, k] = f.data[i, j, k-1] - f.data[i, j, k]
#     end
#     @. δzf.data[:, :, 1] = 0
#     nothing
# end

function δz!(g::RegularCartesianGrid, f::FaceField, δzf::EdgeField)
    @views @. δzf.data[:, :, 2:end] = f.data[:, :, 1:end-1] - f.data[:, :, 2:end]
    @views @. δzf.data[:, :,     1] = 0
    nothing
end

# function avgx!(g::RegularCartesianGrid, f::CellField, favgx::FaceField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds favgx.data[i, j, k] =  (f.data[i, j, k] + f.data[decmod1(i, g.Nx), j, k]) / 2
#     end
# end

"""
    avgx!(g::RegularCartesianGrid, f::CellField, favgx::FaceField)

Compute the average \$\\overline{\\;f\\;}^x = \\frac{f_E + f_W}{2}\$ between the
eastern and western cells of a cell-centered field `f` and store it in a `g`
face-centered field `favgx`, assuming both fields are defined on a regular
Cartesian grid `g` with periodic boundary conditions in the \$x\$-direction.
"""
function avgx!(g::RegularCartesianGrid, f::CellField, favgx::FaceField)
    @views @. favgx.data[2:end, :, :] = (f.data[2:end, :, :] + f.data[1:end-1, :, :]) / 2.0f0
    @views @. favgx.data[1,     :, :] = (f.data[1,     :, :] + f.data[end,     :, :]) / 2.0f0
    nothing
end

# function avgx!(g::RegularCartesianGrid, f::FaceField, favgx::CellField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds favgx.data[i, j, k] =  (f.data[incmod1(i, g.Nx), j, k] + f.data[i, j, k]) / 2
#     end
# end

function avgx!(g::RegularCartesianGrid, f::FaceField, favgx::CellField)
    @views @. favgx.data[1:end-1, :, :] = (f.data[2:end, :, :] + f.data[1:end-1, :, :]) / 2.0f0
    @views @. favgx.data[end,     :, :] = (f.data[1,     :, :] + f.data[end,     :, :]) / 2.0f0
    nothing
end

# function avgx!(g::RegularCartesianGrid, f::FaceField, favgx::EdgeField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds favgx.data[i, j, k] =  (f.data[i, j, k] + f.data[decmod1(i, g.Nx), j, k]) / 2
#     end
# end

function avgx!(g::RegularCartesianGrid, f::FaceField, favgx::EdgeField)
    @views @. favgx.data[2:end, :, :] = (f.data[2:end, :, :] + f.data[1:end-1, :, :]) / 2.0f0
    @views @. favgx.data[1,     :, :] = (f.data[1,     :, :] + f.data[end,     :, :]) / 2.0f0
    nothing
end

# function avgy!(g::RegularCartesianGrid, f::CellField, favgy::FaceField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds favgy.data[i, j, k] =  (f.data[i, j, k] + f.data[i, decmod1(j, g.Ny), k]) / 2
#     end
# end

function avgy!(g::RegularCartesianGrid, f::CellField, favgy::FaceField)
    @views @. favgy.data[:, 2:end, :] = (f.data[:, 2:end, :] + f.data[:, 1:end-1, :]) / 2.0f0
    @views @. favgy.data[:, 1,     :] = (f.data[:, 1,     :] + f.data[:, end,     :]) / 2.0f0
    nothing
end

# function avgy!(g::RegularCartesianGrid, f::FaceField, favgy::CellField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds favgy.data[i, j, k] =  (f.data[i, incmod1(j, g.Ny), k] + f.data[i, j, k]) / 2
#     end
# end

function avgy!(g::RegularCartesianGrid, f::FaceField, favgy::CellField)
    @views @. favgy.data[:, 1:end-1, :] = (f.data[:, 2:end, :] + f.data[:, 1:end-1, :]) / 2.0f0
    @views @. favgy.data[:, end,     :] = (f.data[:, 1,     :] + f.data[:, end,     :]) / 2.0f0
    nothing
end

# function avgy!(g::RegularCartesianGrid, f::FaceField, favgy::EdgeField)
#     for k in 1:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds favgy.data[i, j, k] =  (f.data[i, j, k] + f.data[i, decmod1(j, g.Ny), k]) / 2
#     end
# end

function avgy!(g::RegularCartesianGrid, f::FaceField, favgy::EdgeField)
    @views @. favgy.data[:, 2:end, :] = (f.data[:, 2:end, :] + f.data[:, 1:end-1, :]) / 2.0f0
    @views @. favgy.data[:, 1,     :] = (f.data[:, 1,     :] + f.data[:, end,     :]) / 2.0f0
    nothing
end

# function avgz!(g::RegularCartesianGrid, f::CellField, favgz::FaceField)
#     for k in 2:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds favgz.data[i, j, k] =  (f.data[i, j, k] + f.data[i, j, k-1]) / 2
#     end
#     @. favgz.data[:, :, 1] = f.data[:, :, 1]
#     nothing
# end

function avgz!(g::RegularCartesianGrid, f::CellField, favgz::FaceField)
    @views @. favgz.data[:, :, 2:end] = (f.data[:, :, 2:end] + f.data[:, :, 1:end-1]) / 2.0f0
    @views @. favgz.data[:, :, 1] = f.data[:, :, 1]
    nothing
end

# function avgz!(g::RegularCartesianGrid, f::FaceField, favgz::CellField)
#     for k in 1:(g.Nz-1), j in 1:g.Ny, i in 1:g.Nx
#         favgz.data[i, j, k] =  (f.data[i, j, incmod1(k, g.Nz)] + f.data[i, j, k]) / 2
#     end
#
#     # Assuming zero at the very bottom, so (f[end] + 0) / 2 = 0.5 * f[end].
#     @. favgz.data[:, :, end] = 0.5 * f.data[:, :, end]
#     nothing
# end

function avgz!(g::RegularCartesianGrid, f::FaceField, favgz::CellField)
    @views @. favgz.data[:, :, 1:end-1] = (f.data[:, :, 2:end] + f.data[:, :, 1:end-1]) / 2.0f0
    @views @. favgz.data[:, :,     end] = 0.5 * f.data[:, :, end]
    nothing
end

# function avgz!(g::RegularCartesianGrid, f::FaceField, favgz::EdgeField)
#     for k in 2:g.Nz, j in 1:g.Ny, i in 1:g.Nx
#         @inbounds favgz.data[i, j, k] =  (f.data[i, j, k] + f.data[i, j, k-1]) / 2
#     end
#     @. favgz.data[:, :, 1] = f.data[:, :, 1]
#     nothing
# end

function avgz!(g::RegularCartesianGrid, f::FaceField, favgz::EdgeField)
    @views @. favgz.data[:, :, 2:end] = (f.data[:, :, 2:end] + f.data[:, :, 1:end-1]) / 2.0f0
    @views @. favgz.data[:, :, 1] = f.data[:, :, 1]
    nothing
end


"""
    div!(g, fx, fy, fz, div, tmp)

Compute the divergence.
"""
function div!(g::RegularCartesianGrid,
              fx::FaceFieldX, fy::FaceFieldY, fz::FaceFieldZ, div::CellField,
              tmp::OperatorTemporaryFields)

    δxfx, δyfy, δzfz = tmp.fC1, tmp.fC2, tmp.fC3

    δx!(g, fx, δxfx)
    δy!(g, fy, δyfy)
    δz!(g, fz, δzfz)

    @. div.data = (1/g.V) * (g.Ax * δxfx.data + g.Ay * δyfy.data + g.Az * δzfz.data)
    nothing
end

function div!(g::RegularCartesianGrid,
              fx::CellField, fy::CellField, fz::CellField, div::FaceField,
              tmp::OperatorTemporaryFields)

    δxfx, δyfy, δzfz = tmp.fFX, tmp.fFY, tmp.fFZ

    δx!(g, fx, δxfx)
    δy!(g, fy, δyfy)
    δz!(g, fz, δzfz)

    @. div.data = (1/g.V) * (g.Ax * δxfx.data + g.Ay * δyfy.data + g.Az * δzfz.data)
    nothing
end

function div_flux!(g::RegularCartesianGrid,
                   u::FaceFieldX, v::FaceFieldY, w::FaceFieldZ, Q::CellField,
                   div_flux::CellField, tmp::OperatorTemporaryFields)

    Q̅ˣ, Q̅ʸ, Q̅ᶻ = tmp.fFX, tmp.fFY, tmp.fFZ

    avgx!(g, Q, Q̅ˣ)
    avgy!(g, Q, Q̅ʸ)
    avgz!(g, Q, Q̅ᶻ)

    flux_x, flux_y, flux_z = tmp.fFX, tmp.fFY, tmp.fFZ

    @. flux_x.data = g.Ax * u.data * Q̅ˣ.data
    @. flux_y.data = g.Ay * v.data * Q̅ʸ.data
    @. flux_z.data = g.Az * w.data * Q̅ᶻ.data

    # Imposing zero vertical flux through the top layer.
    @. flux_z.data[:, :, 1] = 0

    δxflux_x, δyflux_y, δzflux_z = tmp.fC1, tmp.fC2, tmp.fC3

    δx!(g, flux_x, δxflux_x)
    δy!(g, flux_y, δyflux_y)
    δz!(g, flux_z, δzflux_z)

    @. div_flux.data = (1/g.V) * (δxflux_x.data + δyflux_y.data + δzflux_z.data)
    nothing
end

function u∇u!(g::RegularCartesianGrid, ũ::VelocityFields, u∇u::FaceFieldX,
              tmp::OperatorTemporaryFields)

    ∂uu∂x, ∂uv∂y, ∂uw∂z = tmp.fFX, tmp.fFY, tmp.fFZ

    u̅ˣ = tmp.fC1
    avgx!(g, ũ.u, u̅ˣ)
    uu = tmp.fC1
    @. uu.data = g.Ax * u̅ˣ.data^2
    δx!(g, uu, ∂uu∂x)

    u̅ʸ, v̅ˣ = tmp.fE1, tmp.fE2
    avgy!(g, ũ.u, u̅ʸ)
    avgx!(g, ũ.v, v̅ˣ)
    uv = tmp.fE1
    @. uv.data = g.Ay * u̅ʸ.data * v̅ˣ.data
    δy!(g, uv, ∂uv∂y)

    u̅ᶻ, w̅ˣ = tmp.fE1, tmp.fE2
    avgz!(g, ũ.u, u̅ᶻ)
    avgx!(g, ũ.w, w̅ˣ)
    uw = tmp.fE1
    @. uw.data = g.Az * u̅ᶻ.data * w̅ˣ.data
    δz!(g, uw, ∂uw∂z)

    @. u∇u.data = (1/g.V) * (∂uu∂x.data + ∂uv∂y.data + ∂uw∂z.data)
    nothing
end

function u∇v!(g::RegularCartesianGrid, ũ::VelocityFields, u∇v::FaceFieldY,
              tmp::OperatorTemporaryFields)

    ∂vu∂x, ∂vv∂y, ∂vw∂z = tmp.fFX, tmp.fFY, tmp.fFZ

    v̅ˣ, u̅ʸ = tmp.fE1, tmp.fE2
    avgx!(g, ũ.v, v̅ˣ)
    avgy!(g, ũ.u, u̅ʸ)
    vu = tmp.fE1
    @. vu.data = g.Ax * v̅ˣ.data * u̅ʸ.data
    δx!(g, vu, ∂vu∂x)

    v̅ʸ = tmp.fC1
    avgy!(g, ũ.v, v̅ʸ)
    vv = tmp.fC1
    @. vv.data = g.Ay * v̅ʸ.data^2
    δy!(g, vv, ∂vv∂y)

    v̅ᶻ, w̅ʸ = tmp.fE1, tmp.fE2
    avgz!(g, ũ.v, v̅ᶻ)
    avgy!(g, ũ.w, w̅ʸ)
    vw = tmp.fE1
    @. vw.data = g.Az * v̅ᶻ.data * w̅ʸ.data
    δz!(g, vw, ∂vw∂z)

    @. u∇v.data = (1/g.V) * (∂vu∂x.data + ∂vv∂y.data + ∂vw∂z.data)
    nothing
end

function u∇w!(g::RegularCartesianGrid, ũ::VelocityFields, u∇w::FaceFieldZ,
              tmp::OperatorTemporaryFields)

    ∂wu∂x, ∂wv∂y, ∂ww∂z = tmp.fFX, tmp.fFY, tmp.fFZ

    w̅ˣ, u̅ᶻ = tmp.fE1, tmp.fE2
    avgx!(g, ũ.w, w̅ˣ)
    avgz!(g, ũ.u, u̅ᶻ)
    wu = tmp.fE1
    @. wu.data = g.Ax * w̅ˣ.data * u̅ᶻ.data
    δx!(g, wu, ∂wu∂x)

    w̅ʸ, v̅ᶻ = tmp.fE1, tmp.fE2
    avgy!(g, ũ.w, w̅ʸ)
    avgz!(g, ũ.v, v̅ᶻ)
    wv = tmp.fE1
    @. wv.data = g.Ay * w̅ʸ.data * v̅ᶻ.data
    δy!(g, wv, ∂wv∂y)

    w̅ᶻ = tmp.fC1
    avgz!(g, ũ.w, w̅ᶻ)
    ww = tmp.fC1
    @. ww.data = g.Az * w̅ᶻ.data^2
    δz!(g, ww, ∂ww∂z)

    # @. ww.data[:, :, 1]   .= 0
    # @. ww.data[:, :, end] .= 0

    @. u∇w.data = (1/g.V) * (∂wu∂x.data + ∂wv∂y.data + ∂ww∂z.data)
    nothing
end

function κ∇²!(g::RegularCartesianGrid, Q::CellField, κ∇²Q::CellField, κh, κv,
             tmp::OperatorTemporaryFields)
    δxQ, δyQ, δzQ = tmp.fFX, tmp.fFY, tmp.fFZ

    δx!(g, Q, δxQ)
    δy!(g, Q, δyQ)
    δz!(g, Q, δzQ)

    κ∇Q_x, κ∇Q_y, κ∇Q_z = tmp.fFX, tmp.fFY, tmp.fFZ

    @. κ∇Q_x.data = κh * δxQ.data / g.Δx
    @. κ∇Q_y.data = κh * δyQ.data / g.Δy
    @. κ∇Q_z.data = κv * δzQ.data / g.Δz

    div!(g, κ∇Q_x, κ∇Q_y, κ∇Q_z, κ∇²Q, tmp)
    nothing
end

function 𝜈∇²u!(g::RegularCartesianGrid, u::FaceFieldX, 𝜈∇²u::FaceField, 𝜈h, 𝜈v,
                tmp::OperatorTemporaryFields)

    𝜈∇²u_x, 𝜈∇²u_y, 𝜈∇²u_z = tmp.fFX, tmp.fFY, tmp.fFZ

    δxu = tmp.fC1
    δx!(g, u, δxu)
    𝜈∇u_x = tmp.fC1
    @. 𝜈∇u_x.data = g.Ax * 𝜈h * δxu.data / g.Δx
    δx!(g, 𝜈∇u_x, 𝜈∇²u_x)

    δyu = tmp.fE1
    δy!(g, u, δyu)
    𝜈∇u_y = tmp.fE1
    @. 𝜈∇u_y.data = g.Ay * 𝜈h * δyu.data / g.Δy
    δy!(g, 𝜈∇u_y, 𝜈∇²u_y)

    δzu = tmp.fE1
    δz!(g, u, δzu)
    𝜈∇u_z = tmp.fE1
    @. 𝜈∇u_z.data = g.Az * 𝜈v * δzu.data / g.Δz
    δz!(g, 𝜈∇u_z, 𝜈∇²u_z)

    # @. 𝜈∇u_z.data[:, :,   1] = 0  # # redundant because of δz! (c2f).
    # @. 𝜈∇u_z.data[:, :, end] = 0

    @. 𝜈∇²u.data = (1/g.V) * (𝜈∇²u_x.data + 𝜈∇²u_y.data + 𝜈∇²u_z.data)
    nothing
end

function 𝜈∇²v!(g::RegularCartesianGrid, v::FaceFieldY, 𝜈∇²v::FaceField, 𝜈h, 𝜈v,
                tmp::OperatorTemporaryFields)

    𝜈∇²v_x, 𝜈∇²v_y, 𝜈∇²v_z = tmp.fFX, tmp.fFY, tmp.fFZ

    δxv = tmp.fE1
    δx!(g, v, δxv)
    𝜈∇v_x = tmp.fE1
    @. 𝜈∇v_x.data = g.Ax * 𝜈h * δxv.data / g.Δx
    δx!(g, 𝜈∇v_x, 𝜈∇²v_x)

    δyv = tmp.fC1
    δy!(g, v, δyv)
    𝜈∇v_y = tmp.fC1
    @. 𝜈∇v_y.data = g.Ay * 𝜈h * δyv.data / g.Δy
    δy!(g, 𝜈∇v_y, 𝜈∇²v_y)

    δzv = tmp.fE1
    δz!(g, v, δzv)
    𝜈∇v_z = tmp.fE1
    @. 𝜈∇v_z.data = g.Az * 𝜈v * δzv.data / g.Δz
    δz!(g, 𝜈∇v_z, 𝜈∇²v_z)

    # @. 𝜈∇v_z.data[:, :,   1] = 0  # # redundant because of δz! (c2f).
    # @. 𝜈∇v_z.data[:, :, end] = 0

    @. 𝜈∇²v.data = (1/g.V) * (𝜈∇²v_x.data + 𝜈∇²v_y.data + 𝜈∇²v_z.data)
    nothing
end

function 𝜈∇²w!(g::RegularCartesianGrid, w::FaceFieldZ, 𝜈∇²w::FaceField, 𝜈h, 𝜈v,
                tmp::OperatorTemporaryFields)

    𝜈∇²w_x, 𝜈∇²w_y, 𝜈∇²w_z = tmp.fFX, tmp.fFY, tmp.fFZ

    δxw = tmp.fE1
    δx!(g, w, δxw)
    𝜈∇w_x = tmp.fE1
    @. 𝜈∇w_x.data = g.Ax * 𝜈h * δxw.data / g.Δx
    δx!(g, 𝜈∇w_x, 𝜈∇²w_x)

    δyw = tmp.fE1
    δy!(g, w, δyw)
    𝜈∇w_y = tmp.fE1
    @. 𝜈∇w_y.data = g.Ay * 𝜈h * δyw.data / g.Δy
    δy!(g, 𝜈∇w_y, 𝜈∇²w_y)

    δzw = tmp.fC1
    δz!(g, w, δzw)
    𝜈∇w_z = tmp.fC1
    @. 𝜈∇w_z.data = g.Az * 𝜈v * δzw.data / g.Δz
    δz!(g, 𝜈∇w_z, 𝜈∇²w_z)

    # Imposing free slip viscous boundary conditions at the bottom layer.
    # @. 𝜈∇w_z.data[:, :,   1] = 0
    # @. 𝜈∇w_z.data[:, :, end] = 0

    @. 𝜈∇²w.data = (1/g.V) * (𝜈∇²w_x.data + 𝜈∇²w_y.data + 𝜈∇²w_z.data)
    nothing
end

function ∇²_ppn!(g::RegularCartesianGrid, f::CellField, ∇²f::CellField)
    for k in 2:(g.Nz-1), j in 1:g.Ny, i in 1:g.Nx
       ∇²f.data[i, j, k] = (f.data[incmod1(i, g.Nx), j, k] - 2*f.data[i, j, k] + f.data[decmod1(i, g.Nx), j, k]) / g.Δx^2 +
                           (f.data[i, incmod1(j, g.Ny), k] - 2*f.data[i, j, k] + f.data[i, decmod1(j, g.Ny), k]) / g.Δy^2 +
                           (f.data[i, j, k+1]              - 2*f.data[i, j, k] + f.data[i, j, k-1])              / g.Δz^2
    end
    for j in 1:g.Ny, i in 1:g.Nx
        ∇²f.data[i, j,   1] = (f.data[i, j, 2] - f.data[i, j, 1]) / g.Δz^2 +
                              (f.data[incmod1(i, g.Nx), j, 1] - 2*f.data[i, j, 1] + f.data[decmod1(i, g.Nx), j, 1]) / g.Δx^2 +
                              (f.data[i, incmod1(j, g.Ny), 1] - 2*f.data[i, j, 1] + f.data[i, decmod1(j, g.Ny), 1]) / g.Δy^2
        ∇²f.data[i, j, end] = (f.data[i, j, end-1] - f.data[i, j, end]) / g.Δz^2 +
                              (f.data[incmod1(i, g.Nx), j, end] - 2*f.data[i, j, end] + f.data[decmod1(i, g.Nx), j, end]) / g.Δx^2 +
                              (f.data[i, incmod1(j, g.Ny), end] - 2*f.data[i, j, end] + f.data[i, decmod1(j, g.Ny), end]) / g.Δy^2
    end
    nothing
end