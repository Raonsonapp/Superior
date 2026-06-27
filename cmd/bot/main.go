package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"time"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Superior Bot Running 🚀")
	})

	go http.ListenAndServe(":"+port, nil)

	time.Sleep(2 * time.Second)

	dialer := &net.Dialer{
		Timeout: 10 * time.Second,
	}

	client := &http.Client{
		Timeout: 15 * time.Second,
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				MinVersion: tls.VersionTLS12,
			},
			DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
				// Танҳо IPv4
				return dialer.DialContext(ctx, "tcp4", addr)
			},
		},
	}

	resp, err := client.Get("https://api.telegram.org")
	if err != nil {
		log.Println("FAILED:", err)
	} else {
		log.Println("SUCCESS:", resp.Status)
		resp.Body.Close()
	}

	select {}
}
