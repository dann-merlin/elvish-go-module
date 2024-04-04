package main

import (
	"src.elv.sh/pkg/eval"
	"src.elv.sh/pkg/eval/vars"
)

var hw_counter int = 0
var hw_string string = "Hello World"

func getHwCounter() any {
	return hw_counter
}

func HelloWorld() any {
	hw_counter++
	return hw_string
}

var mapOfVars = map[string]vars.Var{
	"counter": vars.FromGet(getHwCounter),
	"str": vars.NewReadOnly(hw_string),
}

var mapOfGoFuncs = map[string]any{
	"helloworld": HelloWorld,
}

// There are also other Add.. functions available.
// See elvish/pkg/eval/ns.go
var Ns = eval.BuildNs().
	AddVars(mapOfVars).
	AddGoFns(mapOfGoFuncs).
	Ns()
