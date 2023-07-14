FROM golang:1.18-alpine3.17 AS base

### Multi-stage builds
FROM base AS build

RUN mkdir /app

COPY . /app

WORKDIR /app

# this cgo_enabled=0 is to build a static binary
RUN CGO_ENABLED=0 go build -o ./tmp/api ./cmd/api

# makes the binary executable
# RUN chmod +x /app/server

# this is the final image
FROM alpine:3.9 AS prod

RUN mkdir /app

# copy the binary from the build stage to the final
COPY --from=build /app/tmp/api /app

# run the binary
CMD ["/app/api"]

# Setup this part for development only
FROM base AS dev

ENV PATH="$PATH:/bin/bash" \
    PROJECT_DIR=/app \
    GO111MODULE=on \
    CGO_ENABLED=0

RUN apk add --update bash curl

WORKDIR /app

COPY . .

RUN go install -mod=mod github.com/githubnemo/CompileDaemon

ENTRYPOINT CompileDaemon --build="go build -o ./tmp/main ./cmd/api" --command="./tmp/main" --polling=true
