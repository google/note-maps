# Note Maps: Data Model

A **note map** can be consistently and losslessly represented as a set of
**notes** in which each **note** is a plain object with the following fields
and meanings:

*   **ID**: a valid UUID.
*   **value**: an optional Unicode string. All text typed or pasted into a Note
    Maps app and stored in notes within a note map is stored in the value
    fields of those notes. Any non-empty value can be assumed to have been
    typed or pasted into a Note Maps app.
*   **value type ID**: an optional note ID for a note that describes the data
    type of the value string. A Note Map app should not support editing a
    note's value without also setting the note's value type ID to a type that
    it knows how to work with.
*   **role players**: an optional set of (**role ID**, **player ID**) pairs. A
    note that has a non-empty set for this field can be said to represent an
    **association** between notes. In each pair, **role ID** identifies a note
    that describes a role that a note can play in an association between notes,
    and **player ID** identifies a note that plays the identified role in the
    association represented by this note.
*   **subject identifiers**: a sequence of IRIs that globally uniquely identify
    the subject of this note.
*   **type IDs**: an optional sequence of note IDs for notes that describe the
    kind or type of this note, or what this note is about.
*   **content IDs**: a sequence of note IDs for notes that together form the
    content, or body, of this note.

Most notes will have only one of **value**, **role players**, or **content
IDs**, but it is valid for a note to have all three.

When creating or updating notes, implementations should store only **normalized**
notes, and may silently normalize any note upon reading it from storage. Any
note can be normalized as follows:

*   Any line break or vertical spacing characters in **value** can be removed
    or replaced with horizontal spacing characters.
*   If a field holds an empty string or a list or set of zero elements, that
    field can be removed. Since empty and missing values are semantically
    equivalent, implementations that prefer non-null values can safely
    interpret absent fields has being present with empty values.
*   The ID of any note that represents an **association** should be present in
    the **content IDs** of each note that plays one of its roles.
*   Translating any note map to a directed graph in which every **ID** is
    translated to a unique node and every **content ID** is translated to a
    directed edge from the containing note's ID to the content ID should
    produce a graph with no cycles. For each cycle found, any one edge in that
    cycle can be removed to normalize the note map.

Implementations of this model don't necessarily need to explicitly implement a
matching “note” data type. For example:

*   Instead of representing note IDs in content IDs, an implementation might
    embed whole notes, or store parent ID and position within content notes.
*   Insetad of a set of role-player pairs, an implementation might use a map
    from roles to sets of players.
*   Instead of storing a single Unicode string in value, an implementation
    might store a conflict-free replicated data type (CRDT) that represents a
    string. Even a whole note or note map might be stored as a CRDT.

As an example, following is a note map presented as formatted text and then as
a JSON representation consistent with the specification above:

> ### git (*software*)
>
> A distributed version-control system.
>
> *implementation...data structure:* **merkle tree**

```json
[
  {
    "id": "05f5652c-f2ec-4923-898c-c9aed4a22268",
    "subject_identifiers": ["https://git-scm.com"],
    "type_ids": ["492a47dc-c350-4aae-952a-b9d8602837e8"],
    "content_ids": [
      { "value": "git", "type_ids": ["name"] },
      { "value": "A distributed version-control system." },
      "d6d42492-231f-41c9-a6af-c3c80e8dbd09"
    ]
  },
  {
    "id": "492a47dc-c350-4aae-952a-b9d8602837e8",
    "content_ids": [
      { "type_ids": ["name"], "value": "software" }
    ]
  },
  {
    "id": "d6d42492-231f-41c9-a6af-c3c80e8dbd09",
    "role_players": {
      "1eff6b0c-1fef-4fe3-9f9b-52420ec9feb6": ["05f5652c-f2ec-4923-898c-c9aed4a22268"],
      "": ["3532f60d-0842-456e-bcf4-b28c68d96371"]
    }
  },
  {
    "id": "1eff6b0c-1fef-4fe3-9f9b-52420ec9feb6",
    "content_ids": [
      { "type_ids": ["name"], "value": "implementation" }
    ]
  },
  {
    "id": "3532f60d-0842-456e-bcf4-b28c68d96371",
    "type_ids": ["f5650c12-7f8d-4fa4-af25-f47fd20154ad"],
    "content_ids": [
      { "type_ids": ["name"], "value": "merkle tree" }
    ]
  },
  {
    "id": "f5650c12-7f8d-4fa4-af25-f47fd20154ad",
    "content_ids": [
      { "type_ids": ["name"], "value": "data structure" }
    ]
  }
]
```
