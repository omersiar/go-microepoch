package main

import (
	"fmt"
	"net/http"
	"time"
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
   hostname := os.Hostname()
   reqCounter.Inc()
   fmt.Fprintf(w, "{\"host\": %s, \"type\": \"epoch\", \"data\": %d, \"unit\": \"sec\", \"rev\": %q}", hostname, epoch, Version)
}

func main() {
  prometheus.MustRegister(pingCounter)
  http.HandleFunc("/", sendEpoch)
  http.Handle("/metrics", promhttp.Handler())
  http.ListenAndServe(":8080", nil)
}
