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

package notes

import (
	"reflect"
	"testing"
)

func TestOp(t *testing.T) {
	id := ID("test")
	op := Op(id)
	if !op.AffectsID(id) {
		t.Errorf("%#v should affect %#v", op, id)
	}
	if op.AffectsID("other") {
		t.Errorf("%#v should not affect %#v", op, ID("other"))
	}
	if got := op.GetID(); got != id {
		t.Errorf("%#v.GetID() should return %#v, returned %#v", op, id, got)
	}
}

func TestOperationSlice_SetValue(t *testing.T) {
	var ops OperationSlice
	ops = ops.SetValue("id0", "vs1", "dt2")
	if !reflect.DeepEqual(ops, OperationSlice{
		OpSetValue{Op: "id0", Lexical: "vs1", Datatype: "dt2"},
	}) {
		t.Error(ops)
	}
}

func TestOperationSlice_SetValueString(t *testing.T) {
	var ops OperationSlice
	ops = ops.SetValueString("id0", "vs1")
	if !reflect.DeepEqual(ops, OperationSlice{
		OpSetValueString{Op: "id0", Lexical: "vs1"},
	}) {
		t.Error(ops)
	}
}

func TestOperationSlice_AddContent(t *testing.T) {
	var ops OperationSlice
	ops = ops.AddContent("id0", "c0", "c1")
	if !reflect.DeepEqual(ops, OperationSlice{
		OpAddContent{Op: "id0", Add: "c0"},
		OpAddContent{Op: "id0", Add: "c1"},
	}) {
		t.Error(ops)
	}
}

func TestOperationSlice_InsertContent(t *testing.T) {
	var ops OperationSlice
	ops = ops.InsertContent("id0", 1, "c2", "c3")
	if !reflect.DeepEqual(ops, OperationSlice{
		OpInsertContent{Op: "id0", Index: 1, Content: "c2"},
		OpInsertContent{Op: "id0", Index: 2, Content: "c3"},
	}) {
		t.Error(ops)
	}
}

func TestOperationSlice_RemoveContent(t *testing.T) {
	var ops OperationSlice
	ops = ops.RemoveContent("id0", "c1", "c2")
	if !reflect.DeepEqual(ops, OperationSlice{
		OpRemoveContent{Op: "id0", Content: "c1"},
		OpRemoveContent{Op: "id0", Content: "c2"},
	}) {
		t.Error(ops)
	}
}

func TestOperationSlice_SwapContent(t *testing.T) {
	var ops OperationSlice
	ops = ops.SwapContent("id0", 1, 2)
	if !reflect.DeepEqual(ops, OperationSlice{
		OpSwapContent{Op: "id0", A: 1, B: 2},
	}) {
		t.Error(ops)
	}
}
