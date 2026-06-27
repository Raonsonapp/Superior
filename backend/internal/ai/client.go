package ai

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

const HFEndpoint = "https://router.huggingface.co/v1/chat/completions"

type Client struct {
	Token string
	Http  *http.Client
	Model string
}

func NewClient() *Client {

	model := os.Getenv("AI_MODEL")
	if model == "" {
		model = "Qwen/Qwen3-8B"
	}

	return &Client{
		Token: os.Getenv("HF_TOKEN"),
		Model: model,
		Http: &http.Client{
			Timeout: 120 * time.Second,
		},
	}
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ChatRequest struct {
	Model string `json:"model"`

	Messages []Message `json:"messages"`

	MaxTokens int `json:"max_tokens"`

	Temperature float64 `json:"temperature"`
}

type ChatChoice struct {
	Message Message `json:"message"`
}

type ChatResponse struct {
	Choices []ChatChoice `json:"choices"`
}

func (c *Client) Chat(userMessage string) (string, error) {

	systemPrompt := `You are Superior AI.

Never say you are Qwen.

Always introduce yourself as Superior AI.

You are an expert in:

Instagram
TikTok
YouTube Shorts
Hashtags
Captions
Marketing
SEO
Content Creation
Business
Programming`

	reqBody := ChatRequest{
		Model: c.Model,
		Messages: []Message{
			{
				Role:    "system",
				Content: systemPrompt,
			},
			{
				Role:    "user",
				Content: userMessage,
			},
		},
		MaxTokens: 1024,
		Temperature: 0.7,
	}

	body, _ := json.Marshal(reqBody)

	req, err := http.NewRequest(
		"POST",
		HFEndpoint,
		bytes.NewBuffer(body),
	)

	if err != nil {
		return "", err
	}

	req.Header.Set("Authorization", "Bearer "+c.Token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.Http.Do(req)

	if err != nil {
		return "", err
	}

	defer resp.Body.Close()

	data, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf(string(data))
	}

	var result ChatResponse

	if err := json.Unmarshal(data, &result); err != nil {
		return "", err
	}

	if len(result.Choices) == 0 {
		return "", fmt.Errorf("empty response")
	}

	return result.Choices[0].Message.Content, nil
}
