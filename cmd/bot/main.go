package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"github.com/Raonsonapp/Superior/backend/internal/api"
)

func main() {
	_ = godotenv.Load()
	gin.SetMode(gin.ReleaseMode)

	router := gin.Default()

	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{"app": "Superior AI", "version": "1.0.0", "status": "running"})
	})

	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	api.Register(router)

	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}

	log.Println("🚀 Superior AI Server:", port)
	router.Run(":" + port)
}
