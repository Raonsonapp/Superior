package main

import (
	"fmt"
	"log"
	"net"
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
		log.Println("HTTP Server started on :" + port)
		if err := http.ListenAndServe(":"+port, nil); err != nil {
			log.Fatal(err)
		}
	}()

	token := os.Getenv("BOT_TOKEN")
	if token == "" {
		log.Fatal("BOT_TOKEN is missing")
	}

	client := &http.Client{
		Timeout: 60 * time.Second,
		Transport: &http.Transport{
			TLSHandshakeTimeout: 30 * time.Second,
			DialContext: (&net.Dialer{
				Timeout: 30 * time.Second,
			}).DialContext,
		},
	}

	bot, err := tgbotapi.NewBotAPIWithClient(token, client)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Bot connected: @%s", bot.Self.UserName)

	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60

	updates := bot.GetUpdatesChan(u)

	for update := range updates {
		if update.Message == nil {
			continue
		}

		msg := tgbotapi.NewMessage(
			update.Message.Chat.ID,
			"Салом! Superior AI фаъол аст 🤖",
		)

		_, err := bot.Send(msg)
		if err != nil {
			log.Println(err)
		}
	}

	select {}
}
