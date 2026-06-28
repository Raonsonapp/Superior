package main

import (
	"log"
	"net/http"
	"os"

	"github.com/Raonsonapp/Superior/backend/handlers"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()

	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()

	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	aiH := handlers.NewAIHandler()

	v1 := r.Group("/api/v1/ai")
	{
		v1.POST("/chat", aiH.Chat)
		v1.POST("/translate", aiH.Translate)
		v1.POST("/summarize", aiH.Summarize)
	}

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "model": "qwen3"})
	})

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{"app": "Superior AI", "version": "1.0.0"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}

	log.Println("🚀 Superior AI Server порти:", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Server хато:", err)
	}
}
