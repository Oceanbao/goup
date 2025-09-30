FROM golang:1.24-alpine as builder

WORKDIR /app

# Retrieve application dependencies.
# This allows the container build to reuse cached dependencies.
# Expecting to copy go.mod and if present go.sum.
COPY go.mod go.sum ./
RUN go mod download

# Build tools
# RUN go install github.com/go-task/task/v3/cmd/task@latest
# RUN go install github.com/swaggo/swag/cmd/swag@latest

# Copy local code to the container image.
COPY . .

# Build the binary.
# - CGO_ENABLED=0 is critical for static linking, resulting in a portable binary
# - -a -installsuffix netgo are often used together for building with CGO_ENABLED=0
# - -ldflags is used to strip debugging symbols and keep the image small
ARG TARGET_DIR=/usr/local/bin
RUN CGO_ENABLED=0 go build -ldflags '-w -s' -o ${TARGET_DIR}/server ./cmd/app/main.go
# RUN task gobuild-docker

# Use the official Debian slim image for a lean production container.
# https://hub.docker.com/_/debian
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM alpine:latest

# Security best practice: Run as a non-root user
RUN adduser -D appuser
USER appuser

# Set working directory
WORKDIR /home/appuser

# Copy the built binary from the 'builder' stage
COPY --from=builder /usr/local/bin/server .

# Expose the application port
EXPOSE 8080

# Command to run the application
ENTRYPOINT ["./server"]

# RUN set -x && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
#   ca-certificates && \
#   rm -rf /var/lib/apt/lists/*

# Copy the binary to the production image from the builder stage.
# COPY --from=builder /bin/app /app

# Run the web service on container startup.
# CMD ["/app"]
