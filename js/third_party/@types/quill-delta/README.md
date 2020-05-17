# @types/quill-delta

These files were produced from a later build of 'quill-delta' then copied here
and minimally packaged in order to support building Note Maps.

```
$ git clone https://github.com/quilljs/delta
$ cd delta
$ npm i
$ cat dist/*.d.ts \
  | grep -v 'import' \
  | sed -e 's/export default/declare/' \
  > "${NOTE_MAPS?}/js/third_party/@types/quill-delta/index.d.ts"
```

One manual change: the above procedure sorts the types
alphabetically, putting `Op` at the end of the file. It must
be moved to the beginning.
