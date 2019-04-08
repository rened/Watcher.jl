using SHA, Compat

function isdir(filename)
	s = stat(filename)
    s.mode & 0x4000 > 0
end 

struct FileLists
	all
	files
	dirs
end

function walk(dirs::Array; kargs...)
	r = walk(first(dirs))
	for i = 2:length(dirs)
		a = walk(dirs[i])
		append!(r.all, a.all)
		append!(r.files, a.files)
		append!(r.dirs, a.dirs)
	end
	r
end


function walk(dir = "", lists = FileLists(Any[],Any[],Any[]))
	items = Base.map(x->joinpath(dir,x), isempty(dir) ? readdir() : readdir(dir))
	dirs = filter(isdir, items)
	files = filter(x->!isdir(x), items)
    append!(lists.all, items)
    append!(lists.files, files)
    append!(lists.dirs, dirs)
	Base.map(x->walk(x, lists), dirs)
	lists
end

watchfile(filename, f) = @async (watch_file(filename); f(filename); watchfile(filename,f))

function watchfiles(f, filenames, watchers)
	for filename in filenames
        if isfile(filename)
            t = mtime(filename)
            watchers[filename] = t
            watchfile(filename, f)
        end
	end
end

firstn(a, n) = a[1:min(n, length(a))]

function parseargs(ARGS = ARGS)
	# -w=dir1,dir2   ... directories to watch, default is all dirs
	# -f=jl,txt      ... filetype to watch, default "jl"
    # --now           ... already execute for the first time on startup, then watch
    # --run           ... everything after this is the command

    splitind = findall("--run" .== ARGS)[1]
    parseuntil = splitind > 0 ? splitind : length(ARGS)
    toparse = ARGS[1:parseuntil]

    isw(a) = startswith(a, "-w=")
    isf(a) = startswith(a, "-f=")
    isnow(a) = startswith(a, "--now")
    isrun(a) = startswith(a, "--run")
    isarg(a) = isw(a) || isf(a) || isnow(a) || isrun(a)
    w = filter(isw, toparse)
    f = filter(isf, toparse)
    now = filter(isnow, toparse)

    for x in ARGS[1:parseuntil]
        if !isarg(x)
            warn("Watcher: Ignoring unknown argument \"$x\"")
        end
    end
	if splitind > 0
        cmd = ARGS[splitind+1:end]
    else
		cmd = ["julia", "test/runtests.jl"]
	end

	dirs = filter(x -> isdir(x) && x[1]!='.', readdir())
	if length(w) > 0
		dirs = split(w[1][4:end],",")
	end
	filetypes = ["jl"]
	if length(f) > 0 
		filetypes = map(x-> join([".",x]), split(f[1][4:end],","))
	end
    # @show ARGS
	# @show (dirs, filetypes, cmd, length(now)>0)
	(dirs, filetypes, cmd, length(now)>0)
end

function filehash(filename)
	return hash(read(filename))
end

function runcmd(cmd::Vector{String}, processes::Vector, watchers=Dict(), filename=nothing)
    if filename != nothing
        # t = mtime(filename)
        h = filehash(filename)
        if watchers[filename] == h
            return
        end
        watchers[filename] = h
    end

    @async try
        while !isempty(processes)
            p = pop!(processes)
            kill(p,9)
        end
        println("\n\n-------------------------\n\n")
        process = open(`$cmd`)
        push!(processes, process)
        while in(process, processes) && !eof(process.out)
            x = read(process.out, String)
            in(process, processes) && print(x)
            flush(stdout)
        end
    catch e
        if isa(e, InterruptException)
            kill(process)
        end
    end
end
 
