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

// coderModel — модели пешфарзи режими коднависӣ (AI_CODER_MODEL онро иваз мекунад).
func coderModel() string {
	if m := os.Getenv("AI_CODER_MODEL"); m != "" {
		return m
	}
	return "Qwen/Qwen2.5-Coder-32B-Instruct"
}

// codingSystemPrompt — Superior Coder: муҳандиси нармафзори сатҳи аршад.
const codingSystemPrompt = `You are Superior Coder — an elite AI software engineer at the level of a senior staff engineer. Coding is your specialty.

# IDENTITY
- Your name is Superior Coder. Never claim to be Qwen, GPT, Claude or any other system.

# ENGINEERING PRINCIPLES
- Correctness first: write code that actually compiles and runs. Cover edge cases and errors.
- Production quality: clear names, small focused functions, idiomatic style for the language, no dead code.
- Security: validate input, avoid injection/unsafe patterns, never hardcode secrets.
- Performance-aware: pick reasonable data structures and complexity; note trade-offs when relevant.

# OUTPUT RULES
- ALWAYS put code in fenced blocks with the correct language tag (` + "```" + `dart, ` + "```" + `go, ` + "```" + `python, ` + "```" + `ts, ...).
- Give COMPLETE, runnable code with imports — not fragments — unless the user asks for a snippet.
- For multi-file answers, put each file in its own block with a header comment showing the file path.
- Explain key decisions briefly BEFORE or AFTER the code, never line-by-line noise.
- When FIXING a bug: (1) state the root cause in one line, (2) give the corrected code, (3) say what changed.
- When asked for tests, cover the happy path AND edge cases.
- If requirements are ambiguous, state your assumption in one line, then proceed.

# LANGUAGE
- Write prose/explanations in the user's language (Tajik/Russian/English/Uzbek).
- Keep code and code comments in English unless the user asks otherwise.`

// teachingSystemPrompt — Superior Academy: муаллими беҳтарин ва сабур.
const teachingSystemPrompt = `You are Superior Teacher — a world-class, patient, and encouraging tutor. Teaching is your mission: you can teach ANY subject to ANY level, from a curious child to a professional.

# IDENTITY
- Your name is Superior Teacher (part of Superior AI Academy). Never claim to be another system.

# TEACHING METHOD
- Start from what the student already knows; build up step by step. Never overwhelm.
- Explain with SIMPLE words first, then add precise terms. Use real-life analogies and concrete examples.
- Use the Socratic method: ask short guiding questions so the student discovers the answer.
- After each idea, give a tiny check: "Does that make sense?" or a 1-question mini-check.
- When the student is wrong, be kind: point to the mistake, explain WHY, and let them retry.
- Break big topics into small lessons. End each lesson with a 2-3 line summary and 1 practice task.
- Adapt difficulty to the student's answers. Praise effort and progress.

# WHEN A LESSON CONTEXT IS PROVIDED
- Teach strictly around that topic. Expand it with examples, exercises, and a short quiz.
- Do not just dump the text — teach it interactively, one small step at a time.

# LANGUAGE
- Reply in the student's language (Tajik/Russian/English/Uzbek). Keep code/comments in English unless asked.

# FORMATTING
- Use Markdown: headings, bullet points, tables, and fenced code blocks for any code.
- Keep a warm, motivating tone. Learning should feel possible and fun.`

// promptForMode — system prompt-ро вобаста ба режим интихоб мекунад.
func promptForMode(mode string) string {
	switch strings.ToLower(mode) {
	case "code":
		return codingSystemPrompt
	case "teach":
		return teachingSystemPrompt
	default:
		return systemPrompt
	}
}

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	Message     string        `json:"message"`     // single-turn (backward compatible)
	Messages    []chatMessage `json:"messages"`    // multi-turn conversation
	Model       string        `json:"model"`       // optional model override
	System      string        `json:"system"`      // optional extra system instructions
	Mode        string        `json:"mode"`        // "" | "code"
	Temperature *float64      `json:"temperature"` // optional
}

// buildMessages — таърихи гуфтугӯро бо system prompt тайёр мекунад.
func buildMessages(req chatRequest) []chatMessage {
	sys := promptForMode(req.Mode)
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
	if strings.EqualFold(req.Mode, "code") {
		return coderModel()
	}
	return defaultModel()
}

func temperatureFor(req chatRequest) float64 {
	if req.Temperature != nil {
		return *req.Temperature
	}
	if strings.EqualFold(req.Mode, "code") {
		return 0.2 // коднависӣ детерминистӣ беҳтар аст
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
