# Note Maps: Data Model

A **note map** is a a collection of *notes*.

A **note** has the following properties.

*   **ID**: a string that uniquely identifies this note within its note map.
*   `si`: **subject identifiers**: a sequence of IRIs that globally uniquely
    identify the subject of this note.
*   `c`: **content IDs**: a sequence of note IDs for notes that together are
    the *content* of this note.
*   `t`: **type IDs**: a sequence of note IDs for notes that describe the
    *type* of the subject of this note.
*   `v`: **value**: an optional string, any valid Unicode string, required if
    *value type ID* is present.
*   `vt`: **value type ID**: an optional note ID for a note that describes the
    data type of the *value* string.
*   `a`: **association ID**: an optional note ID for a note that describes an
    association between subjects, required if **player ID** is present.
*   `ap`: **player ID**: an optional note ID for a note that describes a
    subject that plays a role in an association, required if **association ID**
    is present.

Additional constraints:

*   In some cases, it may be more convenient to embed whole notes instead of
    note IDs.
*   When creating new notes, it may be easier sometimes to leave IDs
    unspecified.
*   For any note that has both an *association ID* and a *role ID*, that note's
    *ID* should be present in the *content IDs* of the corresponding
    association and role notes.

Example, in JSON:

```json
{
  "id": "111"
  "si": ["https://git-scm.com"],
  "c": [
    {
      "t": ["name"],
      "v": "git"
    },
    {
      "v": "A distributed version-control system."
    },
    {
      "ap": "111",
      "a": {
        "c": [
          {
            "t": ["name"],
            "v": "software"
          }
        ]
      }
    }
  ]
}
```

The example above could hypothetically be rendered as:

> ### git
>
> A distributed version-control system.
>
> *example..type:* **software**
