package handlers

import (
	"net/http"

	"github.com/Raonsonapp/Superior/backend/ai"
	"github.com/gin-gonic/gin"
)

type AIHandler struct {
	client *ai.QwenClient
}

func NewAIHandler() *AIHandler {
	return &AIHandler{client: ai.NewQwenClient()}
}

type ChatRequest struct {
	Message string `json:"message" binding:"required"`
}

type TranslateRequest struct {
	Text   string `json:"text" binding:"required"`
	Target string `json:"target" binding:"required"`
}

type SummarizeRequest struct {
	Text string `json:"text" binding:"required"`
}

type AIResponse struct {
	Success bool   `json:"success"`
	Result  string `json:"result,omitempty"`
	Error   string `json:"error,omitempty"`
}

func (h *AIHandler) Chat(c *gin.Context) {
	var req ChatRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, AIResponse{Success: false, Error: "message лозим аст"})
		return
	}
	result, err := h.client.Chat(req.Message, "You are Superior AI. Answer helpfully.")
	if err != nil {
		c.JSON(http.StatusInternalServerError, AIResponse{Success: false, Error: err.Error()})
		return
	}
	c.JSON(http.StatusOK, AIResponse{Success: true, Result: result})
}

func (h *AIHandler) Translate(c *gin.Context) {
	var req TranslateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, AIResponse{Success: false, Error: "text ва target лозим аст"})
		return
	}
	result, err := h.client.Translate(req.Text, req.Target)
	if err != nil {
		c.JSON(http.StatusInternalServerError, AIResponse{Success: false, Error: err.Error()})
		return
	}
	c.JSON(http.StatusOK, AIResponse{Success: true, Result: result})
}

func (h *AIHandler) Summarize(c *gin.Context) {
	var req SummarizeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, AIResponse{Success: false, Error: "text лозим аст"})
		return
	}
	result, err := h.client.Summarize(req.Text)
	if err != nil {
		c.JSON(http.StatusInternalServerError, AIResponse{Success: false, Error: err.Error()})
		return
	}
	c.JSON(http.StatusOK, AIResponse{Success: true, Result: result})
}
