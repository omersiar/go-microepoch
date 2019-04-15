package main

import (
	"fmt"
	"net/http"
	"time"
)

// Version populates in compile time
var Version string

func sendEpoch(w http.ResponseWriter, r *http.Request) {
   s := time.Now().UTC().Unix()
   fmt.Fprintf(w, "{\"type\": \"epoch\", \"data\": %d, \"unit\": \"sec\", \"rev\": %q}", s, Version)
}

func main() {
  http.HandleFunc("/", sendEpoch)
  http.ListenAndServe(":8080", nil)
}
