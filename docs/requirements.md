# Note Maps: Requirements

Status: **draft**

## Objective

> Suppose you could have a note taking app that's also a personal database and
> works a bit like a structured document editor.  Sound interesting?
>
> What if this note taking app is also offline-first, peer-to-peer replicated,
> collaborative, and encrypted on the wire in a way that lets untrusted peers
> be trusted for replicated storage?
>
> [2020-05-15](https://twitter.com/joshuatacoma/status/1261254734327025669)

Note Maps will be all of the above.

## Requirements

### Functional

#### FR1: Edit the value of a note

Editing a note can mean changing the *value* of a note.  The **value** of a
note is always available as plain text, but may have another data type.  The
data type of a note's value is a note identifier.  The default data type for a
note's value is a built-in "plain text" type.  If the data type is not
supported, it should not be possible to edit the value without also changing
the data type to a supported data type.  The following data types are built in
and must be supported:

* `org.note-maps.text.plain`: a value is valid only if it is valid text, and
  should be preserved as entered.
* `org.note-maps.text.iso8601`: a value is valid only if it is valid according
  to [ISO 8601][].

Invalid values may be rejected as input.  Even if invalid values are rejected
as input, they may be present in notes from another source: this should not
cause any failures or errors, but may cause a warning.

[ISO 8601]: https://en.wikipedia.org/wiki/ISO_8601

#### FR2: Edit the content of a note

Editing a note can mean adding, removing, or re-ordering the *content* of a
note.  The **content** of a note is a sequence of note identifiers.  New notes
may be created by adding to the content of an existing note.  A given note is
the **parent** of an other note and that note is its **child** if and only if
the given note has the other note in its content.  Notes cannot be accidentally
deleted by removing them from the content of a note: instead, a note that is
removed from the content of a note without being present in the content of
another note simply becomes a note without a parent.

#### FR3: Edit the type of a note

Editing a note can mean adding to or removing from the *type* of a note.  The
**type** of a note is a set of note identifiers, one of which is the **primary
type** of the note.

* `org.note-maps.name`: the type of a note that represents a **name** of its
  parent. This way, a note can have zero or more names. The content of a note
  may be automatically re-ordered so that notes that include this type precede
  those that do not.

#### FR4: Edit links between notes

Editing a note can mean linking it to or unlinking it from another note.  A
link between notes is also a note, or an **association**.  Editing an
association means adding or removing a *role* within that association.  A
**role** is a pair of note identifiers: the type of the role in that link, and
the note that plays that role in that link.  A role type may be empty, but a
role without a player should be removed or ignored.  Any given note's content
includes an association if and only if the given note plays a role in the link
note.

#### FR5: Delete a note

A note is effectively deleted when it has no value, no type, no content, and no
roles.  There is a "delete" operation that can clear the value, type, content,
and roles of a note, effectively deleting it.

#### FR6: Search

A note map can be searched with a query constructed from simple text input.

### Usable

#### UR1: Render by name

In contexts where a note must be displayed in a context with no additional
detail, it should be rendered as the value of one of its names.  Only values
that are also valid identifiers should be used in this way.  If a note has no
such name, it should be rendered as its identifier.  The value of a name should
always be visually distinct from an identifier.  The following built-in note
identifiers should always have a name in the current locale, examples are
included in English:

| note identifier              | name `[en]` |
| ---------------------------- | ----------- |
| `org.note-maps.name`         | name        |
| `org.note-maps.text.plain`   | text        |
| `org.note-maps.text.iso8601` | date        |

In any context where this rules is applied, it should also be easy to interact
with the name or identifier to find out more about that note.

#### UR2: It's like editing a document

Editing a note should feel like editing a document.

#### UR3: Note taking can begin immediately on first launch

On first launch, the default behavior is to create a new note and begin editing it.

#### UR4: Meet or exceed applicable UI guidelines

Every major platform has published exhaustive UI guidelines. Meeting or
exceeding these guidelines should generally mean improving accessibility and
ease of use.

### Technical

#### TR1: Private notes

Only the author of a note, and whoever the author chooses to share that note
with, should be able to read it.

#### TR2: Durable notes

Notes should never be entirely lost as they might be, for example, a mobile
device or server was broken.

#### TR3: Network is not required for general use

Nobody should be unable to take notes or review the notes they've taken due to
a loss of connectivity.

#### TR4: Works on mobile platforms

All this should be possible on Android and iOS devices.

#### TR5: Works on laptop and desktop platforms

All this should be possible on laptop and desktop machines.

### Interaction

#### IR1: Share from other apps

It should be easy to share content from other mobile apps into notes in a note
map on Android and iOS devices.

#### IR2: Share to other apps

It should be easy to share content from note maps into other mobile apps on
Android and iOS devices.

### Constraints

#### CR1: Valid note identifiers

A note identifier:

* May contain characters from the following Unicode character classes:
  * Letter (L)
  * Mark (M)
  * Number (N)
* May contain any of these characters: `.`, `-`.
* Must not begin or end with a period (`.`).
* Must not contain multiple consecutive periods (`..`).
* Must not be empty.

These requirements may change to add to the set of valid
identifiers, but never to remove from it.
