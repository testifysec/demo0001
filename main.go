package main

import (
	"github.com/common-nighthawk/go-figure"
)

func Hello() string {
	return "Hello Demo!"
}

func main() {
	myFigure := figure.NewFigure(Hello(), "starwars", true)
	myFigure.Print()
}
