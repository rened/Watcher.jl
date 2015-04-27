using SHA, Compat

exists(filename::String) = (s = stat(filename); s.inode!=0)

function isdir(filename)
	s = stat(filename)
    s.mode & 0x4000 > 0
end 

type FileLists
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

function watchfiles(f, filenames, watchers)
	inodes = map(x -> stat(x).inode, filenames)

	for i = 1:length(inodes)
		if !haskey(watchers, inodes[i])
			h = filehash(filenames[i])
			watchers[inodes[i]] = h
            if exists(filenames[i])
                watch_file( (fn, ev, st) -> (f(inodes[i], filenames[i])), filenames[i])
            end
		end
	end
end

firstn(a, n) = a[1:min(n, length(a))]

function parseargs(ARGS = ARGS)
	# -w=dir1,dir2   ... directories to watch, default is all dirs
	# -f=jl,txt      ... filetype to watch, default "jl"
    # -now           ... already execute for the first time on startup, then watch

    nargs = 3
    w = filter(x -> startswith(x, "-w="), firstn(ARGS,nargs))
    f = filter(x -> startswith(x, "-f="), firstn(ARGS,nargs))

    now = filter(x -> startswith(x, "-now"), firstn(ARGS,nargs))
	cmd = ARGS[length(w)+length(f)+length(now)+1:end]
	if isempty(cmd)
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
	(dirs, filetypes, cmd, length(now)>0)
end

function filehash(filename)
	if filemode(filename) == 0
		return 0
	else
		return sha256(readall(filename))
	end
end

function runcmd(cmd, process, watchers=Dict(), inode=0, filename="")
	h = filehash(filename)
	if haskey(watchers, inode) && watchers[inode] == h
		return
	end
	watchers[inode] = h
	if isa(process[1], Base.Process)
		kill(process[1])
		process[1] = nothing
	end
	stream, process[1] = open(`$cmd`)
	@async while !eof(stream)
		print(readline(stream))
	end
end
 
