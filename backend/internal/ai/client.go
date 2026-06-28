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
	Result  string `json:"result,omitempty"`
	Reply   string `json:"reply,omitempty"`
	Error   string `json:"error,omitempty"`
}

type TranslateRequest struct {
	Text   string `json:"text"`
	Target string `json:"target"`
}

type SummarizeRequest struct {
	Text string `json:"text"`
}

func Chat(c *gin.Context) {
	var req ChatRequest
	if err := c.ShouldBindJSON(&req); err != nil || req.Message == "" {
		c.JSON(http.StatusBadRequest, ChatResponse{Success: false, Error: "message лозим аст"})
		return
	}
	client := ai.NewClient()
	reply, err := client.Chat(req.Message)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ChatResponse{Success: false, Error: err.Error()})
		return
	}
	c.JSON(http.StatusOK, ChatResponse{Success: true, Result: reply, Reply: reply})
}

func Translate(c *gin.Context) {
	var req TranslateRequest
	if err := c.ShouldBindJSON(&req); err != nil || req.Text == "" {
		c.JSON(http.StatusBadRequest, ChatResponse{Success: false, Error: "text лозим аст"})
		return
	}
	prompts := map[string]string{
		"ru": "Translate to Russian. Reply with translation only:\n\n",
		"en": "Translate to English. Reply with translation only:\n\n",
		"tg": "Ба тоҷикӣ тарҷума кун. Фақат тарҷума:\n\n",
	}
	prompt := prompts[req.Target]
	if prompt == "" {
		prompt = prompts["en"]
	}
	client := ai.NewClient()
	reply, err := client.Chat(prompt + req.Text)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ChatResponse{Success: false, Error: err.Error()})
		return
	}
	c.JSON(http.StatusOK, ChatResponse{Success: true, Result: reply, Reply: reply})
}

func Summarize(c *gin.Context) {
	var req SummarizeRequest
	if err := c.ShouldBindJSON(&req); err != nil || req.Text == "" {
		c.JSON(http.StatusBadRequest, ChatResponse{Success: false, Error: "text лозим аст"})
		return
	}
	client := ai.NewClient()
	reply, err := client.Chat("Summarize in 3-5 sentences:\n\n" + req.Text)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ChatResponse{Success: false, Error: err.Error()})
		return
	}
	c.JSON(http.StatusOK, ChatResponse{Success: true, Result: reply, Reply: reply})
}
