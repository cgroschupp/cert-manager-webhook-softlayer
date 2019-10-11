FROM golang:1.12-alpine AS build_deps

RUN apk add --no-cache git

WORKDIR /workspace
ENV GO111MODULE=on

COPY go.mod .
COPY go.sum .

RUN go get -u github.com/go-delve/delve/cmd/dlv
RUN go mod download

FROM build_deps AS build

COPY . .

RUN CGO_ENABLED=0 go build -gcflags "all=-N -l" -o webhook .

FROM alpine:3.9

RUN apk add --no-cache ca-certificates

COPY --from=build /go/bin/dlv /usr/local/bin/dlv
COPY --from=build /workspace/webhook /usr/local/bin/webhook

EXPOSE 40000

ENTRYPOINT ["dlv", "--listen=:40000", "--headless=true", "--api-version=2", "exec", "/usr/local/bin/webhook"]
