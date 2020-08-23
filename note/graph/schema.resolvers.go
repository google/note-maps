package graph

// This file will be automatically regenerated based on the schema, any resolver implementations
// will be copied through when generating and any unknown code will be moved to the end.

import (
	"context"

	"github.com/google/note-maps/note/graph/generated"
	"github.com/google/note-maps/note/graph/model"
)

func (r *queryResolver) Status(ctx context.Context) (*model.Status, error) {
	return &model.Status{
		ID:      "",
		Summary: "linked but not yet implemented",
	}, nil
}

// Query returns generated.QueryResolver implementation.
func (r *Resolver) Query() generated.QueryResolver { return &queryResolver{r} }

type queryResolver struct{ *Resolver }
