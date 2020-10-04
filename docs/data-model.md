# Note Maps: Data Model

A **note map** is a a collection of *notes*.

A **note** has the following fields.

*   **ID**: a string that uniquely identifies this note within its note map.
*   `t`: **type IDs**: a sequence of note IDs for notes that describe the
    *type* of the subject of this note.
*   `v`: **value**: an optional string, any valid Unicode string.
*   `vt`: **value type ID**: an optional note ID for a note that describes the
    data type of the **value** string.
*   `a`: **association ID**: an optional note ID for a note that describes an
    association between subjects, required if **player ID** is present.
*   `ap`: **player ID**: an optional note ID for a note that describes a
    subject that plays a role in an association, required if **association ID**
    is present.
*   `si`: **subject identifiers**: a sequence of IRIs that globally uniquely
    identify the subject of this note.
*   `c`: **content IDs**: a sequence of note IDs for notes that together are
    the *content* of this note.

There are very few constraints:

*   For any note that has both an *association ID* and a *role ID*, that note's
    *ID* should be present in the *content IDs* of both the corresponding
    association and role notes.

In implementation, even **ID** (the only required field) may be absent for new
notes.

For illustration, it may be more convenient to embed whole notes instead of
note IDs.

An eample, in JSON though there's no requirement JSON be used in the
implementation:

```json
{
  "id": "111",
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
      "t": { "c": [ { "t": ["name"], "v": "example" } ] },
      "a": {
        "ap": {
          "t": { "c": [ { "t": ["name"], "v": "type" } ] },
          "c": [
            {
              "t": ["name"],
              "v": "software"
            }
          ]
        }
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
