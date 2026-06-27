package main

import (
	"log"
	"net/http"
	"os"

	"github.com/Raonsonapp/Superior/backend/internal/api"
	"github.com/gin-gonic/gin"
)

func main() {

	router := gin.Default()

	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"name":    "Superior AI",
			"version": "1.0.0",
			"status":  "running",
		})
	})

	router.POST("/chat", api.Chat)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("Superior AI started on port", port)

	router.Run(":" + port)
}
