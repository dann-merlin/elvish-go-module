# How to write an elvish plugin in Go

## Initialize `go.mod` file

Initialize the `go.mod` file.
This can be done using `go mod init`,
however you will probably have to change a lot anyways,
so you might as well just write the file yourself.

```
module my-url.tld/user/helloworld  // typically you would use github.com/username/repo

go 1.21  // this should be the same version

require (
	src.elv.sh v0.20.1  // update this if necessary
	// .. more of your dependencies
	// (will automatically be added when using "go get")
)

// You probably want to specify a local copy of the elvish repo like this
// Otherwise it's possible that packages that are part of elvish itself
// won't match the ones in your compiled binary
replace src.elv.sh => ../elvish
```

## Write the module

The module needs to have a package called `main`.
The module needs to have a variable called `Ns`,
which has to be of the elvish `eval.Ns` type.

```go
package main

import (
	"src.elv.sh/pkg/eval"
	"src.elv.sh/pkg/eval/vars"
)

// ...
var mapOfVars = map[string]vars.Var{
    // ...
}
var mapOfGoFuncs = map[string]any{
	// ...
}

// There are also other Add.. functions available.
// See elvish/pkg/eval/ns.go
var Ns = eval.BuildNs().
	AddVars(mapOfVars).
	AddGoFns(mapOfGoFuncs).
	Ns()
```

For a more in-depth implementation see the `helloworld.go` file.

## If needed, add dependencies

Add dependencies like usual in go, for example:

```bash
go get net/http
go mod tidy
```

This will likely update other dependencies, which are also used by elvish.
This is bad, because your module needs to have the exact same versions of dependencies
that are shared between the module and elvish itself.

You can run a script provided in this repo, like this:
```bash
`./check-compatibility.elv check /path/to/elvish/directory`
```
This checks all shared dependencies and informs you of discrepancies.

You can also let it try to fix these, by running:
```bash
`./check-compatibility.elv fix /path/to/elvish/directory`
```
I have only tested this a little bit, so be sure to let me know of any bugs
or failed fix attempts by submitting an issue.

## Build the module

To build the module run this command:

```bash
go build -buildmode=plugin
```

This will create a dynamic library (`.so` file).

The official builds currently do not support go modules.
You will have to build a go binary yourself passing `CGO_ENABLED=1` as an environment variable.

```bash
CGO_ENABLED=1 go install ./cmd/elvish
```

## Provide a .elv file for the interface

Provide a skeleton .elv file which describes the interfaces including
documenting comments.
