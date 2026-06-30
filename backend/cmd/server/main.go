package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

const hfRouterURL = "https://router.huggingface.co/v1/chat/completions"

// defaultModel — модели пешфарз. Бо тағйирёбандаи муҳити AI_MODEL иваз мешавад.
func defaultModel() string {
	if m := os.Getenv("AI_MODEL"); m != "" {
		return m
	}
	return "Qwen/Qwen3-8B"
}

// systemPrompt — шахсияти Superior AI: ёрирасони пуртавон, моҳир дар коднависӣ,
// сербар ва бисёрзабона (тоҷикӣ/русӣ/англисӣ).
const systemPrompt = `You are Superior AI — a highly capable, friendly, and precise AI assistant.

# IDENTITY
- Your name is Superior AI.
- Never claim to be Qwen, GPT, Claude, or any other system. You are Superior AI.

# LANGUAGE
- Detect the language of the user's latest message and reply in that SAME language.
- Tajik (тоҷикӣ) → Tajik. Russian (русский) → Russian. English → English. Uzbek → Uzbek.
- Never mix languages within one reply unless the user mixes them or asks you to.

# REASONING & QUALITY
- Think step by step on hard problems before answering. Be accurate; if unsure, say so.
- Be concise by default, thorough when the task needs depth.
- Prefer structured answers: headings, bullet points, and tables when they help.

# CODING (you are an expert software engineer)
- Write clean, correct, production-quality code. Explain key decisions briefly.
- ALWAYS put code inside fenced markdown blocks with the correct language tag,
  e.g. ` + "```" + `dart, ` + "```" + `go, ` + "```" + `python, ` + "```" + `js.
- Include short comments where they add value. Handle edge cases and errors.
- When debugging, identify the root cause, then give the corrected code.

# FORMATTING
- Use Markdown: **bold**, ` + "`" + `inline code` + "`" + `, lists, tables, and fenced code blocks.
- Keep a warm, professional tone.`

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	Message     string        `json:"message"`     // single-turn (backward compatible)
	Messages    []chatMessage `json:"messages"`    // multi-turn conversation
	Model       string        `json:"model"`       // optional model override
	System      string        `json:"system"`      // optional extra system instructions
	Temperature *float64      `json:"temperature"` // optional
}

// buildMessages — таърихи гуфтугӯро бо system prompt тайёр мекунад.
func buildMessages(req chatRequest) []chatMessage {
	sys := systemPrompt
	if strings.TrimSpace(req.System) != "" {
		sys = sys + "\n\n# ADDITIONAL USER INSTRUCTIONS\n" + req.System
	}

	msgs := []chatMessage{{Role: "system", Content: sys}}

	if len(req.Messages) > 0 {
		for _, m := range req.Messages {
			if m.Role == "system" {
				continue // system танҳо аз сервер меояд
			}
			if strings.TrimSpace(m.Content) == "" {
				continue
			}
			msgs = append(msgs, m)
		}
	} else if strings.TrimSpace(req.Message) != "" {
		msgs = append(msgs, chatMessage{Role: "user", Content: req.Message})
	}

	return msgs
}

func modelFor(req chatRequest) string {
	if strings.TrimSpace(req.Model) != "" {
		return req.Model
	}
	return defaultModel()
}

func temperatureFor(req chatRequest) float64 {
	if req.Temperature != nil {
		return *req.Temperature
	}
	return 0.7
}

// callAI — даъвати ғайри-стримии модел (барои chat/translate/summarize).
func callAI(messages []chatMessage, model string, temperature float64) (string, error) {
	token := os.Getenv("HF_TOKEN")

	body, _ := json.Marshal(map[string]interface{}{
		"model":       model,
		"messages":    messages,
		"max_tokens":  2048,
		"temperature": temperature,
		"stream":      false,
	})

	client := &http.Client{Timeout: 120 * time.Second}

	for attempt := 0; attempt < 3; attempt++ {
		req, _ := http.NewRequest("POST", hfRouterURL, bytes.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Content-Type", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			if attempt < 2 {
				time.Sleep(time.Duration(2<<attempt) * time.Second)
				continue
			}
			return "", err
		}
		data, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode == 503 || resp.StatusCode == 429 {
			if attempt < 2 {
				time.Sleep(time.Duration(5<<attempt) * time.Second)
				continue
			}
			return "", fmt.Errorf("⏳ Модел банд аст. Лутфан дубора кӯшиш кунед")
		}
		if resp.StatusCode != 200 {
			return "", fmt.Errorf("AI хато %d: %s", resp.StatusCode, string(data))
		}

		var result struct {
			Choices []struct {
				Message struct {
					Content string `json:"content"`
				} `json:"message"`
			} `json:"choices"`
		}
		if err := json.Unmarshal(data, &result); err != nil {
			return "", fmt.Errorf("ҷавобро хонда нашуд: %w", err)
		}
		if len(result.Choices) == 0 {
			return "", fmt.Errorf("ҷавоби холӣ")
		}
		return strings.TrimSpace(result.Choices[0].Message.Content), nil
	}
	return "", fmt.Errorf("сервер дастрас нест")
}

// streamAI — модели стримиро ба клиент тавассути SSE проксӣ мекунад.
// Ба клиент рӯйдодҳои `data: {"content":"..."}` ва дар охир `data: [DONE]` мефиристад.
func streamAI(c *gin.Context, messages []chatMessage, model string, temperature float64) {
	token := os.Getenv("HF_TOKEN")

	body, _ := json.Marshal(map[string]interface{}{
		"model":       model,
		"messages":    messages,
		"max_tokens":  2048,
		"temperature": temperature,
		"stream":      true,
	})

	req, _ := http.NewRequest("POST", hfRouterURL, bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 180 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		writeSSE(c, gin.H{"error": err.Error()})
		writeSSEDone(c)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		data, _ := io.ReadAll(resp.Body)
		msg := "⏳ Модел банд аст. Лутфан дубора кӯшиш кунед."
		if resp.StatusCode != 503 && resp.StatusCode != 429 {
			msg = fmt.Sprintf("AI хато %d: %s", resp.StatusCode, string(data))
		}
		writeSSE(c, gin.H{"error": msg})
		writeSSEDone(c)
		return
	}

	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("X-Accel-Buffering", "no")

	flusher, _ := c.Writer.(http.Flusher)
	scanner := bufio.NewScanner(resp.Body)
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)

	for scanner.Scan() {
		line := scanner.Text()
		if !strings.HasPrefix(line, "data:") {
			continue
		}
		payload := strings.TrimSpace(strings.TrimPrefix(line, "data:"))
		if payload == "[DONE]" {
			break
		}

		var chunk struct {
			Choices []struct {
				Delta struct {
					Content string `json:"content"`
				} `json:"delta"`
			} `json:"choices"`
		}
		if err := json.Unmarshal([]byte(payload), &chunk); err != nil {
			continue
		}
		if len(chunk.Choices) == 0 {
			continue
		}
		tok := chunk.Choices[0].Delta.Content
		if tok == "" {
			continue
		}
		writeSSE(c, gin.H{"content": tok})
		if flusher != nil {
			flusher.Flush()
		}
	}

	writeSSEDone(c)
	if flusher != nil {
		flusher.Flush()
	}
}

func writeSSE(c *gin.Context, data gin.H) {
	b, _ := json.Marshal(data)
	fmt.Fprintf(c.Writer, "data: %s\n\n", b)
}

func writeSSEDone(c *gin.Context) {
	fmt.Fprint(c.Writer, "data: [DONE]\n\n")
}

func main() {
	_ = godotenv.Load()
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()

	// CORS
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"app":     "Superior AI",
			"version": "2.0.0",
			"model":   defaultModel(),
			"status":  "running",
		})
	})

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Models — рӯйхати моделҳои дастрас барои интихоб дар клиент.
	r.GET("/api/v1/models", func(c *gin.Context) {
		c.JSON(200, gin.H{"models": []gin.H{
			{"id": "Qwen/Qwen3-8B", "name": "Superior Fast", "desc": "Зуд ва сабук"},
			{"id": "Qwen/Qwen2.5-72B-Instruct", "name": "Superior Pro", "desc": "Қавитар, барои масъалаҳои мураккаб"},
			{"id": "Qwen/Qwen2.5-Coder-32B-Instruct", "name": "Superior Coder", "desc": "Махсус барои коднависӣ"},
			{"id": "deepseek-ai/DeepSeek-R1", "name": "Superior Think", "desc": "Тафаккури амиқ ва мантиқӣ"},
		}})
	})

	// Chat (non-streaming) — таърихи пурраи гуфтугӯро қабул мекунад.
	r.POST("/api/v1/ai/chat", func(c *gin.Context) {
		var req chatRequest
		_ = c.ShouldBindJSON(&req)
		msgs := buildMessages(req)
		if len(msgs) <= 1 {
			c.JSON(400, gin.H{"success": false, "error": "паём лозим аст"})
			return
		}
		reply, err := callAI(msgs, modelFor(req), temperatureFor(req))
		if err != nil {
			c.JSON(500, gin.H{"success": false, "error": err.Error()})
			return
		}
		c.JSON(200, gin.H{"success": true, "result": reply, "reply": reply})
	})

	// Chat (streaming, SSE) — ҷавобро ҳарф-ба-ҳарф мефиристад.
	r.POST("/api/v1/ai/chat/stream", func(c *gin.Context) {
		var req chatRequest
		_ = c.ShouldBindJSON(&req)
		msgs := buildMessages(req)
		if len(msgs) <= 1 {
			c.Header("Content-Type", "text/event-stream")
			writeSSE(c, gin.H{"error": "паём лозим аст"})
			writeSSEDone(c)
			return
		}
		streamAI(c, msgs, modelFor(req), temperatureFor(req))
	})

	// Translate
	r.POST("/api/v1/ai/translate", func(c *gin.Context) {
		var req struct {
			Text   string `json:"text"`
			Target string `json:"target"`
		}
		_ = c.ShouldBindJSON(&req)
		if strings.TrimSpace(req.Text) == "" {
			c.JSON(400, gin.H{"success": false, "error": "text лозим аст"})
			return
		}
		prompts := map[string]string{
			"ru": "Translate the following text to Russian. Reply with the translation only, no explanations.",
			"en": "Translate the following text to English. Reply with the translation only, no explanations.",
			"tg": "Матни зеринро ба забони тоҷикӣ тарҷума кун. Танҳо тарҷумаро бинавис, тавзеҳ лозим нест.",
			"uz": "Translate the following text to Uzbek. Reply with the translation only, no explanations.",
		}
		sys := prompts[req.Target]
		if sys == "" {
			sys = prompts["en"]
		}
		reply, err := callAI([]chatMessage{
			{Role: "system", Content: sys},
			{Role: "user", Content: req.Text},
		}, defaultModel(), 0.3)
		if err != nil {
			c.JSON(500, gin.H{"success": false, "error": err.Error()})
			return
		}
		c.JSON(200, gin.H{"success": true, "result": reply})
	})

	// Summarize
	r.POST("/api/v1/ai/summarize", func(c *gin.Context) {
		var req struct {
			Text string `json:"text"`
		}
		_ = c.ShouldBindJSON(&req)
		if strings.TrimSpace(req.Text) == "" {
			c.JSON(400, gin.H{"success": false, "error": "text лозим аст"})
			return
		}
		reply, err := callAI([]chatMessage{
			{Role: "system", Content: "Summarize the following text in 3-5 sentences. Respond in the same language as the text. Be concise and clear."},
			{Role: "user", Content: req.Text},
		}, defaultModel(), 0.4)
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
	log.Println("🚀 Superior AI Server v2.0 on :" + port + " | model: " + defaultModel())
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
