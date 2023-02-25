module github.com/google/note-maps

go 1.14

replace git.apache.org/thrift.git => github.com/apache/thrift v0.14.2

require (
	github.com/99designs/gqlgen v0.13.0
	github.com/99designs/keyring v1.1.6
	github.com/alecthomas/participle v0.7.1
	github.com/dgraph-io/badger v1.6.2
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/google/subcommands v1.2.0
	github.com/onsi/ginkgo v1.14.0 // indirect
	github.com/textileio/go-threads v1.0.2
	github.com/vektah/gqlparser/v2 v2.2.0
	golang.org/x/net v0.7.0 // indirect
	google.golang.org/protobuf v1.27.1
	gopkg.in/yaml.v3 v3.0.0-20210107192922-496545a6307b
)
