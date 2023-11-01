FROM golang:latest AS builder

WORKDIR /code

ENV CGO_ENABLED 0
ENV GOPATH /go
ENV GOCACHE /go-build


COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod/cache \
    go mod download


COPY . .

COPY ./templates ./

RUN --mount=type=cache,target=/go/pkg/mod/cache \
    --mount=type=cache,target=/go-build \
    go build -o bin/app main.go

FROM builder as dev-envs

RUN apk update && \
    apk add git && \
    addgroup -S docker && \
    adduser -S --shell /bin/bash --ingroup docker vscode

FROM scratch

COPY --from=builder /code/bin/app /usr/local/bin/app
COPY --from=builder /code/templates /templates


CMD ["/usr/local/bin/app"]
