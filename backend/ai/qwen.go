package ai

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

const hfRouterURL = "https://router.huggingface.co/v1/chat/completions"

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatRequest struct {
	Model       string        `json:"model"`
	Messages    []chatMessage `json:"messages"`
	MaxTokens   int           `json:"max_tokens"`
	Temperature float64       `json:"temperature"`
	Stream      bool          `json:"stream"`
}

type chatResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

type QwenClient struct {
	httpClient *http.Client
	token      string
}

func NewQwenClient() *QwenClient {
	return &QwenClient{
		httpClient: &http.Client{Timeout: 90 * time.Second},
		token:      os.Getenv("HF_TOKEN"),
	}
}

func (q *QwenClient) Chat(userMessage string, systemPrompt string) (string, error) {
	messages := []chatMessage{
		{Role: "system", Content: systemPrompt},
		{Role: "user", Content: userMessage},
	}

	reqBody := chatRequest{
		Model:       "Qwen/Qwen3-8B",
		Messages:    messages,
		MaxTokens:   512,
		Temperature: 0.7,
		Stream:      false,
	}

	bodyBytes, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("marshal error: %w", err)
	}

	req, err := http.NewRequest("POST", hfRouterURL, bytes.NewReader(bodyBytes))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")
	if q.token != "" {
		req.Header.Set("Authorization", "Bearer "+q.token)
	}

	resp, err := q.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("request error: %w", err)
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	if resp.StatusCode == 503 {
		return "⏳ Модел бор мешавад. 30 сония интизор шав ва дубора кӯшиш кун.", nil
	}

	if resp.StatusCode == 429 {
		return "⏳ Лимит пур шуд. Каме интизор шав.", nil
	}

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("HF API хато %d: %s", resp.StatusCode, string(respBytes))
	}

	var hfResp chatResponse
	if err := json.Unmarshal(respBytes, &hfResp); err != nil {
		return "", fmt.Errorf("parse error: %w", err)
	}

	if hfResp.Error != nil {
		return "", fmt.Errorf("AI хато: %s", hfResp.Error.Message)
	}

	if len(hfResp.Choices) == 0 {
		return "Ҷавоб дода нашуд. Дубора кӯшиш кун.", nil
	}

	result := strings.TrimSpace(hfResp.Choices[0].Message.Content)
	if result == "" {
		return "Ҷавоб холӣ омад. Дубора кӯшиш кун.", nil
	}

	return result, nil
}

func (q *QwenClient) Translate(text string, targetLang string) (string, error) {
	prompts := map[string]string{
		"ru": "Переведи текст на русский язык. Дай только перевод без объяснений.",
		"en": "Translate the text to English. Give only the translation without explanations.",
		"tg": "Матнро ба тоҷикӣ тарҷума кун. Фақат тарҷумаро бинавис.",
	}
	prompt, ok := prompts[targetLang]
	if !ok {
		prompt = prompts["en"]
	}
	return q.Chat(text, prompt)
}

func (q *QwenClient) Summarize(text string) (string, error) {
	return q.Chat(text,
		"Summarize the following text in 3-5 sentences. Be concise and clear.")
}
