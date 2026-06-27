package config

import (
	"log"
	"os"
)

type Config struct {
	HFToken string
	Port    string
}

func Load() *Config {

	cfg := &Config{
		HFToken: os.Getenv("HF_TOKEN"),
		Port:    os.Getenv("PORT"),
	}

	if cfg.Port == "" {
		cfg.Port = "8080"
	}

	if cfg.HFToken == "" {
		log.Fatal("HF_TOKEN not found")
	}

	return cfg
}
