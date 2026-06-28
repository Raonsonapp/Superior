package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func callAI(message, system string) (string, error) {
	token := os.Getenv("HF_TOKEN")
	model := os.Getenv("AI_MODEL")
	if model == "" {
		model = "Qwen/Qwen3-8B"
	}

	body, _ := json.Marshal(map[string]interface{}{
		"model": model,
		"messages": []map[string]string{
			{"role": "system", "content": system},
			{"role": "user", "content": message},
		},
		"max_tokens":  1024,
		"temperature": 0.7,
	})

	client := &http.Client{Timeout: 120 * time.Second}

	for i := 0; i < 3; i++ {
		req, _ := http.NewRequest("POST",
			"https://router.huggingface.co/v1/chat/completions",
			bytes.NewBuffer(body))
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Content-Type", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			if i < 2 {
				time.Sleep(10 * time.Second)
				continue
			}
			return "", err
		}
		defer resp.Body.Close()
		data, _ := io.ReadAll(resp.Body)

		if resp.StatusCode == 503 {
			if i < 2 {
				time.Sleep(20 * time.Second)
				continue
			}
			return "", fmt.Errorf("⏳ Модел бор мешавад. Дубора кӯшиш кун")
		}
		if resp.StatusCode != 200 {
			return "", fmt.Errorf("хато %d: %s", resp.StatusCode, string(data))
		}

		var result struct {
			Choices []struct {
				Message struct {
					Content string `json:"content"`
				} `json:"message"`
			} `json:"choices"`
		}
		json.Unmarshal(data, &result)
		if len(result.Choices) == 0 {
			return "", fmt.Errorf("ҷавоб холӣ")
		}
		return result.Choices[0].Message.Content, nil
	}
	return "", fmt.Errorf("3 маротиба кӯшиш шуд, нашуд")
}

func main() {
	_ = godotenv.Load()
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()

	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{"app": "Superior AI", "version": "1.0.0"})
	})

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	r.POST("/api/v1/ai/chat", func(c *gin.Context) {
		var req struct {
			Message string `json:"message"`
		}
		c.ShouldBindJSON(&req)
		if req.Message == "" {
			c.JSON(400, gin.H{"success": false, "error": "message лозим аст"})
			return
		}
		reply, err := callAI(req.Message,
			"You are Superior AI. Never say you are Qwen. Answer helpfully in the user's language.")
		if err != nil {
			c.JSON(500, gin.H{"success": false, "error": err.Error()})
			return
		}
		c.JSON(200, gin.H{"success": true, "result": reply, "reply": reply})
	})

	r.POST("/api/v1/ai/translate", func(c *gin.Context) {
		var req struct {
			Text   string `json:"text"`
			Target string `json:"target"`
		}
		c.ShouldBindJSON(&req)
		prompts := map[string]string{
			"ru": "Translate to Russian. Reply with translation only, no explanations.",
			"en": "Translate to English. Reply with translation only, no explanations.",
			"tg": "Ба тоҷикӣ тарҷума кун. Фақат тарҷума, тавзеҳ лозим нест.",
		}
		system := prompts[req.Target]
		if system == "" {
			system = prompts["en"]
		}
		reply, err := callAI(req.Text, system)
		if err != nil {
			c.JSON(500, gin.H{"success": false, "error": err.Error()})
			return
		}
		c.JSON(200, gin.H{"success": true, "result": reply})
	})

	r.POST("/api/v1/ai/summarize", func(c *gin.Context) {
		var req struct {
			Text string `json:"text"`
		}
		c.ShouldBindJSON(&req)
		reply, err := callAI(req.Text,
			"Summarize the following text in 3-5 sentences. Be concise and clear.")
		if err != nil {
			c.JSON(500, gin.H{"success": false, "error": err.Error()})
			return
		}
		c.JSON(200, gin.H{"success": true, "result": reply})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}
	log.Println("🚀 Superior AI Server:", port)
	r.Run(":" + port)
}
