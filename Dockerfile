# Build stage
FROM golang:1.20-alpine AS builder
WORKDIR /app

# Cache go modules
COPY go.mod .
RUN go mod download || true

# Copy sources and build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /dockerized-app

# Final minimal image
FROM scratch
COPY --from=builder /dockerized-app /dockerized-app
EXPOSE 8080
ENTRYPOINT ["/dockerized-app"]
