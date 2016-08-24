# Watcher

[![Build Status](https://travis-ci.org/rened/Watcher.jl.png)](https://travis-ci.org/rened/Watcher.jl)
[![Build Status](http://pkg.julialang.org/badges/Watcher_0.4.svg)](http://pkg.julialang.org/?pkg=Watcher&ver=0.4)
[![Build Status](http://pkg.julialang.org/badges/Watcher_0.5.svg)](http://pkg.julialang.org/?pkg=Watcher&ver=0.5)


This package allows to run a custom command every time a file in the specified directories changes. It was initally written to auto-run unit tests every time a file gets saved.

The default invokation is very simple:

```jl
julia -e "using Watcher"
```

This will watch all `jl` files in the current directory and in subdiretories, and run "julia test/runtests.jl" when a file changes.

You can change this behaviour:

```jl
julia -e "using Watcher" -- [-f=jl,txt] [-w=src,test] [--now] [--run echo "something changed"]
```

`-f=type1,type2` specifies which file types to watch, default is `jl`

`-w=dir1,dir2` tells it to look only in these two directors, default is the current directory and all its sub directories

`--now` will run the command already once on startup, and then continue watching for changes

Everything after `--run` is the command the will get executed, with the default being `julia test/runtests.jl`.

## Tips

It is recommended to put `println` statements at the beginning and end of your unit test file, to get immediate feedback that the tests started running (executing `using` statements can take some time):

```jl
println("Starting runtests.jl ...")
using FactCheck, YourPackage

# run your tests

println(" ... finished runtests.jl")
FactCheck.exitstatus()
```

