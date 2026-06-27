package main

import (
	"fmt"
	"log"
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

	go func() {
		log.Println(http.ListenAndServe(":"+port, nil))
	}()

	time.Sleep(3 * time.Second)

	client := &http.Client{
		Timeout: 20 * time.Second,
	}

	resp, err := client.Get("https://api.telegram.org")

	if err != nil {
		log.Println("ERROR:", err)
	} else {
		log.Println("STATUS:", resp.Status)
		resp.Body.Close()
	}

	select {}
}
