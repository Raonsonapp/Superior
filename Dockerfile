FROM golang:1.24

WORKDIR /app

COPY . .

RUN go mod tidy

RUN go build -o superior ./cmd/bot

EXPOSE 7860

CMD ["./superior"]
