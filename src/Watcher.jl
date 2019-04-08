module Watcher

using FileWatching

include("code.jl")


###########################
# start the watchers

function __init__()
    try
        (dirs, filetypes, cmd, runnow) = parseargs()

        files = filter(x -> any(map(y -> endswith(x,y), filetypes)), walk().files)

        processes = Any[]
        watchers = Dict()

        # f(h) = (runcmd(cmd, processes, watchers, h); watchfiles(f, files, watchers))
        f(h) = runcmd(cmd, processes, watchers, h)
        watchfiles(f, files, watchers)

        if runnow
            runcmd(cmd, processes)
        end

        while true
            sleep(1)
        end

    catch e
        if isa(e, InterruptException)
            exit()
        else
            rethrow(e)
        end
    end
end

end # module





