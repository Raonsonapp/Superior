package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"github.com/Raonsonapp/Superior/backend/internal/api"
)

func main() {

	// Load .env
	_ = godotenv.Load()

	// Release Mode
	gin.SetMode(gin.ReleaseMode)

	router := gin.Default()

	// Health Check
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"name":    "Superior AI",
			"version": "1.0.0",
			"status":  "running",
		})
	})

	// API
	api.Register(router)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("===================================")
	log.Println("🚀 Superior AI Started")
	log.Println("Port:", port)
	log.Println("===================================")

	if err := router.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
