FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY backend/ .
RUN go mod tidy && go build -o superior ./cmd/server

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/superior .
EXPOSE 7860
CMD ["./superior"]
