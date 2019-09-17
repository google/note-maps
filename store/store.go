// Copyright 2019 Google LLC
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

package store

import (
	"fmt"
	"log"

	"github.com/google/note-maps/kv"
	"github.com/google/note-maps/store/models"
	"github.com/google/note-maps/store/pb"
	"github.com/google/note-maps/topicmaps/tmql"
)

type TopicMapNotSpecifiedError struct{}

func (e TopicMapNotSpecifiedError) Error() string {
	return "topic map not specified"
}

type Txn struct {
	models.Txn
}

func NewTxn(ms models.Txn) Txn { return Txn{ms} }

// Merge merges any topic map item into the backing store.
func (tx Txn) Merge(t *pb.AnyItem) error {
	// Establish the topic map for context.
	if t.TopicMapId != 0 {
		tx.Partition = kv.Entity(t.TopicMapId)
	} else if tx.Partition == 0 {
		return TopicMapNotSpecifiedError{}
	} else {
		t.TopicMapId = uint64(tx.Partition)
	}

	// Establish the item id as a kv.Entity.
	var (
		te  kv.Entity
		err error
	)
	if t.ItemId != 0 {
		te = kv.Entity(t.ItemId)
	} else {
		te, err = tx.Alloc()
		if err != nil {
			return err
		}
		t.ItemId = uint64(te)
	}

	// Translate any incoming refs into IIs, SIs, and SLs.
	var (
		iis models.IIs
		sis models.SIs
		sls models.SLs
	)
	for _, ref := range t.Refs {
		switch ref.Type {
		case pb.RefType_ItemIdentifier:
			iis = append(iis, ref.Iri)
		case pb.RefType_SubjectIdentifier:
			sis = append(sis, ref.Iri)
		case pb.RefType_SubjectLocator:
			sls = append(sls, ref.Iri)
		}
	}
	if err = tx.SetIIs(te, iis); err != nil {
		return err
	}
	log.Printf("item %v has IIs %#v", te, iis)
	if err = tx.SetSIs(te, sis); err != nil {
		return err
	}
	log.Printf("item %v has SIs %#v", te, sis)
	if err = tx.SetSLs(te, sls); err != nil {
		return err
	}
	log.Printf("item %v has SLs %#v", te, sls)

	// Merge children: Names
	ns := kv.EntitySlice(uint64sToEntities(t.NameIds))
	ns.Sort()
	for _, name := range t.Names {
		name.ItemType = pb.ItemType_NameItem
		if err = tx.Merge(name); err != nil {
			return err
		}
		ns.Insert(kv.Entity(name.ItemId))
	}
	if err := tx.SetTopicNames(te, models.TopicNames(ns)); err != nil {
		return err
	}

	// Merge children: Occurrences
	os := kv.EntitySlice(uint64sToEntities(t.OccurrenceIds))
	os.Sort()
	for _, occurrence := range t.Occurrences {
		occurrence.ItemType = pb.ItemType_OccurrenceItem
		if err = tx.Merge(occurrence); err != nil {
			return err
		}
		os.Insert(kv.Entity(occurrence.ItemId))
	}
	if err := tx.SetTopicOccurrences(te, models.TopicOccurrences(os)); err != nil {
		return err
	}

	// Merge properties of reified item.
	switch t.ItemType {
	case pb.ItemType_NameItem:
		n := &models.Name{}
		n.Value = t.Value
		if err = tx.SetName(te, n); err != nil {
			return err
		}
	case pb.ItemType_OccurrenceItem:
		o := &models.Occurrence{}
		o.Value = t.Value
		if err = tx.SetOccurrence(te, o); err != nil {
			return err
		}
	}

	return nil
}

// QueryString returns a TupleSequence representing the results of evaluating
// the TMQL query expressed in `expr`.
func (tx Txn) QueryString(expr string, os ...QueryOption) (*pb.TupleSequence, error) {
	var parsed tmql.QueryExpression
	if err := tmql.ParseString(expr, &parsed); err != nil {
		return nil, err
	}
	return tx.Query(&parsed, os...)
}

// Query returns a TupleSequence representing the results of evaluating `expr`.
func (tx Txn) Query(expr *tmql.QueryExpression, os ...QueryOption) (*pb.TupleSequence, error) {
	q := newQuery(tx, expr, os...)
	return q.evaluate()
}

type query struct {
	tx   Txn
	expr *tmql.QueryExpression
	mask map[pb.Mask]bool
	env  *queryEnv
}

func newQuery(tx Txn, expr *tmql.QueryExpression, os ...QueryOption) *query {
	q := query{
		tx:   tx,
		expr: expr,
		mask: make(map[pb.Mask]bool),
		env:  makeQueryEnv(map[string]value{"%_": tx}),
	}
	for _, o := range os {
		o.apply(&q)
	}
	return &q
}

func (q *query) evaluate() (*pb.TupleSequence, error) {
	switch {
	case q.expr.PathExpression != nil:
		v, err := q.evaluatePathExpression(q.expr.PathExpression)
		if err != nil {
			return nil, err
		}
		switch v := v.(type) {
		case kv.EntitySlice:
			log.Printf("loading %v items: %#v", len(v), v)
			arena := make([]pb.AnyItem, len(v))
			items := make([]*pb.AnyItem, len(v))
			for i := range arena {
				items[i] = &arena[i]
			}
			for mask := range q.mask {
				switch mask {
				case pb.Mask_ValueMask:
					log.Printf("loading values for %#v", v)
					ns, err := q.tx.GetNameSlice(v)
					if err != nil {
						return nil, err
					}
					log.Printf("loaded names for %#v: %#v", v, ns)
					os, err := q.tx.GetOccurrenceSlice(v)
					if err != nil {
						return nil, err
					}
					log.Printf("loaded os for %#v: %#v", v, os)
					for i := range items {
						log.Printf("loading %#v from %v, %v", items[i], ns[i], os[i])
						if ns[i].Value != "" {
							items[i].Value = ns[i].Value
						} else {
							items[i].Value = os[i].Value
						}
					}
				default:
					return nil, fmt.Errorf("mask not yet supported: %v", mask)
				}
			}
			var tuples pb.TupleSequence
			for _, item := range items {
				tuples.Tuples = append(tuples.Tuples, &pb.Tuple{Items: []*pb.AnyItem{item}})
			}
			return &tuples, nil
		}
		// TODO: Use v and q.Mask to query tx for everything necessary to flesh out
		// and return a pb.TupleSequence.
		return nil, fmt.Errorf("not yet implemented, but v = %#v", v)
	default:
		return nil, fmt.Errorf("malformed query: %#v", q.expr)
	}
}

// TMQL [1] constant
//
// http://www.isotopicmaps.org/tmql/tmql.html#constant
func (q *query) evaluateConstant(c *tmql.Constant) (value, error) {
	switch {
	case c.Atom != nil:
		return q.evaluateAtom(c.Atom)
	case c.ItemReference != nil:
		return q.evaluateItemReference(c.ItemReference)
	default:
		return nil, fmt.Errorf("malformed constant: %v", c)
	}
}

// TMQL [2] atom
//
// http://www.isotopicmaps.org/tmql/tmql.html#atom
func (q *query) evaluateAtom(a *tmql.Atom) (value, error) {
	switch {
	case a.Keyword != "":
		return a.Keyword, nil
	case a.Number != nil:
		return a.Number, nil
	case a.String != nil:
		return a.String, nil
	default:
		return nil, fmt.Errorf("malformed atom: %v", a)
	}
}

// TMQL [17] item-reference
//
// http://www.isotopicmaps.org/tmql/tmql.html#item-reference
func (q *query) evaluateItemReference(ir *tmql.ItemReference) (value, error) {
	switch {
	case ir.Identifier != "":
		// Find SL or SI for q.tx.Prefix (within in q.tx.Prefix) and use it to
		// construct an absolute IRI.
		return nil, fmt.Errorf("identifiers not supported yet: %v", ir.Identifier)
	case ir.QIRI != "":
		if ir.QIRI[0] == '<' && ir.QIRI[len(ir.QIRI)-1] == '>' {
			return ir.QIRI[1 : len(ir.QIRI)-1], nil
		} else {
			return ir.QIRI, nil
		}
	default:
		return nil, fmt.Errorf("malformed item reference: %v", ir)
	}
}

func (q *query) evaluateVariable(name string) (value, error) {
	if name == "." {
		name = "$0"
	}
	v, ok := q.env.get(name)
	if !ok {
		return nil, fmt.Errorf("undefined variable: %s", name)
	}
	return v, nil
}

// TMQL [18] axis
//
// http://www.isotopicmaps.org/tmql/tmql.html#axis
func (q *query) evaluateStep(step *tmql.Step) (value, error) {
	v, err := q.evaluateVariable("$0")
	if err != nil {
		return nil, err
	}
	switch step.Axis {
	//case tmql.TypesAxis:
	//case tmql.SupertypesAxis:
	//case tmql.PlayersAxis:
	//case tmql.RolesAxis:
	//case tmql.TraverseAxis:
	case tmql.CharacteristicsAxis:
		switch step.Direction {
		case tmql.StepForward:
			switch v := v.(type) {
			case kv.EntitySlice:
				// Lookup names and occurrences for all es in v
				nss, err := q.tx.GetTopicNamesSlice([]kv.Entity(v))
				if err != nil {
					return nil, err
				}
				oss, err := q.tx.GetTopicOccurrencesSlice([]kv.Entity(v))
				if err != nil {
					return nil, err
				}
				var es kv.EntitySlice
				for _, ns := range nss {
					for _, n := range ns {
						es.Insert(n)
					}
				}
				for _, os := range oss {
					for _, o := range os {
						es.Insert(o)
					}
				}
				return es, nil
			default:
				return nil, fmt.Errorf("forward %v from %T not yet supported", step.Axis, v)
			}
		case tmql.StepBackward:
		}
	//case tmql.ScopeAxis:
	//case tmql.LocatorsAxis:
	case tmql.IndicatorsAxis:
		switch step.Direction {
		case tmql.StepForward:
			return nil, fmt.Errorf("forward %v is not yet supported", step.Axis)
		case tmql.StepBackward:
			switch v := v.(type) {
			case string:
				return q.tx.EntitiesMatchingSIsLiteral(kv.String(v))
			default:
				return nil, fmt.Errorf("backward indicators from %T is not supported", v)
			}
		}
		//case tmql.ItemAxis:
		//case tmql.ReifierAxis:
		//case tmql.AtomifyAxis:
	}
	return nil, fmt.Errorf("step is not supported: %#v", step)
}

// TMQL [20] anchor
//
// http://www.isotopicmaps.org/tmql/tmql.html#anchor
func (q *query) evaluateAnchor(a *tmql.Anchor) (value, error) {
	switch {
	case a.Constant != nil:
		return q.evaluateConstant(a.Constant)
	case a.Variable != "":
		return q.evaluateVariable(a.Variable)
	default:
		return nil, fmt.Errorf("malformed anchor: %v", a)
	}
}

// TMQL [21] simple-content
//
// http://www.isotopicmaps.org/tmql/tmql.html#simple-content
func (q *query) evaluateSimpleContent(sc *tmql.SimpleContent) (value, error) {
	v, err := q.evaluateAnchor(sc.Anchor)
	if err != nil {
		return nil, err
	}
	q.env = q.env.push(map[string]value{"$0": v})
	defer func() { q.env = q.env.pop() }()
	for _, step := range sc.Navigation {
		v, err = q.evaluateStep(step)
		if err != nil {
			return nil, err
		}
		q.env.m["$0"] = v
	}
	return v, nil
}

// TMQL [24] tuple-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#tuple-expression
func (q *query) evaluateTupleExpression(te *tmql.TupleExpression) (value, error) {
	return nil, fmt.Errorf("not yet implemented: tuple expression")
}

// TMQL [53] path-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#path-expression
func (q *query) evaluatePathExpression(pe *tmql.PathExpression) (value, error) {
	switch {
	case pe.PostfixedExpression != nil:
		return q.evaluatePostfixedExpression(pe.PostfixedExpression)
	default:
		return nil, fmt.Errorf("malformed path expression: %#v", pe)
	}
}

// TMQL [54] postfixed-expression
//
// http://www.isotopicmaps.org/tmql/tmql.html#postfixed-expression
func (q *query) evaluatePostfixedExpression(pe *tmql.PostfixedExpression) (value, error) {
	var (
		v   value
		err error
	)
	switch {
	case pe.TupleExpression != nil:
		v, err = q.evaluateTupleExpression(pe.TupleExpression)
		if err != nil {
			return nil, err
		}
	case pe.SimpleContent != nil:
		v, err = q.evaluateSimpleContent(pe.SimpleContent)
		if err != nil {
			return nil, err
		}
	default:
		return nil, fmt.Errorf("malformed postfixed expression: %#v", pe)
	}
	q.env = q.env.push(map[string]value{"$0": v})
	defer func() { q.env = q.env.pop() }()
	for _, p := range pe.Postfix {
		v, err = q.evaluatePostfix(p)
		if err != nil {
			return nil, err
		}
		q.env.m["$0"] = v
	}
	return v, nil
}

// TMQL [55] postfix
//
// http://www.isotopicmaps.org/tmql/tmql.html#postfix
func (q *query) evaluatePostfix(pf *tmql.Postfix) (value, error) {
	return nil, fmt.Errorf("not yet implemented: postfix")
}

type QueryOption interface {
	apply(q *query)
}

type queryMaskOption []pb.Mask

func (o queryMaskOption) apply(q *query) {
	for _, m := range o {
		q.mask[m] = true
	}
}

func QueryMaskOption(ms ...pb.Mask) QueryOption { return queryMaskOption(ms) }

type value interface{}

type queryEnv struct {
	m      map[string]value
	parent *queryEnv
}

func makeQueryEnv(m map[string]value) *queryEnv {
	if m == nil {
		m = make(map[string]value)
	}
	return &queryEnv{m: m}
}

func (e *queryEnv) push(m map[string]value) *queryEnv {
	return &queryEnv{
		m:      m,
		parent: e,
	}
}

func (e *queryEnv) pop() *queryEnv { return e.parent }

func (e *queryEnv) get(k string) (value, bool) {
	if e == nil {
		return nil, false
	}
	if v, ok := e.m[k]; ok {
		return v, true
	}
	return e.parent.get(k)
}

type results struct {
	entities []uint64
}

func uint64sToEntities(us []uint64) []kv.Entity {
	es := make([]kv.Entity, len(us))
	for i, u := range us {
		es[i] = kv.Entity(u)
	}
	return es
}
