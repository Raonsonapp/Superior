package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Superior Bot Running 🚀")
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}

	log.Println("Server started on :" + port)

	log.Fatal(http.ListenAndServe(":"+port, nil))
}
