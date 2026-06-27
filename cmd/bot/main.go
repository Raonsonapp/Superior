package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "7860"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Superior Bot Running 🚀")
	})

	go func() {
		log.Println("HTTP server started on :" + port)
		if err := http.ListenAndServe(":"+port, nil); err != nil {
			log.Fatal(err)
		}
	}()

	time.Sleep(2 * time.Second)

	token := os.Getenv("BOT_TOKEN")
	if token == "" {
		log.Println("BOT_TOKEN missing")
		select {}
	}

	bot, err := tgbotapi.NewBotAPI(token)
	if err != nil {
		log.Println("Telegram connection failed:", err)

		// Серверро зинда нигоҳ медорад
		select {}
	}

	log.Println("Connected:", bot.Self.UserName)

	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60

	updates := bot.GetUpdatesChan(u)

	for update := range updates {
		if update.Message == nil {
			continue
		}

		msg := tgbotapi.NewMessage(update.Message.Chat.ID, "Салом 👋 Superior AI фаъол аст.")
		bot.Send(msg)
	}
}
