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
	Success bool   `json:"success"`
	Reply   string `json:"reply,omitempty"`
	Error   string `json:"error,omitempty"`
}

func Chat(c *gin.Context) {

	var req ChatRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ChatResponse{
			Success: false,
			Error:   "Invalid request",
		})
		return
	}

	client := ai.NewClient()

	reply, err := client.Chat(req.Message)

	if err != nil {
		c.JSON(http.StatusInternalServerError, ChatResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, ChatResponse{
		Success: true,
		Reply:   reply,
	})
}
