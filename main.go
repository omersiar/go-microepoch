package main

import (
	"fmt"
	"net/http"
	"time"
   "os"
   "github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Version populates in compile time
var Version string

var reqCounter = prometheus.NewCounter(
   prometheus.CounterOpts{
       Name: "epoch_request_count",
       Help: "No of request handled by the handler",
   },
)

func sendEpoch(w http.ResponseWriter, r *http.Request) {
   epoch := time.Now().UTC().Unix()
   hostname, err := os.Hostname()
	if err != nil {
		fmt.Println(err)
	}
   reqCounter.Inc()
   fmt.Fprintf(w, "{\"host\": %s, \"type\": \"epoch\", \"data\": %d, \"unit\": \"sec\", \"rev\": %q}", hostname, epoch, Version)
}

func main() {
  prometheus.MustRegister(reqCounter)
  http.HandleFunc("/", sendEpoch)
  http.Handle("/metrics", promhttp.Handler())
  http.ListenAndServe(":8080", nil)
}
