package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Printf("Hello World From %s/%s!\n", runtime.GOOS, runtime.GOARCH)
}
