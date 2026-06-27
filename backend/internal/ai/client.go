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

const Model = "Qwen/Qwen3-8B"

type Client struct {
	Token string
	Http  *http.Client
}

func NewClient() *Client {
	return &Client{
		Token: os.Getenv("HF_TOKEN"),
		Http: &http.Client{
			Timeout: 120 * time.Second,
		},
	}
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type Request struct {
	Model       string    `json:"model"`
	Messages    []Message `json:"messages"`
	MaxTokens   int       `json:"max_tokens"`
	Temperature float64   `json:"temperature"`
}

type Choice struct {
	Message Message `json:"message"`
}

type Response struct {
	Choices []Choice `json:"choices"`
}

func (c *Client) Chat(prompt string) (string, error) {

	reqBody := Request{
		Model: Model,
		Messages: []Message{
			{
				Role: "system",
				Content: `You are Superior AI.

You are the world's best AI for:

Instagram
TikTok
YouTube Shorts
Facebook
Content creation
Marketing
Hashtags
Captions
Trend analysis

Always answer professionally.
Always help the user grow.`,
			},
			{
				Role:    "user",
				Content: prompt,
			},
		},
		MaxTokens:   1024,
		Temperature: 0.7,
	}

	body, _ := json.Marshal(reqBody)

	req, err := http.NewRequest(
		"POST",
		"https://router.huggingface.co/v1/chat/completions",
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

	if resp.StatusCode != 200 {
		return "", fmt.Errorf(string(data))
	}

	var result Response

	if err := json.Unmarshal(data, &result); err != nil {
		return "", err
	}

	if len(result.Choices) == 0 {
		return "", fmt.Errorf("empty response")
	}

	return result.Choices[0].Message.Content, nil
}
