# Go Chat Broadcast

A real-time TCP-based chat server and client implementation in Go.

## Overview

This project demonstrates concurrent server architecture using Go goroutines, channels, and Mutex synchronization for a shared client list.

## Features

- **User Join/Leave Notifications**: When a client connects, all other clients are notified with "User [ID] joined". When they disconnect, others see "User [ID] left".
- **Message Broadcasting**: When a client sends a message, it is broadcast to all other clients (no self-echo).
- **Concurrency**: Uses goroutines for concurrent client handling, channels for message passing, and Mutex for protecting shared state.

## Architecture

- **`server.go`** — TCP server that listens on port 9000, assigns unique client IDs, manages concurrent connections, and broadcasts messages.
- **`client.go`** — Client that connects to the server, prints incoming messages, and sends stdin input to the server.
- **`go.mod`** — Go module file.

## How It Works

1. The server accepts connections from multiple clients, assigning each a unique integer ID.
2. When a client connects, the server broadcasts a join notification to all other clients.
3. Client messages are read and broadcast to all other connected clients (excluding the sender).
4. Each client has a dedicated goroutine for writing outgoing messages via a buffered channel.
5. The shared client map is protected by a Mutex to ensure thread-safe access.
