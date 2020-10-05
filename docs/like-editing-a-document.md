# Note Maps: Like Editing a Document

This is an expansion of [Requirements: Functional: UR2: It's like editing a
document](requirements.md#ur2-its-like-editing-a-document).

> Editing a note should feel like editing a document.

## Rough Draft

This pseudo-document should include the following, in order:

1. The note's type. Each note in the type should be rendered by name or
   identifier according to UR1, and these should be delimited by a space
   character. Deleting any character within the name or identifier representing
   a note should remove it from that note's type, automatically applying to all
   the characters used to represent that note in this context.
1. The note's content. Each child note is another paragraph in the document.
   The paragraph may be styled according to the type of the note.  Notes that
   include `org.note-maps.name` in their type should be styled as though they
   are headings.  A child is rendered and edited differently based on whether
   it is an association, see below.
1. The roles of a note, but only if it is already an association. Roles should
   be styled in a way that distinguishes them from content. Editing roles
   should generally feel like editing content, except that each value is
   interpreted as the name or identifier of another note.
1. The value of the note, but only if it already has a value.  If included, and
   its data type is...
   * ...`org.note-maps.text.plain` then editing it should be like editing
     within a multi-line text box.
   * ...`org.note-maps.text.iso8601` then editing it should be like selecting a
     date, date and time, date range, or any of the other values [ISO 8601][]
     allows.

If a child note is not an association, it should be rendered a paragraph that
includes:

1. Optionally, a dot or mark as in a bulleted list.
1. The primary type of the note, rendered by name or identifier according to
   UR1.
1. If the note has a type, it should be followed by a delimiter. This may be
   a space character, a colon (`:`), or anything else as long as it is
   consistent within the document.
1. The value of the note.  If possible, the data type of the value should be
   apparent from the way the value is rendered.
1. Optionally, the content of the note may be included recursively, with
   indentation and/or other styling to distinguish it as the content of this
   note.

If, when editing the value of a child note that does not already have a type, a
delimiter is entered, and the portion of the value up but excluding that
delimiter is a valid identifier (see CR1), then the portion of the value up to
and including that delimiter may be removed and the primary type of the note
may be set to a note whose name matches the portion of the value up to but
excluding the delimiter.  For example, if the child note's value is `color:
purple` and the `:` has just been inserted, then:

* the value should become `purple`.
* a type note with the name `color` should be found or created with no
  additional user interaction except to disambiguate when there are
  already multiple notes named "color".
* the note with the name `color` should be added to the type of this
  child note.

As a variation on the above, if the value up to but excluding the delimiter
contains two consecutive periods (`..`), then the note should become an
association. For example, if the child note's value is `area..project:
learning` and the `:` has just been inserted then:

* a new association note should be created with two roles.
* one role player should be the parent node, with role type `area`.
* the other role player should be the original child note whose value was being
  edited, with role type `project`.
* the original child note's value should be cleared, and it should gain a child
  note of its own of type `org.note-maps.name` and value `learning`.

If a child note is an association, it includes at least one role in which this
parent note is a player. We'll call that the *local role* and the others
*remote roles*. It should also be rendered as a paragraph, but with different
rules. When an association has only two roles, it should be rendered as a
paragraph that includes:

1. Optionally, a dot or mark as for notes that are not associations.
1. The local role type, rendered by name or identifier according to UR1.
1. A delimiter, `..`, even if the local role type is empty.
1. The remote role type, rendered by name or identifier according to UR1.
1. The same delimiter that is used to separate type from value in child notes
   that are not associations (above).
1. The association's name or identifier according to UR1.

If an association includes more than two roles, it must be rendered
differently. Optionally, an association with only two roles may also be
rendered this way.

1. Optionally, a dot or mark as for notes that are not associations.
1. The local role type, rendered by name or identifier according to UR1.
1. A delimiter, `..`, even if the local role type is empty.
1. The association's name or identifier according to UR1.
1. An indented list of the remote roles, where each role is rendered as:
   1. A delimiter, `..`.
   1. The remote role type, rendered by name or identifier according to UR1.
   1. The same delimiter that is used to separate type from value in child notes
      that are not associations (above).
   1. The name or identifier of the remote role player, according to UR1.

In either case, as with child notes that are not associations, this may be
followed by the content of the association.

For example, let's apply this to a note named "My Note Map".  It links to
"research" and "bibliography" notes, and also has a random thought about note
maps.  The link to "research" is expanded, and research represents an "area" of
responsibility in which "learning" and "teaching" are each a "project".  Here's
one way this might be displayed:

> *name*: **My Note Map**\
> *name*: **my personal knowledge base**
>
> ..: **research**
>
> * *area*..*project*: **learning**
> * *area*..*project*: **teaching**
>
> ..: **bibliography**
>
> This is all pretty new to me and I'm expecting to change the structure quite
> a lot over time. That change should be fairly easy because: I add notes first
> and types later, I can easily turn any note into an association, associations
> are easy to change, and it all feels just like editing a document.
