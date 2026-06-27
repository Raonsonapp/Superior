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

const (
	HF_API_URL = "https://api-inference.huggingface.co/models/Qwen/Qwen3-8B"
)

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type HFRequest struct {
	Inputs     string                 `json:"inputs"`
	Parameters map[string]interface{} `json:"parameters"`
}

type HFResponse []struct {
	GeneratedText string `json:"generated_text"`
}

type QwenClient struct {
	httpClient *http.Client
	token      string
}

func NewQwenClient() *QwenClient {
	return &QwenClient{
		httpClient: &http.Client{Timeout: 60 * time.Second},
		token:      os.Getenv("HF_TOKEN"),
	}
}

func (q *QwenClient) Chat(userMessage string, systemPrompt string) (string, error) {
	prompt := fmt.Sprintf("<|im_start|>system\n%s<|im_end|>\n<|im_start|>user\n%s<|im_end|>\n<|im_start|>assistant\n", systemPrompt, userMessage)

	reqBody := HFRequest{
		Inputs: prompt,
		Parameters: map[string]interface{}{
			"max_new_tokens":   512,
			"temperature":      0.7,
			"top_p":            0.9,
			"do_sample":        true,
			"return_full_text": false,
		},
	}

	bodyBytes, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("marshal error: %w", err)
	}

	req, err := http.NewRequest("POST", HF_API_URL, bytes.NewReader(bodyBytes))
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
		return "⏳ Модел дар ҳоли бор шудан аст. Лутфан 30 сония интизор шавед ва дубора кӯшиш кунед.", nil
	}

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("HF API error %d: %s", resp.StatusCode, string(respBytes))
	}

	var hfResp HFResponse
	if err := json.Unmarshal(respBytes, &hfResp); err != nil {
		return "", fmt.Errorf("unmarshal error: %w, body: %s", err, string(respBytes))
	}

	if len(hfResp) == 0 || hfResp[0].GeneratedText == "" {
		return "Ҷавоб дода нашуд. Дубора кӯшиш кунед.", nil
	}

	return hfResp[0].GeneratedText, nil
}

func (q *QwenClient) Translate(text string, targetLang string) (string, error) {
	var langPrompt string
	switch targetLang {
	case "ru":
		langPrompt = "Translate the following text to Russian. Reply with translation only, no explanations."
	case "en":
		langPrompt = "Translate the following text to English. Reply with translation only, no explanations."
	case "tg":
		langPrompt = "Матни зеринро ба забони тоҷикӣ тарҷума кун. Фақат тарҷумаро бинавис."
	default:
		langPrompt = "Translate the following text to English. Reply with translation only."
	}
	return q.Chat(text, langPrompt)
}

func (q *QwenClient) Summarize(text string) (string, error) {
	return q.Chat(text, "Summarize the following text concisely in 3-5 sentences. Be clear and informative.")
}

func (q *QwenClient) DescribeImage(imageURL string) (string, error) {
	// Qwen3-8B текстӣ аст, барои image multimodal Qwen2-VL лозим аст
	// Феълан image URL-ро метавон тавассути caption тавсиф кард
	prompt := fmt.Sprintf("I have an image at this URL: %s\nDescribe what this image might contain based on the URL path and filename.", imageURL)
	return q.Chat(prompt, "You are a helpful assistant.")
}
