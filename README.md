# Watcher

[![Build Status](https://travis-ci.org/rened/Watcher.jl.svg?branch=master)](https://travis-ci.org/rened/Watcher.jl)

This package allows to run a custom command every time a file in the specified directories changes. It was initally written to auto-run unit tests every time a file gets saved.

The default invokation is very simple:

```jl
julia -e "using Watcher"
```

This will watch all `jl` files in the current directory and in subdiretories, and run "julia test/runtests.jl" when a file changes.

You can change this behaviour:

```jl
# using Julia 0.3
julia -e "using Watcher" [-f=jl,txt] [-w=src,test] [-now] echo "something changed"
```

```jl
# using Julia 0.4
julia -e "using Watcher" -- [-f=jl,txt] [-w=src,test] [-now] echo "something changed"
```

`-f=type1,type2` specifies which file types to watch, default is `jl`

`-w=dir1,dir2` tells it to look only in these two directors, default is the current directory and all its sub directories

`-now` will run the command already once on startup, and then continue watching for changes

Everything after any `-f`, `-w` and `-now` parameters is the command the will get executed, with the default being `julia test/runtests.jl`.

## Tips

It is recommended to put `println` statements at the beginning and end of your unit test file, to get immediate feedback that the tests started running (executing `using` statements can take some time):

```jl
println("Starting runtests.jl ...")
using FactCheck, YourPackage

# run your tests

println(" ... finished runtests.jl")
FactCheck.exitstatus()
```

