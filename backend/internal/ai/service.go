package api

import (
	"strings"
)

type Service struct {
	client *Client
}

func NewService() *Service {
	return &Service{
		client: NewClient(),
	}
}

func (s *Service) Chat(message string) (string, error) {

	message = strings.TrimSpace(message)

	if message == "" {
		return "Лутфан савол нависед.", nil
	}

	answer, err := s.client.Chat(message)

	if err != nil {
		return "", err
	}

	return answer, nil
}
