package main

import (
	"strings"
	"testing"
)

func TestPromptForMode(t *testing.T) {
	if promptForMode("code") != codingSystemPrompt {
		t.Error("code mode бояд codingSystemPrompt-ро баргардонад")
	}
	if promptForMode("CODE") != codingSystemPrompt {
		t.Error("mode бояд case-insensitive бошад")
	}
	if promptForMode("teach") != teachingSystemPrompt {
		t.Error("teach mode бояд teachingSystemPrompt-ро баргардонад")
	}
	if promptForMode("") != systemPrompt {
		t.Error("режими холӣ бояд systemPrompt-и пешфарзро баргардонад")
	}
	if promptForMode("chat") != systemPrompt {
		t.Error("режими номаълум бояд systemPrompt баргардонад")
	}
}

func TestModelFor(t *testing.T) {
	// модели возеҳ ҳамеша афзалият дорад
	if got := modelFor(chatRequest{Model: "x/y", Mode: "code"}); got != "x/y" {
		t.Errorf("модели возеҳ бояд истифода шавад, гирифтем %q", got)
	}
	// режими code → модели coder
	if got := modelFor(chatRequest{Mode: "code"}); got != coderModel() {
		t.Errorf("режими code бояд coderModel-ро диҳад, гирифтем %q", got)
	}
	// пешфарз
	if got := modelFor(chatRequest{}); got != defaultModel() {
		t.Errorf("пешфарз бояд defaultModel бошад, гирифтем %q", got)
	}
}

func TestTemperatureFor(t *testing.T) {
	if got := temperatureFor(chatRequest{Mode: "code"}); got != 0.2 {
		t.Errorf("режими code бояд 0.2 бошад, гирифтем %v", got)
	}
	if got := temperatureFor(chatRequest{}); got != 0.7 {
		t.Errorf("пешфарз бояд 0.7 бошад, гирифтем %v", got)
	}
	custom := 0.9
	if got := temperatureFor(chatRequest{Temperature: &custom}); got != 0.9 {
		t.Errorf("temperature-и возеҳ бояд истифода шавад, гирифтем %v", got)
	}
}

func TestBuildMessages(t *testing.T) {
	req := chatRequest{
		Messages: []chatMessage{
			{Role: "system", Content: "should be dropped"},
			{Role: "user", Content: "салом"},
			{Role: "assistant", Content: "ваалейкум"},
			{Role: "user", Content: "   "}, // холӣ — рад мешавад
			{Role: "user", Content: "чӣ хелӣ?"},
		},
	}
	msgs := buildMessages(req)

	if len(msgs) != 4 {
		t.Fatalf("интизори 4 паём (system + 3), гирифтем %d", len(msgs))
	}
	if msgs[0].Role != "system" {
		t.Error("паёми аввал бояд system бошад")
	}
	if !strings.Contains(msgs[0].Content, "Superior AI") {
		t.Error("system prompt бояд шахсияти Superior дошта бошад")
	}
	for _, m := range msgs[1:] {
		if m.Role == "system" {
			t.Error("паёмҳои system-и корбар бояд филтр шаванд")
		}
		if strings.TrimSpace(m.Content) == "" {
			t.Error("паёмҳои холӣ бояд филтр шаванд")
		}
	}
}

func TestBuildMessagesSingleTurn(t *testing.T) {
	msgs := buildMessages(chatRequest{Message: "тест"})
	if len(msgs) != 2 || msgs[1].Content != "тест" || msgs[1].Role != "user" {
		t.Errorf("режими як-паёма нодуруст: %+v", msgs)
	}
}
