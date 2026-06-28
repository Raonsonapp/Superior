package api

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func Register(router *gin.Engine) {
	// CORS
	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	// Health
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{"app": "Superior AI", "version": "1.0.0", "status": "running"})
	})
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "model": os.Getenv("AI_MODEL")})
	})

	// API routes — Flutter /api/v1/ai/chat занг мезанад
	v1 := router.Group("/api/v1/ai")
	{
		v1.POST("/chat", Chat)
		v1.POST("/translate", Translate)
		v1.POST("/summarize", Summarize)
	}

	// Кӯҳна route ҳам нигоҳ медорем
	router.POST("/chat", Chat)
}
