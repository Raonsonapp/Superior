package main

import (
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/Raonsonapp/Superior/backend/ai"
	"github.com/Raonsonapp/Superior/backend/handlers"
	"github.com/gin-gonic/gin"
	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
	"github.com/joho/godotenv"
)

var qwen *ai.QwenClient

func main() {
	_ = godotenv.Load()

	qwen = ai.NewQwenClient()

	go startAPIServer()

	token := os.Getenv("BOT_TOKEN")
	if token == "" {
		log.Println("⚠️  BOT_TOKEN нест — фақат API server кор мекунад")
		select {} // block forever
	}

	bot, err := tgbotapi.NewBotAPI(token)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("✅ Bot %s сар шуд", bot.Self.UserName)

	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60
	updates := bot.GetUpdatesChan(u)

	for update := range updates {
		if update.Message == nil {
			continue
		}
		go handleMessage(bot, update.Message)
	}
}

func handleMessage(bot *tgbotapi.BotAPI, msg *tgbotapi.Message) {
	chatID := msg.Chat.ID
	text := msg.Text

	switch {
	case text == "/start":
		sendMenu(bot, chatID)

	case strings.HasPrefix(text, "/tr_ru "):
		t := strings.TrimPrefix(text, "/tr_ru ")
		processAI(bot, chatID, func() (string, error) {
			return qwen.Translate(t, "ru")
		}, "🌐 Тарҷума (Русӣ):")

	case strings.HasPrefix(text, "/tr_en "):
		t := strings.TrimPrefix(text, "/tr_en ")
		processAI(bot, chatID, func() (string, error) {
			return qwen.Translate(t, "en")
		}, "🌐 Translation (English):")

	case strings.HasPrefix(text, "/tr_tg "):
		t := strings.TrimPrefix(text, "/tr_tg ")
		processAI(bot, chatID, func() (string, error) {
			return qwen.Translate(t, "tg")
		}, "🌐 Тарҷума (Тоҷикӣ):")

	case strings.HasPrefix(text, "/sum "):
		t := strings.TrimPrefix(text, "/sum ")
		processAI(bot, chatID, func() (string, error) {
			return qwen.Summarize(t)
		}, "📝 Хулоса:")

	case !strings.HasPrefix(text, "/"):
		processAI(bot, chatID, func() (string, error) {
			return qwen.Chat(text, "You are Superior AI. Answer in the user's language. Be helpful and concise.")
		}, "🤖")

	default:
		reply(bot, chatID, "❓ /start барои меню")
	}
}

func processAI(bot *tgbotapi.BotAPI, chatID int64, fn func() (string, error), prefix string) {
	bot.Send(tgbotapi.NewChatAction(chatID, tgbotapi.ChatTyping))
	result, err := fn()
	if err != nil {
		reply(bot, chatID, "❌ Хатогӣ: "+err.Error())
		return
	}
	reply(bot, chatID, fmt.Sprintf("%s\n\n%s", prefix, result))
}

func sendMenu(bot *tgbotapi.BotAPI, chatID int64) {
	keyboard := tgbotapi.NewReplyKeyboard(
		tgbotapi.NewKeyboardButtonRow(
			tgbotapi.NewKeyboardButton("💬 AI Chat"),
			tgbotapi.NewKeyboardButton("🌐 Тарҷума"),
		),
		tgbotapi.NewKeyboardButtonRow(
			tgbotapi.NewKeyboardButton("📝 Хулоса"),
		),
	)
	msg := tgbotapi.NewMessage(chatID, "🤖 *Superior AI*\n\nФармонҳо:\n/tr\\_ru Матн — тарҷума ба Русӣ\n/tr\\_en Text — translate to English\n/tr\\_tg Text — тарҷума ба Тоҷикӣ\n/sum Матн — хулоса")
	msg.ParseMode = "Markdown"
	msg.ReplyMarkup = keyboard
	bot.Send(msg)
}

func reply(bot *tgbotapi.BotAPI, chatID int64, text string) {
	bot.Send(tgbotapi.NewMessage(chatID, text))
}

func startAPIServer() {
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()

	aiH := handlers.NewAIHandler()

	v1 := r.Group("/api/v1/ai")
	{
		v1.POST("/chat", aiH.Chat)
		v1.POST("/translate", aiH.Translate)
		v1.POST("/summarize", aiH.Summarize)
	}

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "model": "qwen3"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}
	log.Println("🚀 API Server:", port)
	r.Run(":" + port)
}
