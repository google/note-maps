#!/bin/sh
go build .
go get .
go generate ./cmd/kvschema
go get ./cmd/kvschema
go generate ./examples/...
go test ./... -coverprofile=cov
