# Watcher

[![Build Status](https://travis-ci.org/rened/Watcher.jl.svg?branch=master)](https://travis-ci.org/rened/Watcher.jl)

This package allows to run a custom command every time when one file in the specified directories changes. It was initally written to auto-run unit tests every time a file gets saved.

The default invokation is very simple:

```jl
julia -e "using Watcher"
```

This will watch all `.jl` files in the current directory and in subdiretories, and run "julia test/runtests.jl" when a file changes.

You can change this behaviour:

```jl
julia -e "using Watcher" -f=jl,txt -w=src,test echo "something changed"
```

`-f=type1,type2` specifies which file types to watch (default `jl`)

`-w=dir1,dir2` tells it to look only in these two directors, default is the current directory and all its sub directories

Everything after any `-f` and `-w` parameters is the command the will get executed, with the default being `julia test/runtests.jl`.
