package api

import (
	"net/http"

	"github.com/Raonsonapp/Superior/backend/internal/ai"
	"github.com/gin-gonic/gin"
)

type ChatRequest struct {
	Message string `json:"message"`
}

type ChatResponse struct {
	Reply string `json:"reply"`
}

func Chat(c *gin.Context) {

	var req ChatRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	client := ai.NewClient()

	answer, err := client.Chat(req.Message)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, ChatResponse{
		Reply: answer,
	})
}
