package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

func check(url string) {
	client := &http.Client{
		Timeout: 20 * time.Second,
	}

	resp, err := client.Get(url)
	if err != nil {
		log.Println(url, "❌", err)
		return
	}
	defer resp.Body.Close()

	log.Println(url, "✅", resp.Status)
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Superior Bot Running 🚀")
	})

	go func() {
		log.Println("Server started on :" + port)
		log.Fatal(http.ListenAndServe(":"+port, nil))
	}()

	time.Sleep(3 * time.Second)

	check("https://google.com")
	check("https://huggingface.co")
	check("https://api.telegram.org")
	check("https://api.github.com")

	select {}
}
