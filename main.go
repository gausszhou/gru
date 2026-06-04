package main

import (
	"log"

	"github.com/gausszhou/gru/cmd"
)

func main() {
	if err := cmd.Execute(); err != nil {
		log.Fatal(err)
	}
}
