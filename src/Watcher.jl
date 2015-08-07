VERSION >= v"0.4.0-dev+6521" && __precompile__()

module Watch
include("code.jl")


###########################
# start the watchers

(dirs, filetypes, cmd, runnow) = parseargs()

files = filter(x -> any(map(y -> endswith(x,y), filetypes)), walk().files)

processes = Any[nothing]
watchers = Dict()

f(h) = (runcmd(cmd, processes, watchers, h); watchfiles(f, files, watchers))
watchfiles(f, files, watchers)

if runnow
    runcmd(cmd, processes)
end

while true
	sleep(1)
end


end # module





