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

	// Gin REST API
	go startAPIServer()

	// Telegram Bot
	token := os.Getenv("BOT_TOKEN")
	if token == "" {
		log.Fatal("BOT_TOKEN не муқаррар шудааст")
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

	case text == "/chat":
		reply(bot, chatID, "💬 Паёми худро бифрист. Ман ба он ҷавоб хоҳам дод.\n\nМисол: Салом, чӣ хел ҳастӣ?")

	case text == "/translate":
		reply(bot, chatID, "🌐 Барои тарҷума форматро истифода бур:\n\n`/tr_ru Матни шумо` — ба Русӣ\n`/tr_en Матни шумо` — ба Англисӣ\n`/tr_tg Your text` — ба Тоҷикӣ")

	case text == "/summarize":
		reply(bot, chatID, "📝 Матнеро ки мехоҳед хулоса кунед бифрист бо /sum дар аввал:\n\n`/sum Матни дароз...`")

	case strings.HasPrefix(text, "/tr_ru "):
		textToTranslate := strings.TrimPrefix(text, "/tr_ru ")
		processAI(bot, chatID, func() (string, error) {
			return qwen.Translate(textToTranslate, "ru")
		}, "🌐 Тарҷума (Русӣ):")

	case strings.HasPrefix(text, "/tr_en "):
		textToTranslate := strings.TrimPrefix(text, "/tr_en ")
		processAI(bot, chatID, func() (string, error) {
			return qwen.Translate(textToTranslate, "en")
		}, "🌐 Translation (English):")

	case strings.HasPrefix(text, "/tr_tg "):
		textToTranslate := strings.TrimPrefix(text, "/tr_tg ")
		processAI(bot, chatID, func() (string, error) {
			return qwen.Translate(textToTranslate, "tg")
		}, "🌐 Тарҷума (Тоҷикӣ):")

	case strings.HasPrefix(text, "/sum "):
		textToSum := strings.TrimPrefix(text, "/sum ")
		processAI(bot, chatID, func() (string, error) {
			return qwen.Summarize(textToSum)
		}, "📝 Хулоса:")

	case !strings.HasPrefix(text, "/"):
		// Ҳар паёми оддӣ = AI chat
		processAI(bot, chatID, func() (string, error) {
			return qwen.Chat(text, "Ту ёрдамчии AI ҳастӣ. Ба забони истифодабаранда ҷавоб деҳ.")
		}, "🤖")

	default:
		reply(bot, chatID, "❓ Фармони нодида. /start барои меню.")
	}
}

func processAI(bot *tgbotapi.BotAPI, chatID int64, fn func() (string, error), prefix string) {
	// Typing indicator
	action := tgbotapi.NewChatAction(chatID, tgbotapi.ChatTyping)
	bot.Send(action)

	result, err := fn()
	if err != nil {
		reply(bot, chatID, "❌ Хатогӣ рӯй дод: "+err.Error())
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
			tgbotapi.NewKeyboardButton("ℹ️ Кӯмак"),
		),
	)

	msg := tgbotapi.NewMessage(chatID, `🤖 *Superior AI Bot*

Ман ёрдамчии AI ҳастам, ки бо Qwen 3 кор мекунам!

*Функсияҳо:*
• 💬 AI Chat — бо ман гап зан
• 🌐 Тарҷума — ба Русӣ/Англисӣ/Тоҷикӣ
• 📝 Хулоса — матни дароз хулоса кун

Фармонҳо:
/chat — чат бо AI
/translate — тарҷума
/summarize — хулосакунӣ`)
	msg.ParseMode = "Markdown"
	msg.ReplyMarkup = keyboard
	bot.Send(msg)
}

func reply(bot *tgbotapi.BotAPI, chatID int64, text string) {
	msg := tgbotapi.NewMessage(chatID, text)
	bot.Send(msg)
}

func startAPIServer() {
	r := gin.Default()

	aiH := handlers.NewAIHandler()

	api := r.Group("/api/v1/ai")
	{
		api.POST("/chat", aiH.Chat)
		api.POST("/translate", aiH.Translate)
		api.POST("/summarize", aiH.Summarize)
	}

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "ai": "qwen3"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}
	r.Run(":" + port)
}
