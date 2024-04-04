module my-url.tld/user/helloworld

go 1.21

require src.elv.sh v0.20.1

require (
	github.com/mattn/go-isatty v0.0.20 // indirect
	golang.org/x/sync v0.6.0 // indirect
	golang.org/x/sys v0.17.0 // indirect
)

replace src.elv.sh => ../elvish
