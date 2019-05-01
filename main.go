package main

import (
	"log"
	"fmt"
	"net/http"
	"time"
	"os"
	
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Version populates in compile time
var Version string

func sendEpoch(w http.ResponseWriter, r *http.Request) {
	name, err := os.Hostname()
	if err != nil {
		panic(err)
	}
	ua := r.Header.Get("User-Agent")
	fmt.Printf("User-Agent: %s \n", ua)
	t := time.Now().UTC().Unix()
	fmt.Fprintf(w, "{\"type\": \"epoch\", \"data\": %d, \"unit\": \"sec\", \"rev\": %q, \"host\": %q}", t, Version, name)
}

func main() {
	http.HandleFunc("/", sendEpoch)
	http.Handle("/metrics", promhttp.Handler())
	log.Fatal(http.ListenAndServe(":8080", nil))
}
