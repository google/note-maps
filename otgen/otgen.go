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

// Package otgen is an experimental and honestly amateur implementation of some
// ideas mostly misunderstood from various online blogs that have mentioned
// operational transformations.
package otgen

import (
	"bytes"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"text/template"
)

func Generate(opts Options) error {
	opts = opts.filled()
	fs, err := multiload(opts, tmpls, map[string][]string{
		opts.BaseName + ".go":      {"ot.go.tmpl"},
		opts.BaseName + "_test.go": {"ot_test.go.tmpl"},
	})
	if err != nil {
		return err
	}
	for _, f := range fs {
		if err := f.execute(); err != nil {
			return err
		}
	}
	for _, f := range fs {
		if err := f.save(); err != nil {
			return err
		}
	}
	return nil
}

type Options struct {
	PackageName string

	// ElementType names a type that is defined outside of the generated code.
	// The default is "rune".
	ElementType string

	// ElementName is a more readable representation of type. The default is
	// ElementType with an upper-case first letter.
	ElementName string

	BaseName string

	// SliceType names a type that is equivalent to []ElementType and is
	// defined otuside of the generated code.
	SliceType string

	// OpType names a type that will be defined in the generated code.
	OpType string

	// OpStringer may be true to indicate OpType should implement Stringer.
	//
	// Requires that SliceType also implement Stringer.
	OpStringer bool

	// DeltaType names a type that will be defined in the generated code.
	DeltaType string

	GeneratedCodeWarning string
}

func (o Options) filled() Options {
	if o.PackageName == "" {
		o.PackageName = "main"
	}
	if o.ElementType == "" {
		o.ElementType = "rune"
	}
	if o.ElementName == "" {
		o.ElementName = strings.ToTitle(o.ElementType[:1]) + o.ElementType[1:]
	}
	if o.BaseName == "" {
		o.BaseName = "generated_" + strings.ToLower(o.ElementType) + "_ot"
	}
	if o.SliceType == "" {
		o.SliceType = "[]" + o.ElementType
	}
	sliceName := o.SliceType
	if sliceName[:2] == "[]" {
		sliceName = sliceName[2:]
	}
	sliceName = strings.ToTitle(sliceName[:1]) + sliceName[1:]
	if o.OpType == "" {
		o.OpType = sliceName + "Op"
	}
	if o.DeltaType == "" {
		o.DeltaType = sliceName + "Delta"
	}
	if o.GeneratedCodeWarning == "" {
		o.GeneratedCodeWarning = "Do not modify this file: it is automatically generated"
	}
	return o
}

type file struct {
	opts Options
	t    *template.Template
	n    string
	code string
}

func load(opts Options, src http.FileSystem, name string, paths ...string) (*file, error) {
	t := template.New(name)
	for _, path := range paths {
		r, err := src.Open(path)
		if err != nil {
			return nil, err
		}
		bs, err := ioutil.ReadAll(r)
		if err != nil {
			return nil, err
		}
		if _, err = t.Parse(string(bs)); err != nil {
			return nil, err
		}
	}
	return &file{opts: opts, t: t, n: name}, nil
}
func multiload(opts Options, src http.FileSystem, nps map[string][]string) ([]*file, error) {
	fs := make([]*file, 0, len(nps))
	for n, ps := range nps {
		f, err := load(opts, src, n, ps...)
		if err != nil {
			return nil, err
		}
		fs = append(fs, f)
	}
	return fs, nil
}
func (f *file) execute() error {
	buf := bytes.NewBuffer(nil)
	if err := f.t.Execute(buf, f.opts); err != nil {
		return err
	}
	f.code = buf.String()
	return nil
}
func (f *file) save() error {
	w, err := os.Create(f.n)
	defer w.Close()
	if err != nil {
		return err
	}
	_, err = w.WriteString(f.code)
	return err
}
