FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY . .

RUN cd backend && go mod tidy && go build -o /app/superior ./cmd/server

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/superior .

EXPOSE 7860
CMD ["./superior"]
