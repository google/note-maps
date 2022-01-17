module github.com/google/note-maps

go 1.14

replace git.apache.org/thrift.git => github.com/apache/thrift v0.14.2

require (
	github.com/99designs/gqlgen v0.13.0
	github.com/99designs/keyring v1.1.6
	github.com/alecthomas/participle v0.7.1
	github.com/dgraph-io/badger v1.6.2
	github.com/golang/protobuf v1.5.2
	github.com/google/subcommands v1.2.0
	github.com/marten-seemann/qpack v0.2.1 // indirect
	github.com/qpackers/qifs v0.0.0-20210127184931-da52cd936b3e // indirect
	github.com/textileio/go-threads v1.0.2
	github.com/tweag/gomod2nix v0.0.0-20210329153857-c78d7b9f15a2 // indirect
	github.com/vektah/gqlparser/v2 v2.2.0
	google.golang.org/protobuf v1.27.1
	gopkg.in/yaml.v3 v3.0.0-20210107192922-496545a6307b
)
