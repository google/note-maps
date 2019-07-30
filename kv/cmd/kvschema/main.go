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

package main

//go:generate go-bindata templates/

import (
	"bytes"
	"flag"
	"fmt"
	"go/ast"
	"go/build"
	"go/importer"
	"go/parser"
	"go/token"
	"go/types"
	"io"
	"log"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"text/template"

	"github.com/google/note-maps/kv"
)

var (
	verbose = flag.Bool("v", false, "enable verbose logging")
	output  = flag.String("output", "kvschema.go", "output file name")
)

func verboseLogf(format string, v ...interface{}) {
	if *verbose {
		log.Output(2, fmt.Sprintf(format, v...))
	}
}

func usage() {
	fmt.Fprintf(os.Stderr, "Usage of kvschemer:\n")
	fmt.Fprintf(os.Stderr, "\tkvschemer [flags] [directory]\n")
	fmt.Fprintf(os.Stderr, "Flags:\n")
	flag.PrintDefaults()
}

func main() {
	flag.Usage = usage
	flag.Parse()
	args := flag.Args()
	if len(args) == 0 {
		wd, err := os.Getwd()
		if err != nil {
			log.Fatal(err)
		}
		args = []string{wd}
	} else if len(args) > 1 {
		flag.Usage()
		os.Exit(2)
	}
	dir := args[0]
	pkgBuild, err := build.ImportDir(dir, 0)
	if err != nil {
		log.Fatal(err)
	}
	var paths []string
	for _, gp := range pkgBuild.GoFiles {
		paths = append(paths, filepath.Join(pkgBuild.Dir, gp))
	}
	fset := token.NewFileSet()
	var files []*ast.File
	for _, path := range paths {
		f, err := parser.ParseFile(fset, path, nil, 0)
		if err != nil {
			log.Fatal(path, ":", err)
		}
		files = append(files, f)
	}
	conf := types.Config{
		Importer:    importer.Default(),
		FakeImportC: true,
	}
	info := &types.Info{}
	pkg, err := conf.Check(pkgBuild.ImportPath, fset, files, info)
	//pkg, err := importer.Default().Import(pkgBuild.ImportPath)
	if err != nil {
		log.Println(err)
	}
	var buf bytes.Buffer
	if err := gen(pkg, &buf); err != nil {
		log.Fatal(err)
	}
	opath := filepath.Join(dir, *output)
	w, err := os.Create(opath)
	if err != nil {
		log.Fatal(err)
	}
	defer w.Close()
	buf.WriteTo(w)
}

func gen(pkg *types.Package, w io.Writer) error {
	kvpath := reflect.TypeOf(kv.Entity(0)).PkgPath()
	var kvpkg *types.Package
	for _, ipkg := range pkg.Imports() {
		if ipkg.Path() == kvpath {
			kvpkg = ipkg
		}
	}
	if kvpkg == nil {
		return fmt.Errorf("%s does not import %s", pkg.Path(), kvpath)
	}
	kvInterface := func(name string) *types.Interface {
		if obj := kvpkg.Scope().Lookup(name); obj == nil {
			return nil
		} else if named, ok := obj.Type().(*types.Named); !ok {
			return nil
		} else if iface, ok := named.Underlying().(*types.Interface); !ok {
			return nil
		} else {
			return iface
		}
	}
	var (
		encoderType    = kvInterface("Encoder")
		decoderType    = kvInterface("Decoder")
		componentTypes []*componentType
	)
	for _, name := range pkg.Scope().Names() {
		if obj, ok := pkg.Scope().Lookup(name).(*types.TypeName); ok {
			named := obj.Type().(*types.Named)
			typeName := named.Obj()
			if !typeName.Exported() {
				continue
			}
			prefixName := name + "Prefix"
			if prefixConst, ok := pkg.Scope().Lookup(prefixName).(*types.Const); !ok {
				verboseLogf("%s exists but const %s is not defined",
					name, prefixName)
				continue
			} else if prefixType, ok := prefixConst.Type().(*types.Named); !ok {
				verboseLogf("const %s is defined but want named type %s and got %s",
					prefixName, "kv.Component", prefixConst.Type())
				verboseLogf("%s", prefixConst)
				verboseLogf("%#v", prefixConst)
				verboseLogf("%#v", prefixConst.Type().Underlying())
				continue
			} else {
				prefixTypeName := prefixType.Obj()
				if prefixTypeName.Pkg().Path() != kvpath ||
					prefixTypeName.Name() != "Component" {
					verboseLogf("const %s is defined but want type %s and got %s",
						prefixName, "kv.Component", prefixTypeName)
					continue
				}
			}
			encoderImpl := Implements(named, encoderType)
			decoderImpl := Implements(named, decoderType)
			if encoderImpl == noImplementation || decoderImpl == noImplementation {
				verboseLogf(
					"%s does not implement both kv.Encoder and kv.Decoder",
					typeName.Name())
				continue
			}
			c := &componentType{
				Name:          typeName.Name(),
				SVar:          strings.ToLower(typeName.Name())[0:1],
				PrefixName:    prefixName,
				DirectEncoder: encoderImpl == directImplementation,
				DirectDecoder: decoderImpl == directImplementation,
			}
			methods := types.NewMethodSet(types.NewPointer(named))
			for i := 0; i < methods.Len(); i++ {
				selection := methods.At(i)
				direct := !selection.Indirect()
				name := selection.Obj().(*types.Func).Name()
				if !strings.HasPrefix(name, "Index") {
					continue
				}
				sig := selection.Type().(*types.Signature)
				if sig.Params().Len() != 0 || sig.Results().Len() != 1 {
					verboseLogf(
						"%s receives or returns a wrong number of values", name)
					continue
				}
				rtype, isSlice := sig.Results().At(0).Type().(*types.Slice)
				if !isSlice {
					verboseLogf("%s does not return a slice", name)
					continue
				}
				elem, ok := rtype.Elem().(*types.Named)
				if !ok {
					verboseLogf("%s is not a named type", elem)
					continue
				}
				encoderImpl = Implements(elem, encoderType)
				decoderImpl = Implements(elem, decoderType)
				if encoderImpl == noImplementation || decoderImpl == noImplementation {
					verboseLogf(
						"%v does not implement encoder/decoder interfaces", elem)
					continue
				}
				expr := elem.Obj().Name()
				elemPkg := elem.Obj().Pkg()
				if elemPkg != pkg {
					expr = elemPkg.Name() + "." + expr
				}
				indexName := strings.TrimPrefix(name, "Index")
				c.Indexes = append(c.Indexes, &indexInfo{
					ComponentName:       c.Name,
					ComponentPrefixName: c.PrefixName,
					Name:                indexName,
					PrefixName:          indexName + "Prefix",
					MethodName:          name,
					MethodDirect:        direct,
					TypeExpr:            expr,
					DirectEncoder:       encoderImpl == directImplementation,
					DirectDecoder:       decoderImpl == directImplementation,
				})
				verboseLogf("index found: %v", c.Indexes[len(c.Indexes)-1])
			}
			componentTypes = append(componentTypes, c)
			verboseLogf("component type info built: %v", c)
		}
	}
	if len(componentTypes) == 0 {
		return fmt.Errorf("did not find any component types")
	}
	tbs, err := Asset("templates/kvschema.gotmpl")
	if err != nil {
		return err
	}
	t, err := template.New("kvschema.gotmpl").Parse(string(tbs))
	if err != nil {
		return err
	}
	return t.ExecuteTemplate(w, "kvschema.go", &struct {
		Package        *types.Package
		ComponentTypes []*componentType
	}{
		pkg,
		componentTypes,
	})
}

type componentType struct {
	PrefixName    string
	Name          string
	SVar          string
	DirectEncoder bool
	DirectDecoder bool
	Indexes       []*indexInfo
}

type indexInfo struct {
	ComponentName       string
	ComponentPrefixName string
	Name                string
	PrefixName          string
	MethodName          string
	MethodDirect        bool
	TypeExpr            string
	DirectEncoder       bool
	DirectDecoder       bool
}

type implementation int

const (
	noImplementation implementation = iota
	directImplementation
	indirectImplementation
)

func Implements(v types.Type, t *types.Interface) implementation {
	if types.Implements(v, t) {
		return directImplementation
	} else if types.Implements(types.NewPointer(v), t) {
		return indirectImplementation
	} else {
		return noImplementation
	}
}
