// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package nmgql

import (
	"context"
	"encoding/json"
	"runtime"

	"github.com/99designs/gqlgen/graphql"
	"github.com/99designs/gqlgen/graphql/executor"
	"github.com/google/note-maps/note/graph"
	"github.com/google/note-maps/note/graph/generated"
	"github.com/vektah/gqlparser/v2/gqlerror"
)

func GetGoVersion() string {
	return runtime.Version()
}

func WarmUp()                           { defaultServer.WarmUp(context.Background()) }
func Request(bs []byte) ([]byte, error) { return defaultServer.Request(context.Background(), bs) }
func CoolDown()                         { defaultServer.CoolDown(context.Background()) }

var (
	defaultServer server
)

type server struct {
	exec *executor.Executor
}

func (s *server) WarmUp(ctx context.Context) {
	if s.exec == nil {
		// TODO: initialize database/network/etc.
		s.exec = executor.New(generated.NewExecutableSchema(generated.Config{
			Resolvers: &graph.Resolver{},
		}))
	}
}

func (s *server) CoolDown(ctx context.Context) {
	// TODO: shut down database/network/etc.
}

func (s *server) Request(ctx context.Context, in []byte) (out []byte, err error) {
	ctx = graphql.StartOperationTrace(ctx)
	s.WarmUp(ctx)

	defer func() {
		if p := recover(); p != nil {
			gqlerr := s.exec.PresentRecoveredError(ctx, p)
			out, err = json.Marshal(&graphql.Response{Errors: []*gqlerror.Error{gqlerr}})
		}
	}()

	start := graphql.Now()
	var r graphql.RawParams
	if err := json.Unmarshal(in, &r); err != nil {
		return nil, wrap(err, "request could not be decoded")
	}
	r.ReadTime = graphql.TraceTiming{
		Start: start,
		End:   graphql.Now(),
	}

	op, gqlerr := s.exec.CreateOperationContext(ctx, &r)
	if gqlerr != nil {
		return json.Marshal(s.exec.DispatchError(graphql.WithOperationContext(ctx, op), gqlerr))
	}

	ctx = graphql.WithOperationContext(ctx, op)
	h, ctx := s.exec.DispatchOperation(ctx, op)
	return json.Marshal(h(ctx))
}

type wrapped struct {
	m string
	e error
}

func (w wrapped) Error() string        { return w.m + ": " + w.e.Error() }
func wrap(err error, msg string) error { return wrapped{msg, err} }
