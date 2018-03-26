include("../src/code.jl")

# this non-test helps during the manual testing of Watcher.jl
# as the normal tests just finish too fast

println("starting runtests.jl")
println(Libc.strftime(time()))
sleep(3)
println("stopping unittest")

