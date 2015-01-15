module Watch
include("code.jl")


###########################
# start the watchers

(dirs, filetypes, cmd, runnow) = parseargs()

files = filter(x -> any(map(y -> endswith(x,y), filetypes)), walk().files)

processes = {nothing}
watchers = Dict()

f(inode, h) = (runcmd(cmd, processes, watchers, inode, h); watchfiles(f, files, watchers))
watchfiles(f, files, watchers)

if runnow
    runcmd(cmd, processes)
end

while true
	sleep(1)
end


end # module





