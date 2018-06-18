using SHA, Compat

exists(filename::AbstractString) = (s = stat(filename); s.inode!=0)

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
	inodes = map(x -> stat(x).inode, filenames)

	for i = 1:length(inodes)
		if !haskey(watchers, inodes[i])
			h = filehash(filenames[i])
			watchers[inodes[i]] = h
            if exists(filenames[i])
                watchfile(filenames[i], f)
            end
		end
	end
end

firstn(a, n) = a[1:min(n, length(a))]

function parseargs(ARGS = ARGS)
	# -w=dir1,dir2   ... directories to watch, default is all dirs
	# -f=jl,txt      ... filetype to watch, default "jl"
    # --now           ... already execute for the first time on startup, then watch
    # --run           ... everything after this is the command

    splitind = findfirst("--run" .== ARGS)
    parseuntil = splitind>0 ? splitind : length(ARGS)
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
	if filemode(filename) == 0
		return 0
	else
		return sha256(read(filename,String))
	end
end

function runcmd(cmd::Vector{String}, processes::AbstractVector, watchers=Dict(), filename="")
    inode = stat(filename).inode
	h = filehash(filename)
	if haskey(watchers, inode) && watchers[inode] == h
		return
	end
	watchers[inode] = h
	if isa(processes[1], Base.Process)
        kill(processes[1],9)
		processes[1] = nothing
	end
    process = open(`$cmd`)
    processes[1] = process
    stream = process.out

    @async try
        while !eof(stream)
            print(read(stream, String))
        end
    catch e
        if isa(e, InterruptException)
            kill(processes[1])
        end
    end
end
 
