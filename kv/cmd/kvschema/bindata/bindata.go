// Package bindata Code generated by go-bindata. (@generated) DO NOT EDIT.
// sources:
// templates/kvschema.gotmpl
package bindata

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func bindataRead(data []byte, name string) ([]byte, error) {
	gz, err := gzip.NewReader(bytes.NewBuffer(data))
	if err != nil {
		return nil, fmt.Errorf("read %q: %v", name, err)
	}

	var buf bytes.Buffer
	_, err = io.Copy(&buf, gz)
	clErr := gz.Close()

	if err != nil {
		return nil, fmt.Errorf("read %q: %v", name, err)
	}
	if clErr != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

type asset struct {
	bytes []byte
	info  os.FileInfo
}

type bindataFileInfo struct {
	name    string
	size    int64
	mode    os.FileMode
	modTime time.Time
}

// Name return file name
func (fi bindataFileInfo) Name() string {
	return fi.name
}

// Size return file size
func (fi bindataFileInfo) Size() int64 {
	return fi.size
}

// Mode return file mode
func (fi bindataFileInfo) Mode() os.FileMode {
	return fi.mode
}

// ModTime return file modify time
func (fi bindataFileInfo) ModTime() time.Time {
	return fi.modTime
}

// IsDir return file whether a directory
func (fi bindataFileInfo) IsDir() bool {
	return fi.mode&os.ModeDir != 0
}

// Sys return file is sys mode
func (fi bindataFileInfo) Sys() interface{} {
	return nil
}

var _templatesKvschemaGotmpl = []byte("\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff\xcc\x58\x5d\x6f\xe3\xb8\x15\x7d\x36\x7f\xc5\xad\x1f\x0a\x69\x46\x23\x67\xf2\x34\xcd\x20\x05\xbc\x49\x3a\x35\x3a\x9b\x2c\x62\x4f\x07\x8b\x20\x28\x68\xe9\x5a\x22\x2c\x93\x1a\x92\x92\xe3\x0a\xfa\xef\xc5\xa5\xbe\x6c\xc7\x49\x30\x05\x16\xd8\xa7\xc4\x22\xef\xe7\x39\x3c\xbc\x52\x55\x4d\xde\x01\xbb\x52\xf9\x4e\x8b\x24\xb5\x70\x7e\xf6\xf1\x6f\xf0\x45\xa9\x24\x43\xf8\xfa\xf5\x8a\xb1\xaf\x22\x42\x69\x30\x86\x42\xc6\xa8\xc1\xa6\x08\xd3\x9c\x47\x29\x42\xbb\x12\xc0\xbf\x51\x1b\xa1\x24\x9c\x87\x67\xe0\xd1\x86\x71\xbb\x34\xf6\x3f\xb3\x9d\x2a\x60\xc3\x77\x20\x95\x85\xc2\x20\xd8\x54\x18\x58\x89\x0c\x01\x9f\x22\xcc\x2d\x08\x09\x91\xda\xe4\x99\xe0\x32\x42\xd8\x0a\x9b\xba\x20\xad\x8b\x90\xfd\xde\x3a\x50\x4b\xcb\x85\x04\x0e\x91\xca\x77\xa0\x56\xfb\xbb\x80\x5b\xc6\x00\x00\x52\x6b\x73\x73\x31\x99\x6c\xb7\xdb\x90\xbb\x34\x43\xa5\x93\x49\xd6\x6c\x33\x93\xaf\xb3\xab\x9b\xdb\xf9\xcd\x87\xf3\xf0\x8c\xb1\x6f\x32\x43\x63\x40\xe3\x8f\x42\x68\x8c\x61\xb9\x03\x9e\xe7\x99\x88\xf8\x32\x43\xc8\xf8\x16\x94\x06\x9e\x68\xc4\x18\xac\xa2\x44\xb7\x5a\x58\x21\x93\x00\x8c\x5a\xd9\x2d\xd7\xc8\x62\x61\xac\x16\xcb\xc2\x1e\x74\xa8\x4b\x4b\x18\xd8\xdf\xa0\x24\x70\x09\xe3\xe9\x1c\x66\xf3\x31\xfc\x32\x9d\xcf\xe6\x01\xfb\x3e\x5b\xfc\xf3\xee\xdb\x02\xbe\x4f\xef\xef\xa7\xb7\x8b\xd9\xcd\x1c\xee\xee\xe1\xea\xee\xf6\x7a\xb6\x98\xdd\xdd\xce\xe1\xee\x1f\x30\xbd\xfd\x1d\xfe\x35\xbb\xbd\x0e\x00\x85\x4d\x51\x03\x3e\xe5\x9a\x72\x57\x1a\x04\xf5\x0e\xe3\x90\xcd\x11\x0f\x82\xaf\x54\x93\x8c\xc9\x31\x12\x2b\x11\x41\xc6\x65\x52\xf0\x04\x21\x51\x25\x6a\x29\x64\x02\x39\xea\x8d\x30\x84\x9e\x01\x2e\x63\x96\x89\x8d\xb0\xdc\xba\xdf\xcf\xca\x09\xd9\xbb\x49\x5d\x33\x56\x55\x31\xae\x84\x44\x18\xaf\x4b\x13\xa5\xb8\xe1\x61\xa2\xc6\x75\x3d\x99\xc0\x95\x8a\x11\x12\x94\xa8\xb9\x6d\x3a\xda\xef\x19\x7f\x86\xeb\x3b\xb8\xbd\x5b\xc0\xcd\xf5\x6c\x11\x32\x96\xf3\x68\x4d\xd9\x54\x55\xf8\x5b\xf3\x6f\x78\xcb\x37\x48\x11\xc4\x26\x57\xda\x82\xc7\x46\xe3\x44\xd8\xb4\x58\x86\x91\xda\x4c\x12\x47\xcb\x89\x54\x16\x3f\x6c\x78\x6e\x26\xeb\x72\xcc\x7c\xc6\x26\x13\x58\x3c\x49\xc8\xb5\x2a\x45\x8c\x06\x50\x5a\x61\x05\x9a\xc0\x11\x4b\x49\x94\xd6\x04\x54\x1e\x08\x19\xe3\x13\x1a\x58\xf2\x68\xdd\x02\x0e\x6b\xdc\x7d\x28\x79\x56\x20\x18\xab\x34\x86\xcc\xee\x72\x74\x0e\x8d\xd5\x45\x64\x2b\x58\x97\xe1\x6f\x5c\x93\x4f\x25\x31\x86\x9a\xb1\x55\x21\x23\xb8\xc5\xad\x67\x69\x71\xf1\x24\x7d\x67\x50\x81\x46\x5b\x68\x49\x3f\xaa\x43\xab\xca\x06\x70\x56\xd7\x50\xb3\xaa\xd2\x5c\x26\x08\xe1\x55\x97\xdc\x62\x97\xa3\xa9\xeb\xaa\xb2\xb8\xc9\x33\x6e\x11\xc6\x7d\xe2\x63\x08\x69\x05\x65\xdc\xff\xd9\x07\x60\xd8\x57\xd7\xd4\x87\x39\xda\xaa\x6a\xdb\x08\x06\xad\x71\xf8\x0d\x8f\xb8\x31\x2a\x12\x0e\x1b\x77\xd2\x90\x88\x5d\x86\x6c\x32\x61\x0e\x3d\xad\xd1\xe4\x4a\xc6\xc4\x8d\xae\x59\x5c\x23\x14\x79\x4c\x46\x61\x53\xb9\x67\xc0\xd5\xbc\x1f\xcd\x43\x6a\xc5\x0d\xb5\x7e\x17\x40\x09\x55\x25\x56\x10\x5e\x0b\x8d\x91\xbd\x91\x91\x8a\x51\xbb\x0a\x32\x83\x75\xfd\xae\xaf\xa8\xb5\xf6\x01\xb5\x56\x1a\x2a\x36\x5a\xe3\x0e\x2e\x2e\x61\xc3\xd7\xe8\x51\x0f\x35\xae\xc4\x53\x00\x9f\xde\x9f\xbf\xff\xe4\xb3\x91\x19\xba\x1a\x36\x7e\xa7\xd6\x5b\xe3\xce\x67\x23\x22\x92\xdb\xdd\xf8\x3c\x58\x7e\xf8\x74\xf1\xe8\xb3\x11\x1e\x3e\xfc\x78\xe6\x9e\x56\x15\x50\xb2\xb3\xb6\xe0\xba\x2e\xb9\x06\x95\xc5\x43\xe3\xd8\x48\xac\x28\x45\xca\xcc\x84\x5f\xd0\x99\x07\xb4\x27\xbc\x46\x72\xe8\x7f\x76\xcb\x7f\xb9\x04\x29\x32\x2a\x63\xd4\x52\x01\xb5\x66\xa3\x23\xfb\x79\x67\x5f\xb6\xe9\x78\xfe\x9b\xf6\x19\xae\xc9\x38\x43\xd9\x56\xdb\x77\xdb\x3b\xf3\x4f\x56\x45\x8d\xbc\x24\x45\x43\x19\x37\xe1\xd6\xe5\x40\xba\xc1\xca\xf3\xc3\x30\xf4\xd9\x88\x8a\xf6\xd8\x68\x94\x89\x35\xec\x07\x1a\xa1\x81\x01\xdb\x39\x69\x29\x1b\xf9\x55\x05\x2d\x8f\x87\xb6\x31\x36\x9a\x4c\xe0\x9b\xe3\xca\x1e\xe9\x1c\x91\xba\x7c\x28\xc1\x8b\x0c\xd7\x8f\xe1\xd4\x65\x36\x24\x74\x04\x9f\xcf\x46\xa4\x60\xff\x09\x40\x94\x54\x79\x13\x8d\x3a\x5e\x55\xe1\xaf\x68\x53\x15\xb7\xcc\xf3\x5d\xbf\x8e\xcb\x7d\xb8\xc8\xc4\xfa\x91\xac\x8f\xea\x3c\x0d\x25\x9a\x17\x91\x3c\x80\x82\xb0\x70\x1e\x4c\x78\x8f\x1b\x55\xa2\x87\x4d\xfc\xd3\x08\xa3\x79\x05\xe2\x23\xcf\xce\x75\xed\xd0\x3e\x51\x79\xf9\xa7\xa9\x7b\x26\x0d\x6a\xfb\x87\xd4\xdd\x3e\x97\x22\xab\x2a\x40\x19\x03\x69\x04\x90\x68\x40\x5d\xb7\x8b\xa7\xcf\x4f\xbf\x9f\xd5\xee\x46\xf8\xb2\xaf\x84\x8d\xe5\x9b\x62\xd8\xe9\xe0\x6c\x05\x52\xed\x6d\x4c\xb9\x81\x25\xa2\xa4\x6b\x37\x13\x91\xb0\xd9\x8e\xc4\xd5\xdd\xb0\xd8\xdc\x2c\x07\xe1\xb6\x22\xcb\xda\x98\xe4\x8e\xa2\x6a\x34\x45\x66\x69\x6c\x89\xa9\xdb\xa4\xaf\x7c\x2f\xc2\x4a\xab\x0d\xcd\x06\xb8\xc9\xed\x0e\x0c\x9d\x31\xda\xbb\xdc\x59\x34\x47\xa2\xfb\xe5\x05\xd1\xf5\xc1\xeb\x9f\x07\x8d\x9c\x3a\x80\xe8\x58\x97\xfb\x4a\x56\x9a\xe0\x80\x07\xfd\x92\x3b\xda\xde\xc3\x63\xef\xb2\x42\x3a\x85\x62\xe5\xc4\xa0\x34\x3e\xfc\xfd\x12\x3e\x3a\x04\x4b\xb8\x84\xd2\x3c\x9c\x3d\xee\xa3\x56\x3a\xbf\x27\xfa\xef\x1c\xf7\x20\x1c\xd4\x4d\x1d\xe4\x51\xda\xdc\xd9\x3b\x9a\xb1\xa8\xe0\x9f\x87\x81\x7a\xd7\xde\x3d\x04\xc7\x5e\xcb\x09\x0c\xf2\xb6\xc4\x83\xc8\x36\xe5\x76\xf0\xe8\x40\xc1\xf8\xff\xc5\xa1\xe9\x1c\x1a\xd8\x6b\x9e\x0f\xde\xc3\xe3\x49\x44\xda\xc4\xba\x4b\xee\x60\x17\x75\x1a\x8d\xef\xff\xc1\xf7\x20\xb5\x4c\x04\x80\x83\xbc\xa0\x71\xc0\x9e\xbe\x20\x47\xcf\x75\xc3\xfb\x6b\x53\xc6\x83\x78\xf4\x3b\x05\x19\x34\xe6\x84\x8a\x48\x91\x05\x83\x94\x0c\xac\x69\xdc\x04\xb4\xde\x52\x67\x9a\x65\x7d\x47\x6e\xda\x59\xee\xe0\x08\xaf\x84\x36\x16\x64\x3f\xe8\x75\x60\x96\x07\x10\x07\xb0\xc4\x44\x48\x9a\x73\xc9\x6b\xff\x66\xd1\x58\xb7\x84\x4b\x34\x72\xeb\xc6\x5c\x2e\x69\x9a\xc6\x1f\x05\xcf\x68\x28\x7a\x67\x2c\xd7\xb6\xa3\xe2\xd4\x95\xe3\x1e\x41\x33\x2c\xba\x33\xbe\x44\x10\xd2\xa2\xce\x35\x92\x8a\x70\x22\x77\xae\xdc\x23\xf2\xf1\x5f\xd4\x6a\xf0\xd0\xd8\xa9\x15\x48\x70\xef\x1d\xcf\x42\xd2\xf6\xe7\x7e\x5b\xc7\x94\x79\xc6\x75\x82\xc6\x92\xbb\x5c\x19\x23\xe8\x35\xc5\x79\x3d\xa2\xe6\xa9\x06\x7a\x4d\xf2\xef\xf6\x86\x34\x49\x41\x7c\x38\xe2\x6d\x23\x0e\xfb\x6c\x6d\x55\x77\x9a\x65\xfd\x65\xdd\x7b\x3d\xe2\x5a\xd0\xf4\x28\x00\xe9\xb3\xba\x9f\x74\xdb\x09\xa1\x6e\xe0\xed\x6c\x7f\xe5\x36\x4a\x85\x4c\xaa\x6a\x98\x4a\x1a\x2f\xcf\x85\xbb\x47\xda\xa1\xf8\xdc\xa2\x69\x43\x4b\x84\x36\x63\x0e\x9b\x36\x02\x19\xd0\x90\x7d\xf3\x94\xeb\x4e\x6c\x6d\x8a\x42\xc3\xd1\x95\x0a\x1b\xf7\xa3\xc3\x6c\x91\x76\xaa\x85\x31\xec\x8d\x3f\xf4\x5e\xc7\x33\x8d\x3c\xde\x81\x51\xfa\xf9\x60\xfc\x13\x25\x7a\xe5\x61\x76\x3e\x78\x87\xb3\xd6\xbe\x72\xbc\xa6\x09\xef\xcf\xdf\x54\x85\x3e\x87\xb7\xe4\xe1\xcd\xd9\xf2\x55\x89\xf9\xf8\xe9\x85\xf9\xf3\x78\x22\xa1\xab\x09\xcd\xb3\xd9\xb2\x1b\x0e\x4c\x70\x7a\x50\x61\x87\x3c\xfa\x65\xf7\xd3\x0c\x22\xf3\x97\x49\xa4\x74\x8c\xed\xf7\x80\x76\x60\xd8\x23\x4f\xbb\x67\xe0\x50\xeb\xeb\x15\x1a\xdd\x23\x77\x17\xbe\x93\x23\x03\xdc\x42\x54\x68\xa3\x74\x73\x55\xa1\x8c\x0d\x6c\x53\x94\xcd\x11\x47\x99\xd8\xb4\xfb\xbc\x71\x44\x3e\x72\x66\x3a\x02\x0e\x1a\x22\x43\xf8\x4e\xf6\xba\x8d\x23\x8c\xfb\xda\xe2\xbe\xaa\xa0\xc5\xa0\x0d\x47\xcf\xdb\xf7\x38\x30\x45\x94\x36\xa3\x09\xb7\x50\x18\x67\xe5\x3e\xc5\x70\x30\xc5\x12\x7f\x14\x28\x2d\x44\x3c\x73\xba\xe4\x1a\xdc\x8d\x36\xaa\xc8\xe2\xee\x84\x49\x7c\xb2\xe0\x46\x9c\xae\xbb\x2f\x9c\x83\x57\x21\xf2\xda\xf4\x48\x9a\x9c\x52\x5c\xb5\xdd\xf9\x49\x7d\x1a\x82\xf5\x91\x9c\x3b\xef\x25\xe6\x07\xf0\x4c\xbd\x3a\x60\x1a\xf9\x6a\x5e\xb7\xbb\xbf\xff\x0b\x00\x00\xff\xff\x10\x3d\x9c\xf7\x2b\x13\x00\x00")

func templatesKvschemaGotmplBytes() ([]byte, error) {
	return bindataRead(
		_templatesKvschemaGotmpl,
		"templates/kvschema.gotmpl",
	)
}

func templatesKvschemaGotmpl() (*asset, error) {
	bytes, err := templatesKvschemaGotmplBytes()
	if err != nil {
		return nil, err
	}

	info := bindataFileInfo{name: "templates/kvschema.gotmpl", size: 4907, mode: os.FileMode(420), modTime: time.Unix(1564964873, 0)}
	a := &asset{bytes: bytes, info: info}
	return a, nil
}

// Asset loads and returns the asset for the given name.
// It returns an error if the asset could not be found or
// could not be loaded.
func Asset(name string) ([]byte, error) {
	cannonicalName := strings.Replace(name, "\\", "/", -1)
	if f, ok := _bindata[cannonicalName]; ok {
		a, err := f()
		if err != nil {
			return nil, fmt.Errorf("Asset %s can't read by error: %v", name, err)
		}
		return a.bytes, nil
	}
	return nil, fmt.Errorf("Asset %s not found", name)
}

// MustAsset is like Asset but panics when Asset would return an error.
// It simplifies safe initialization of global variables.
func MustAsset(name string) []byte {
	a, err := Asset(name)
	if err != nil {
		panic("asset: Asset(" + name + "): " + err.Error())
	}

	return a
}

// AssetInfo loads and returns the asset info for the given name.
// It returns an error if the asset could not be found or
// could not be loaded.
func AssetInfo(name string) (os.FileInfo, error) {
	cannonicalName := strings.Replace(name, "\\", "/", -1)
	if f, ok := _bindata[cannonicalName]; ok {
		a, err := f()
		if err != nil {
			return nil, fmt.Errorf("AssetInfo %s can't read by error: %v", name, err)
		}
		return a.info, nil
	}
	return nil, fmt.Errorf("AssetInfo %s not found", name)
}

// AssetNames returns the names of the assets.
func AssetNames() []string {
	names := make([]string, 0, len(_bindata))
	for name := range _bindata {
		names = append(names, name)
	}
	return names
}

// _bindata is a table, holding each asset generator, mapped to its name.
var _bindata = map[string]func() (*asset, error){
	"templates/kvschema.gotmpl": templatesKvschemaGotmpl,
}

// AssetDir returns the file names below a certain
// directory embedded in the file by go-bindata.
// For example if you run go-bindata on data/... and data contains the
// following hierarchy:
//     data/
//       foo.txt
//       img/
//         a.png
//         b.png
// then AssetDir("data") would return []string{"foo.txt", "img"}
// AssetDir("data/img") would return []string{"a.png", "b.png"}
// AssetDir("foo.txt") and AssetDir("notexist") would return an error
// AssetDir("") will return []string{"data"}.
func AssetDir(name string) ([]string, error) {
	node := _bintree
	if len(name) != 0 {
		cannonicalName := strings.Replace(name, "\\", "/", -1)
		pathList := strings.Split(cannonicalName, "/")
		for _, p := range pathList {
			node = node.Children[p]
			if node == nil {
				return nil, fmt.Errorf("Asset %s not found", name)
			}
		}
	}
	if node.Func != nil {
		return nil, fmt.Errorf("Asset %s not found", name)
	}
	rv := make([]string, 0, len(node.Children))
	for childName := range node.Children {
		rv = append(rv, childName)
	}
	return rv, nil
}

type bintree struct {
	Func     func() (*asset, error)
	Children map[string]*bintree
}

var _bintree = &bintree{nil, map[string]*bintree{
	"templates": &bintree{nil, map[string]*bintree{
		"kvschema.gotmpl": &bintree{templatesKvschemaGotmpl, map[string]*bintree{}},
	}},
}}

// RestoreAsset restores an asset under the given directory
func RestoreAsset(dir, name string) error {
	data, err := Asset(name)
	if err != nil {
		return err
	}
	info, err := AssetInfo(name)
	if err != nil {
		return err
	}
	err = os.MkdirAll(_filePath(dir, filepath.Dir(name)), os.FileMode(0755))
	if err != nil {
		return err
	}
	err = ioutil.WriteFile(_filePath(dir, name), data, info.Mode())
	if err != nil {
		return err
	}
	err = os.Chtimes(_filePath(dir, name), info.ModTime(), info.ModTime())
	if err != nil {
		return err
	}
	return nil
}

// RestoreAssets restores an asset under the given directory recursively
func RestoreAssets(dir, name string) error {
	children, err := AssetDir(name)
	// File
	if err != nil {
		return RestoreAsset(dir, name)
	}
	// Dir
	for _, child := range children {
		err = RestoreAssets(dir, filepath.Join(name, child))
		if err != nil {
			return err
		}
	}
	return nil
}

func _filePath(dir, name string) string {
	cannonicalName := strings.Replace(name, "\\", "/", -1)
	return filepath.Join(append([]string{dir}, strings.Split(cannonicalName, "/")...)...)
}