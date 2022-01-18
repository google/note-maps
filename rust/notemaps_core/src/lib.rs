// Copyright 2021-2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
// in compliance with the License. You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under the
// License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing permissions and
// limitations under the License.

//! Note Maps: it's like Topic Maps, but for taking notes! See?
//!
//! Within a [NoteMap], each [Note] is fully described with [Properties].  Treat all the notes in a
//! note map as vertices within a graph by wrapping the [NoteMap] in an [ArcNoteMap] and using
//! [GraphNote] to refer to a starting note.  Atomic edits are supported by types that implement
//! the [AtomicNoteMap] trait, which provides shortlived [NoteMap] values that extend [NoteMap]
//! with [PropertiesMut] properties. The canonical implementation of [AtomicNoteMap] is AutomergeNoteMap.

#![feature(toowned_clone_into)]
#![feature(extend_one)]
#![feature(associated_type_bounds)]
#![feature(generic_associated_types)]
#![feature(in_band_lifetimes)]

mod am;
pub mod base; // TODO: move or remove or document or rename or something
mod error;

pub use self::am::Automerge;
pub use self::error::Lint;
pub use self::error::ReadError;
pub use self::error::UserError;

use im::Vector;
use smol_str::SmolStr;
use std::borrow::Borrow;
use std::borrow::Cow;
use std::collections::HashMap;
use std::convert::TryFrom;
use std::fmt;
use std::iter::FromIterator;
use std::ops::Deref;
use std::str::FromStr;
use std::string;
use std::sync::Arc;
use std::sync::Mutex;
use unicode_segmentation::UnicodeSegmentation;

/// The essence of a note is just its identifier.
///
/// This module copies an idea about type names from entity component systems: the "entity" is just
/// an identifier while the schema of its properties may be context-dependent.
///
/// Each note has a unique random value:
/// ```
/// use notemaps_core::Note;
/// let some_note = Note::random();
/// assert_ne!(some_note, Note::random());
/// ```
///
/// The default note is zero-valued and const constructible:
/// ```
/// use notemaps_core::Note;
/// const nil_note: Note = Note::nil();
/// assert_eq!(nil_note, Note::default());
/// ```
#[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub struct Note(uuid::Uuid);

const NOTE_NIL: Note = Note(uuid::Uuid::nil());

impl Note {
    /// Constructs a new zero-valued note.
    ///
    /// The zero-valued note is a valid note and may be associated with non-empty properties in a
    /// note map.
    ///
    /// ```
    /// use notemaps_core::Note;
    /// const nil_note: Note = Note::nil();
    /// ```
    pub const fn nil() -> Self {
        Self(uuid::Uuid::nil())
    }

    /// Consructs a new globally unique note identifier.
    ///
    /// ```
    /// use notemaps_core::Note;
    /// let some_note: Note = Note::random();
    /// assert_ne!(some_note, Note::random());
    /// ```
    pub fn random() -> Self {
        Note(uuid::Uuid::new_v4())
    }

    /// Returns a [SmolStr] representation of this Note.
    ///
    /// ```
    /// use notemaps_core::Note;
    /// assert_eq!("00000000000000000000000000000000", Note::nil().to_smol_str().as_str());
    /// ```
    ///
    /// [Note] also implements [TryFrom] for parsing from strings:
    /// ```
    /// use notemaps_core::Note;
    /// use std::convert::TryFrom;
    /// let random = Note::random();
    /// assert_eq!(random, Note::try_from(random.to_smol_str().as_str()).unwrap());
    /// ```
    pub fn to_smol_str(&self) -> SmolStr {
        SmolStr::from(
            self.0
                .to_simple_ref()
                .encode_lower(&mut uuid::Uuid::encode_buffer()),
        )
    }

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url
    // > --name "https://github.com/google/note-maps" ) --name "name"
    // d75ab1bf-9335-5bba-9fe7-4010a7c62c3c
    /// Add this [Note] to the `isa` property of an occurrence to make that occurrence represent
    /// the name of its parent.
    pub const NAME: Note = Note(uuid::Uuid::from_bytes([
        0xd7, 0x5a, 0xb1, 0xbf, // -
        0x93, 0x35, // -
        0x5b, 0xba, // -
        0x9f, 0xe7, // -
        0x40, 0x10, 0xa7, 0xc6, 0x2c, 0x3c,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url
    // > --name "https://github.com/google/note-maps" ) --name "occurrence"
    // bd3420ae-6ada-57b6-90fe-a2905943835c
    /// This is implicitly included in the `isa` property of all occurrences, especially in
    /// relation to the role each plays in its association with its parent.
    pub const OCCURRENCE: Note = Note(uuid::Uuid::from_bytes([
        0xbd, 0x34, 0x20, 0xae, // -
        0x6a, 0xda, // -
        0x57, 0xb6, // -
        0x90, 0xfe, // -
        0xa2, 0x90, 0x59, 0x43, 0x83, 0x5c,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url
    // > --name "https://github.com/google/note-maps" ) --name "topic"
    // ef7d7cc2-9d14-5ebf-8bf4-e5df9213f282
    /// This is implicitly included in the `isa` property of all occurrences, especially in
    /// relation to the role each plays in its association with its parent.
    pub const TOPIC: Note = Note(uuid::Uuid::from_bytes([
        0xef, 0x7d, 0x7c, 0xc2, // -
        0x9d, 0x14, // -
        0x5e, 0xbf, // -
        0x8b, 0xf4, // -
        0xe5, 0xdf, 0x92, 0x13, 0xf2, 0x82,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url
    // > --name "https://github.com/google/note-maps" ) --name "content"
    // fa853ecb-b902-53e3-b134-964521f6eb0c
    /// A supertype of both names and occurrences.
    pub const CONTENT: Note = Note(uuid::Uuid::from_bytes([
        0xfa, 0x85, 0x3e, 0xcb, // -
        0xb9, 0x02, // -
        0x53, 0xe3, // -
        0xb1, 0x34, // -
        0x96, 0x45, 0x21, 0xf6, 0xeb, 0x0c,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url
    // > --name "https://github.com/google/note-maps" ) --name "association"
    // a82c4498-d170-5bbb-af96-2e178ec4893e
    /// An implicit type for any [Note] that represents an association in which any number of roles
    /// may be played by any number of notes, and each role is identified by its type which is also
    /// a note.
    pub const ASSOCIATION: Note = Note(uuid::Uuid::from_bytes([
        0xa8, 0x2c, 0x44, 0x98, // -
        0xd1, 0x70, // -
        0x5b, 0xbb, // -
        0xaf, 0x96, // -
        0x2e, 0x17, 0x8e, 0xc4, 0x89, 0x3e,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url --name
    // > "https://github.com/google/note-maps" ) --name "datatype"
    // 157c488a-f7cb-593e-a58a-3686413ab0e3
    /// The data type for notes with values that are UTF-8 encoded text.
    pub const DATA_TYPE: Note = Note(uuid::Uuid::from_bytes([
        0x15, 0x7c, 0x48, 0x8a, // -
        0xf7, 0xcb, // -
        0x59, 0x3e, // -
        0xa5, 0x8a, // -
        0x36, 0x86, 0x41, 0x3a, 0xb0, 0xe3,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url --name
    // > "https://github.com/google/note-maps" ) --name "datatype_utf8"
    // 7454ca6e-8b25-58fc-aa2c-d82435c14e08
    /// The data type for notes with values that are UTF-8 encoded text.
    pub const DATA_TYPE_UTF8: Note = Note(uuid::Uuid::from_bytes([
        0x74, 0x54, 0xca, 0x6e, // -
        0x8b, 0x25, // -
        0x58, 0xfc, // -
        0xaa, 0x2c, // -
        0xd8, 0x24, 0x35, 0xc1, 0x4e, 0x08,
    ]));

    // uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url --name
    // > "https://github.com/google/note-maps" ) --name "datatype_note"                                                                                               ~
    // 396e65b3-7ca2-5303-8eb7-c5d9dd8bb80f
    /// The data type for notes with values are are also notes.
    pub const DATA_TYPE_NOTE: Note = Note(uuid::Uuid::from_bytes([
        0x39, 0x6e, 0x65, 0xb3, // -
        0x7c, 0xa2, // -
        0x53, 0x03, // -
        0x8e, 0xb7, // -
        0xc5, 0xd9, 0xdd, 0x8b, 0xb8, 0x0f,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url
    // > --name "https://github.com/google/note-maps" ) --name "subject"
    // a0e0b903-8816-5872-b81c-57c905ea02e8
    /// SUBJECT is a supertype of all types, and all notes are instances of it.
    pub const SUBJECT: Note = Note(uuid::Uuid::from_bytes([
        0xa0, 0xe0, 0xb9, 0x03, // -
        0x88, 0x16, // -
        0x58, 0x72, // -
        0xb8, 0x1c, // -
        0x57, 0xc9, 0x05, 0xea, 0x02, 0xe8,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url
    // > --name "https://github.com/google/note-maps" ) --name "supertype"
    // 495ccea7-7cbe-52b6-b0c6-4d76968001f3
    pub const SUPERTYPE: Note = Note(uuid::Uuid::from_bytes([
        0x49, 0x5c, 0xce, 0xa7, // -
        0x7c, 0xbe, // -
        0x52, 0xb6, // -
        0xb0, 0xc6, // -
        0x4d, 0x76, 0x96, 0x80, 0x01, 0xf3,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url
    // > --name "https://github.com/google/note-maps" ) --name "subtype"
    // 7b12a2bf-b7d5-549f-84b9-2f1a7d293d43
    pub const SUBTYPE: Note = Note(uuid::Uuid::from_bytes([
        0x7b, 0x12, 0xa2, 0xbf, // -
        0xb7, 0xd5, // -
        0x54, 0x9f, // -
        0x84, 0xb9, // -
        0x2f, 0x1a, 0x7d, 0x29, 0x3d, 0x43,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url --name
    // > "https://github.com/google/note-maps" ) --name "instance"
    // 823860cc-8f47-5af4-afac-75f92fcae59c
    pub const INSTANCE: Note = Note(uuid::Uuid::from_bytes([
        0x82, 0x38, 0x60, 0xcc, // -
        0x8f, 0x47, // -
        0x5a, 0xf4, // -
        0xaf, 0xac, // -
        0x75, 0xf9, 0x2f, 0xca, 0xe5, 0x9c,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url --name
    // > "https://github.com/google/note-maps" ) --name "type"
    // 3aeb7694-c427-57fc-8824-757f3184ccdd
    pub const TYPE: Note = Note(uuid::Uuid::from_bytes([
        0x3a, 0xeb, 0x76, 0x94, // -
        0xc4, 0x27, // -
        0x57, 0xfc, // -
        0x88, 0x24, // -
        0x75, 0x7f, 0x31, 0x84, 0xcc, 0xdd,
    ]));

    // $ uuidgen --sha1 --namespace $( uuidgen --sha1 --namespace @url --name
    // > "https://github.com/google/note-maps" ) --name "role_type"
    // 68d375dd-3520-584c-939f-2fb071586770
    pub const ROLE_TYPE: Note = Note(uuid::Uuid::from_bytes([
        0x68, 0xd3, 0x75, 0xdd, // -
        0x35, 0x20, // -
        0x58, 0x4c, // -
        0x93, 0x9f, // -
        0x2f, 0xb0, 0x71, 0x58, 0x67, 0x70,
    ]));

    pub fn loopback(self) -> base::AnchoredStep {
        base::AnchoredStep::new(Some(self), base::Step::loopback())
    }
    pub fn supertypes(self) -> base::AnchoredStep {
        base::AnchoredStep::new(Some(self), base::Step::supertypes())
    }
    pub fn supertypes_transitive(self) -> base::AnchoredStep {
        base::AnchoredStep::new(Some(self), base::Step::supertypes_transitive())
    }
    pub fn subtypes(self) -> base::AnchoredStep {
        base::AnchoredStep::new(Some(self), base::Step::subtypes())
    }
    pub fn subtypes_transitive(self) -> base::AnchoredStep {
        base::AnchoredStep::new(Some(self), base::Step::subtypes_transitive())
    }
    pub fn types(self) -> base::AnchoredStep {
        base::AnchoredStep::new(Some(self), base::Step::types())
    }
    pub fn instances(self) -> base::AnchoredStep {
        base::AnchoredStep::new(Some(self), base::Step::instances())
    }
    pub fn traverse(self, from_role: Note, to_role: Note) -> base::AnchoredStep {
        base::AnchoredStep::new(Some(self), base::Step::traverse(from_role, to_role))
    }
}

impl From<&Note> for Note {
    fn from(n: &Note) -> Note {
        *n
    }
}

impl fmt::Display for Note {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        std::fmt::Display::fmt(&self.0.to_simple_ref(), f)
    }
}

impl TryFrom<&str> for Note {
    type Error = UserError;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Note::from_str(value)
    }
}

impl std::str::FromStr for Note {
    type Err = UserError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(Note(uuid::Uuid::parse_str(s).map_err(UserError::from)?))
    }
}

#[cfg(test)]
mod test_node {
    use super::*;

    #[test]
    fn default_to_string_is_zeros() {
        assert_eq!(
            Note::default().to_string(),
            "00000000000000000000000000000000"
        );
        assert_eq!(Note::default(), Note::nil());
    }

    #[test]
    fn zeros_parse_as_default() {
        assert_eq!(
            "00000000000000000000000000000000".parse::<Note>().unwrap(),
            Note::default()
        );
        use std::convert::TryInto;
        let actual: Note = "00000000000000000000000000000000".try_into().unwrap();
        assert_eq!(actual, Note::default());
    }

    #[test]
    fn random_is_unique() {
        assert_ne!(Note::random(), Note::random());
    }

    #[test]
    fn to_string_and_parse_is_identity() {
        assert_eq!(
            Note::default().to_string().parse::<Note>().unwrap(),
            Note::default()
        );
        let random = Note::random();
        assert_eq!(random.to_string().parse::<Note>().unwrap(), random);
        assert_eq!(random.to_smol_str().parse::<Note>().unwrap(), random);
    }
}

/// A common, sealed trait implemented by all types that represent components of a note.
pub trait Component:
    Clone + fmt::Debug + Default + From<AnyComponent> + PartialEq + Eq + private::Sealed
{
    fn as_notes(&self) -> Notes {
        Notes::Option(None.into_iter())
    }
    fn to_string(&self) -> String {
        Default::default()
    }
}

#[derive(Clone, Debug, Default, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct ValueText(Vector<u8>);
impl ValueText {
    pub fn into_bytes(self) -> Vec<u8> {
        self.0.into_iter().collect()
    }
    pub fn to_bytes(&self) -> Vec<u8> {
        self.0.iter().copied().collect()
    }
    pub fn to_string(&self) -> Result<String, string::FromUtf8Error> {
        String::from_utf8(self.to_bytes())
    }
    pub fn to_string_lossy(&self) -> String {
        String::from_utf8_lossy(self.to_bytes().as_ref()).to_string()
    }
}
impl<T: Borrow<str>> From<T> for ValueText {
    fn from(src: T) -> Self {
        Self(src.borrow().bytes().collect())
    }
}
impl From<AnyComponent> for ValueText {
    fn from(src: AnyComponent) -> Self {
        if let AnyComponent::ValueText(src) = src {
            src
        } else {
            Self::default()
        }
    }
}
impl Component for ValueText {
    fn to_string(&self) -> String {
        self.to_string_lossy()
    }
}
impl<T: Deref<Target = str>> OpTarget<T> for ValueText {
    type Result = Self;
    fn apply_ops<I: Iterator<Item = Op<T>>>(&self, ops: I) -> Self::Result {
        let ops = ops.map(|op| op.map(|s| Vec::from(s.deref().as_bytes())));
        Self(self.0.apply_ops(ops))
    }
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct ValueDatatype(Note);
impl<T: Into<Note>> From<T> for ValueDatatype {
    fn from(src: T) -> Self {
        Self(src.into())
    }
}
impl From<AnyComponent> for ValueDatatype {
    fn from(_: AnyComponent) -> Self {
        todo!("")
    }
}
impl Component for ValueDatatype {
    fn as_notes(&self) -> Notes {
        Notes::Option(Some(self.0).into_iter())
    }
}

#[derive(Clone, Debug, Default, PartialEq, Eq, Hash)]
pub struct IsA(Vector<Note>);
impl<T: Into<Vector<Note>>> From<T> for IsA {
    fn from(src: T) -> Self {
        Self(src.into())
    }
}
impl From<AnyComponent> for IsA {
    fn from(_: AnyComponent) -> Self {
        todo!("")
    }
}
impl Component for IsA {
    fn as_notes(&self) -> Notes {
        Notes::Vector(self.0.iter())
    }
}

#[derive(Clone, Debug, Default, PartialEq, Eq, Hash)]
pub struct Occurrences(Vector<Note>);
impl<T: Into<Vector<Note>>> From<T> for Occurrences {
    fn from(src: T) -> Self {
        Self(src.into())
    }
}
impl From<AnyComponent> for Occurrences {
    fn from(_: AnyComponent) -> Self {
        todo!("")
    }
}
impl Component for Occurrences {
    fn as_notes(&self) -> Notes {
        Notes::Vector(self.0.iter())
    }
}

mod private {
    pub trait Sealed {}
    impl Sealed for super::ValueText {}
    impl Sealed for super::ValueDatatype {}
    impl Sealed for super::IsA {}
    impl Sealed for super::Occurrences {}
}

#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub enum AnyComponent {
    ValueText(ValueText),
    ValueDatatype(ValueDatatype),
    IsA(IsA),
    Occurrences(Occurrences),
}

impl<T: Component> From<T> for AnyComponent {
    fn from(_: T) -> Self {
        todo!("")
    }
}

pub enum Notes<'a> {
    Option(std::option::IntoIter<Note>),
    Vector(im::vector::Iter<'a, Note>),
}

impl Iterator for Notes<'a> {
    type Item = Note;

    fn next(&mut self) -> Option<Self::Item> {
        match self {
            Self::Option(iter) => iter.next(),
            Self::Vector(iter) => iter.next().copied(),
        }
    }
}

/// Identifies the part of a note that is being read, written, or mutated in low-level operations
/// on [Note]s.
#[derive(Copy, Clone, Debug, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub enum Field {
    /// Just the Note itself.
    ///
    /// Cannot be mutated.
    Note,
    /// Always represented as a sequence of graphemes.
    ValueText,
    /// Always represented as a single [Note].
    ValueDatatype,
    /// Always represented as a sequence of [Note].
    IsA,
    /// Always represented as a sequence of [Note].
    Occurrences,
}

impl Field {
    pub fn as_str(&self) -> &'static str {
        match self {
            Field::Note => "note",
            Field::ValueText => "value_text",
            Field::ValueDatatype => "value_datatype",
            Field::IsA => "isa",
            Field::Occurrences => "occurrences",
        }
    }
    pub fn parse(value: &str) -> Result<Self, ReadError> {
        match value {
            "note" => Ok(Field::Note),
            "value_text" => Ok(Field::ValueText),
            "value_datatype" => Ok(Field::ValueDatatype),
            "isa" => Ok(Field::IsA),
            "occurrences" => Ok(Field::Occurrences),
            _ => Err(ReadError::IOError(value.into())),
        }
    }
}

impl TryFrom<&str> for Field {
    type Error = ReadError;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Self::parse(value)
    }
}

impl FromStr for Field {
    type Err = ReadError;
    fn from_str(value: &str) -> Result<Self, Self::Err> {
        Self::parse(value)
    }
}

#[cfg(test)]
mod test_field {
    use super::*;

    #[test]
    fn as_str_and_parse_is_identity() {
        assert_eq!(Field::Note.as_str().parse(), Ok(Field::Note));
        assert_eq!(Field::ValueText.as_str().parse(), Ok(Field::ValueText));
        assert_eq!(
            Field::ValueDatatype.as_str().parse(),
            Ok(Field::ValueDatatype)
        );
        assert_eq!(Field::IsA.as_str().parse(), Ok(Field::IsA));
        assert_eq!(Field::Occurrences.as_str().parse(), Ok(Field::Occurrences));
    }
}

/// Looks up the properties of any given note on demand.
///
/// This is the most basic representation of a note map, allowing read-only access to any note.  A
/// significant limitiation is that it does not support any form of searching, not eveny to simply
/// scan all the notes in a map.
pub trait NoteMap: Clone {
    type Properties: Properties;

    fn get(&self, note: &Note) -> Self::Properties;

    fn gett<T: Component>(&self, note: &Note) -> T {
        match AnyComponent::from(T::default()) {
            AnyComponent::ValueText(_) => {
                AnyComponent::ValueText(self.get(note).value().text.into())
            }
            AnyComponent::ValueDatatype(_) => {
                AnyComponent::ValueDatatype(self.get(note).value().datatype.into())
            }
            AnyComponent::IsA(_) => AnyComponent::IsA(self.get(note).isa().into()),
            AnyComponent::Occurrences(_) => {
                AnyComponent::Occurrences(self.get(note).occurrences().into())
            }
        }
        .into()
    }

    fn into_graph_note(self, note: Note) -> GraphNote<Self>
    where
        Self: Sized,
    {
        GraphNote::new(self, note)
    }

    fn graph_note(&self, note: Note) -> GraphNote<Self>
    where
        Self: Clone + Sized,
    {
        self.clone().into_graph_note(note)
    }

    /// Applies any set of changes expressed as a slice of (Note, NoteDelta) values.
    fn apply_delta<'a, T, U, V>(&self, notemap_delta: T) -> Result<(), UserError>
    where
        Self::Properties: PropertiesMut,
        T: IntoIterator<Item = (U, V)>,
        U: Borrow<Note>,
        V: Borrow<[NoteDelta<'a>]>,
    {
        for (note, note_deltas) in notemap_delta {
            self.get(note.borrow()).apply_delta(note_deltas.borrow())?;
        }
        Ok(())
    }
}

pub type NoteMapDB = ArcNoteMap<am::AutomergeNoteMap>;

pub fn temporary() -> NoteMapDB {
    ArcNoteMap::from(
        am::AutomergeNoteMap::open(am::Location::Memory)
            .unwrap()
            .unwrap(),
    )
}

use std::path;

pub fn open(p: Box<path::Path>) -> Result<Result<NoteMapDB, UserError>, am::DurabilityError> {
    match am::AutomergeNoteMap::open(am::Location::SledPath(p))? {
        Ok(notemap) => Ok(Ok(ArcNoteMap::from(notemap))),
        Err(err) => Ok(Err(err)),
    }
}

pub fn open_named(name: &str) -> Result<Result<NoteMapDB, UserError>, am::DurabilityError> {
    match am::AutomergeNoteMap::open(am::Location::SledName(name.to_string()))? {
        Ok(notemap) => Ok(Ok(ArcNoteMap::from(notemap))),
        Err(err) => Ok(Err(err)),
    }
}

/// The value of a note.
///
/// All textual information stored in a note map is stored in [Value]s.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct Value {
    text: String,
    datatype: Note,
}

impl Value {
    fn new<T: Into<String>>(text: T, datatype: Note) -> Self {
        Self {
            text: text.into(),
            datatype,
        }
    }
    pub fn is_empty(&self) -> bool {
        self.text.is_empty() && self.datatype == NOTE_NIL
    }
    pub fn text(&self) -> &str {
        self.text.as_str()
    }
    pub fn datatype(&self) -> Note {
        self.datatype
    }
}

impl<T> From<T> for Value
where
    T: Into<String>,
{
    fn from(value: T) -> Self {
        Self::new(value, Note::default())
    }
}

/// Represents the ability to read basic information about, or [Properties] of, a [Note].
///
/// The note itself, which is only an identifier, is deliberately excluded to avoid redundancy.
/// [Properties] are typically, if not always, constructed in response to a request about a
/// specified [Note].
///
/// For mutable access to [Properties], see [PropertiesMut].
pub trait Properties {
    /// For the given [Note], returns the associated [Value].
    ///
    /// All textual information stored n a note map is stored in [Value]s.
    ///
    /// For example, a notes that describes this module might have the value `written in Rust`.
    fn value(&self) -> Value;

    /// For the given [Note], returns its type, or types.
    ///
    /// For example, `Rust` *isa* `programming language`: for a note representing Rust, the
    /// sequence returned by this method might include a note representing "programming language".
    fn isa(&self) -> Vec<Note>;

    /// For the given [Note], returns its occurrences, or "notes in which this note occurs."
    ///
    /// This name comes from Topic Maps, and traces back to an analogy to the structure of printed
    /// indices found near the back of reference books. A high-level note represents a "topic" that
    /// "occurs" in specified pages of the book, or of other related books. Topic Maps expanded the
    /// idea of an occurrence to more broadly include other metadata about a topic, including for
    /// example what might be printed in a dictionary if each topic represented a word to be
    /// defined.
    ///
    /// In Note Maps, occurrences will also include what Topic Maps distinguished as
    /// "associations". For example, a note might be used to describe the relationship is between
    /// Rust and C++. If that note becomes an "association" between the note representing Rust and
    /// the note representing C++, then it also becomes an occurrence of each of those notes.
    fn occurrences(&self) -> Vec<Note>;

    /// Returns true if and only if these properties are indistinguishable from those of a note
    /// that has never been written.
    fn is_empty(&self) -> bool {
        self.value().is_empty() && self.isa().is_empty() && self.occurrences().is_empty()
    }

    fn matches(&self, predicate: &Predicate) -> bool {
        match predicate {
            Predicate::HasValueDatatype(datatype) => self.value().datatype() == *datatype,
            Predicate::IsA(ntype) => self.isa().contains(ntype),
        }
    }

    fn matches_all(&self, predicates: &[Predicate]) -> bool {
        predicates.iter().all(|p| self.matches(p))
    }

    fn traverse(&self, dimension: Dimension) -> Vec<Note> {
        match dimension {
            Dimension::IsA => self.isa(),
            Dimension::Occurrences => self.occurrences(),
            Dimension::ValueDatatype => Some(self.value().datatype()).into_iter().collect(),
        }
    }
}

#[cfg(test)]
mod test_properties {
    use super::*;
    #[test]
    fn matches_isa() {
        let actual = Note::random();
        let mut props = PropertiesSnapshot::default();
        props.update_isa(&[Op::Insert(vec![actual])]).expect("");
        assert!(props.matches(&Predicate::IsA(actual)));
        assert!(!props.matches(&Predicate::IsA(Note::random())));
    }
}

/// A simple and direct implementation of the [Properties] trait.
///
/// Contains errors (lint check failures) to allow partial reads in case of data loss. This may be
/// removed or replaced with something more sophisticated so that later versions will be able to
/// display placeholders for unrecognized information or unsupported data formats.
#[derive(Default, Clone)]
pub struct PropertiesSnapshot {
    value: Value,
    isa: Vec<Note>,
    occurrences: Vec<Note>,
}

impl Properties for PropertiesSnapshot {
    fn value(&self) -> Value {
        self.value.clone()
    }
    fn isa(&self) -> Vec<Note> {
        self.isa.clone()
    }
    fn occurrences(&self) -> Vec<Note> {
        self.occurrences.clone()
    }
}

impl PropertiesMut for PropertiesSnapshot {
    fn update_value_text(&mut self, delta: &[StrOp<'_>]) -> Result<&mut Self, UserError> {
        self.value.text = self.value.text.apply_ops(Vec::from(delta).into_iter());
        Ok(self)
    }

    fn update_value_datatype(&mut self, datatype: Note) -> Result<&mut Self, UserError> {
        self.value.datatype = datatype;
        Ok(self)
    }

    fn update_isa(&mut self, delta: &[NotesOp]) -> Result<&mut Self, UserError> {
        self.isa = self.isa.apply_ops(Vec::from(delta).into_iter());
        Ok(self)
    }

    fn update_occurrences(&mut self, delta: &[NotesOp]) -> Result<&mut Self, UserError> {
        self.occurrences = self.occurrences.apply_ops(Vec::from(delta).into_iter());
        Ok(self)
    }
}

/// Represents the ability to read basic information about a note including the [Note] itself.
pub trait Identified: Properties {
    fn note(&self) -> Note;
}

/// Represents the ability to make changes to a note.
///
/// This is a low-level interface designed to be implemented by specialized types in
/// backend-specific modules, and extended with convenient functions with default definitions.
///
/// The success of a mutation should not be affected by whether a note already exists: all notes
/// should be treated as existing implicitly, empty by default. If necessary, implementations
/// should create new notes on demand, and only when required to apply a mutation.
pub trait PropertiesMut: Properties {
    /// Updates the `text` property of the associated [Note]'s [Value] by applying `delta`.
    fn update_value_text(&mut self, delta: &[StrOp<'_>]) -> Result<&mut Self, UserError>;

    /// Updates the `datatype` property of the associated [Note]'s [Value] by replacing it with
    /// `datatype`.
    fn update_value_datatype(&mut self, datatype: Note) -> Result<&mut Self, UserError>;

    /// Updates the `isa` property of the associated [Note] by applying `delta`.
    fn update_isa(&mut self, delta: &[NotesOp]) -> Result<&mut Self, UserError>;

    /// Updates the `occurrences` property of the associated [Note] by applying `delta`.
    fn update_occurrences(&mut self, delta: &[NotesOp]) -> Result<&mut Self, UserError>;

    /// Inserts `remote_id` as an occurrence of this note, at position `index` within this note's
    /// occurrences.
    ///
    /// This function has a default implementation based on [PropertiesMut::update_occurrences].
    fn link_occurrence(&mut self, index: usize, remote_id: Note) -> Result<(), UserError> {
        self.update_occurrences(&[Op::Retain(index), vec![remote_id].into()])?;
        Ok(())
    }

    /// Unlinks the child note at the given index.
    ///
    /// If the unlinked note is empty and has no other parent or other context to give it meaning,
    /// then this is equivalent to deleting the note.
    ///
    /// Implementations may reject the edit if the unlinked note is not empty and has no other
    /// parent.
    ///
    /// This function has a default implementation based on [PropertiesMut::update_occurrences].
    fn unlink_occurrence(&mut self, index: usize) -> Result<(), UserError> {
        self.update_occurrences(&[Op::Retain(index), Op::Delete(1)])?;
        Ok(())
    }

    /// Changes the position of existing child notes within this parent note
    ///
    /// This function has a default implementation based on [PropertiesMut::update_occurrences].
    fn move_occurrences(&mut self, _from: &[usize], _to: usize) -> Result<(), UserError> {
        todo!("ref: move occurrences");
    }

    /// Applies any set of changes expressed as a slice of [NoteDelta] values.
    fn apply_delta<'a>(&mut self, note_deltas: &[NoteDelta<'a>]) -> Result<(), UserError> {
        for note_delta in note_deltas {
            use NoteDelta::*;
            match note_delta {
                ValueText(ops) => {
                    self.update_value_text(ops)?;
                }
                ValueDatatype(note) => {
                    self.update_value_datatype(*note)?;
                }
                Occurrence(ops) => {
                    self.update_occurrences(ops)?;
                }
                IsA(ops) => {
                    self.update_isa(ops)?;
                }
            }
        }
        Ok(())
    }
}

/// Represents an operation that can be applied to an existing sequence of values to produce a new
/// sequence of values.
///
/// Intended to be used in slices of [Op] values to describe any possible translation from any
/// possible existing sequence to any possible new sequence. For example, to translate "Hello."
/// into "Hello, world!", any of the following will do:
/// ```
/// use notemaps_core::Op;
/// let mut ops: Vec<Op<String>> = vec![
///     Op::Retain(5),
///     Op::Delete(1),
///     Op::Insert(", world!".into()),
/// ];
/// ops = vec![
///     Op::Retain(5),
///     Op::Delete(1),
///     ", world!".into(),  // convenient conversion into Op::insert
/// ];
/// ops = vec![
///     Op::Retain(5),
///     Op::Delete(1),  // [Delete,Insert] has the same meaning as [Insert,Delete]
///     ", world!".into(),
/// ];
/// ```
///
/// See [OpTarget] for usage.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum Op<Sequence> {
    Retain(usize),
    Delete(usize),
    Insert(Sequence),
}

pub type StrOp<'a> = Op<Cow<'a, str>>;

pub type NotesOp = Op<Vec<Note>>;

impl<Sequence> Op<Sequence> {
    fn is_empty(&self) -> bool {
        match self {
            Op::Retain(len) => *len == 0,
            Op::Delete(len) => *len == 0,
            Op::Insert(_) => false,
        }
    }
    /// Maps an `Op<Sequence>` to an `Op<T>`.
    fn map<T, F>(&self, f: F) -> Op<T>
    where
        F: FnOnce(&Sequence) -> T,
    {
        match self {
            Op::Retain(len) => Op::Retain(*len),
            Op::Delete(len) => Op::Delete(*len),
            Op::Insert(src) => Op::Insert(f(src)),
        }
    }
}

impl<Sequence> From<Sequence> for Op<Sequence> {
    fn from(value: Sequence) -> Self {
        Op::Insert(value)
    }
}

impl<'a> From<&'a str> for Op<Cow<'a, str>> {
    fn from(value: &'a str) -> Self {
        Op::Insert(value.into())
    }
}

impl<'a> From<&'a str> for Op<String> {
    fn from(value: &'a str) -> Self {
        Op::Insert(value.into())
    }
}

impl<T> From<i32> for Op<Vec<T>> {
    fn from(value: i32) -> Self {
        if value >= 0 {
            Self::Retain(value as usize)
        } else {
            Self::Delete((-value) as usize)
        }
    }
}

impl From<i32> for Op<Cow<'a, str>> {
    fn from(value: i32) -> Self {
        if value >= 0 {
            Self::Retain(value as usize)
        } else {
            Self::Delete((-value) as usize)
        }
    }
}

impl From<i32> for Op<String> {
    fn from(value: i32) -> Self {
        if value >= 0 {
            Self::Retain(value as usize)
        } else {
            Self::Delete((-value) as usize)
        }
    }
}

pub trait Delta<Sequence>: IntoIterator<Item = Op<Sequence>> + FromIterator<Op<Sequence>> {
    fn retain(&mut self, len: usize)
    where
        Self: Extend<Self::Item>,
    {
        self.extend_one(Op::Retain(len));
    }

    fn delete(&mut self, len: usize)
    where
        Self: Extend<Self::Item>,
    {
        self.extend_one(Op::Delete(len));
    }

    fn insert(&mut self, items: Sequence)
    where
        Self: Extend<Self::Item>,
    {
        self.extend_one(Op::Insert(items));
    }

    fn normalized(self) -> Self {
        self.into_iter().filter(|op| !op.is_empty()).collect()
    }
}

impl<Sequence> Delta<Sequence> for Vec<Op<Sequence>> {}

/// Represents the ability to apply a sequence of [Op]s to produce a new value.
///
/// Implemented for str:
/// ```
/// use notemaps_core::{Op, OpTarget};
/// assert_eq!(
///     "Hello.".apply_ops(vec![Op::Retain(5), Op::Insert(", world!"), Op::Delete(1)].into_iter()),
///     "Hello, world!"
/// );
/// ```
///
/// Implemented for Vec:
/// ```
/// use notemaps_core::{Op, OpTarget};
/// assert_eq!(
///     vec![1,2,3].apply_ops(vec![Op::Delete(3), Op::Insert(vec![42])].into_iter()),
///     vec![42]
/// );
/// ```
pub trait OpTarget<T: Sized> {
    type Result;
    fn apply_ops<I: Iterator<Item = Op<T>>>(&self, ops: I) -> Self::Result;
}

impl<T: Deref<Target = str>> OpTarget<T> for str {
    type Result = String;
    fn apply_ops<I: Iterator<Item = Op<T>>>(&self, ops: I) -> Self::Result {
        let mut zero = 0;
        let mut is = self.grapheme_indices(true);
        let mut dst = Self::Result::default();
        let remainder: Op<T> = Op::Retain(usize::MAX);
        for op in ops.chain(std::iter::once(remainder)) {
            let n = match op {
                Op::Retain(n) => n,
                Op::Insert(_) => 0,
                Op::Delete(n) => n,
            };
            let end = if let Some(Some((end, last))) =
                (0..n).map(|_| is.next()).take_while(|x| x.is_some()).last()
            {
                end + last.len()
            } else {
                self.len()
            };
            match op {
                Op::Retain(_) => {
                    dst.push_str(&self[zero..end]);
                }
                Op::Insert(text) => {
                    dst.push_str(text.borrow());
                }
                Op::Delete(_) => {}
            }
            zero = end;
        }
        dst
    }
}

impl<T: Copy> OpTarget<Vec<T>> for Vec<T> {
    type Result = Self;
    fn apply_ops<I: Iterator<Item = Op<Vec<T>>>>(&self, ops: I) -> Self::Result {
        let mut i = 0;
        let mut dst = Self::default();
        let remainder: Op<Vec<T>> = Op::Retain(usize::MAX);
        for op in ops.chain(std::iter::once(remainder)) {
            match op {
                Op::Retain(n) => {
                    let safe = n.min(self.len() - i);
                    dst.extend(&self.as_slice()[i..i + safe]);
                    i += safe;
                }
                Op::Insert(items) => {
                    dst.extend(items);
                }
                Op::Delete(n) => {
                    i += n.min(self.len() - i);
                }
            }
        }
        dst
    }
}

use std::iter::IntoIterator;
impl<T: Copy, S: IntoIterator<Item = T>> OpTarget<S> for Vector<T> {
    type Result = Self;

    fn apply_ops<I: Iterator<Item = Op<S>>>(&self, ops: I) -> Self::Result {
        let mut remainder = self.clone();
        let mut dst = Self::new();
        let retain_all = Op::Retain(usize::MAX);
        for op in ops.chain(std::iter::once(retain_all)) {
            match op {
                Op::Retain(n) => {
                    let safe = n.min(remainder.len());
                    dst.append(remainder.split_off(safe))
                }
                Op::Insert(items) => dst.append(Vector::from_iter(items.into_iter())),
                Op::Delete(n) => {
                    remainder = remainder.split_off(n.min(remainder.len()));
                }
            }
        }
        dst
    }
}

#[cfg(test)]
mod op_test {
    use super::*;

    #[test]
    fn str_apply_empty_op_slice() {
        let empty: Vec<Op<String>> = vec![];
        assert_eq!("".apply_ops(empty.into_iter()), "");
    }

    #[test]
    fn str_apply_just_insert() {
        assert_eq!("".apply_ops(vec![Op::Insert("ABC")].into_iter()), "ABC");
    }

    #[test]
    fn str_apply_just_delete() {
        let ops: Vec<Op<String>> = vec![Op::Delete(1)];
        assert_eq!("\r\nABC".apply_ops(ops.into_iter()), "ABC");
    }

    #[test]
    fn str_apply_retain_then_insert() {
        assert_eq!(
            "\r\n".apply_ops(vec![Op::Retain(1), Op::Insert("ABC")].into_iter()),
            "\r\nABC"
        );
    }

    #[test]
    fn str_apply_retain_then_delete() {
        let ops: Vec<Op<String>> = vec![Op::Retain(1), Op::Delete(3)];
        assert_eq!("\r\nABC".apply_ops(ops.into_iter()), "\r\n");
    }

    #[test]
    fn vec_apply_empty_op_slice() {
        assert_eq!(
            Vec::<i32>::default().apply_ops(vec![].into_iter()),
            Vec::<i32>::new()
        );
    }

    #[test]
    fn vec_apply_just_insert() {
        assert_eq!(
            vec![].apply_ops(vec![Op::Insert(vec!['A', 'B', 'C'])].into_iter()),
            vec!['A', 'B', 'C']
        );
    }

    #[test]
    fn vec_apply_just_delete() {
        assert_eq!(
            vec!['a', 'b', 'c'].apply_ops(vec![Op::Delete(2)].into_iter()),
            vec!['c']
        );
    }
}

/// Identifies dimensions that might be traversed by a query for related notes.
///
/// Given a set of selected [Note]s, or more likely [GraphNote]s, related notes can be found by
/// traversing any of these dimensions.
#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum Dimension {
    /// The value datatype dimension. Traverse this dimension to reach the notes representing the
    /// data types of the values of selected notes.
    ValueDatatype,

    /// The "IS-A" dimension. Traverse this dimesion to reach the notes representing the types of
    /// selected notes.
    IsA,

    /// The occurrences dimension. Traverse this dimesion to reach the notes representing the
    /// occurrences of selected notes.
    Occurrences,
}

impl Dimension {
    pub fn to_field(self) -> Option<Field> {
        match self {
            Self::ValueDatatype => Some(Field::ValueDatatype),
            Self::IsA => Some(Field::IsA),
            Self::Occurrences => Some(Field::Occurrences),
        }
    }
}

/// Identifies an edge in a graph of notes.
///
/// An edge describes a parent, a [Dimension] that might be traversed from that parent, and offset
/// into the notes one would find in such a traversal, and the child that would be found at that
/// offset.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Edge<T: Sized> {
    parent: T,
    child: T,
    dimension: Dimension,
    offset: usize,
}

impl<T: Sized> Edge<T> {
    pub fn new(parent: T, child: T, dimension: Dimension, offset: usize) -> Self {
        Self {
            parent,
            child,
            dimension,
            offset,
        }
    }
    pub fn parent(&self) -> &T {
        &self.parent
    }
    pub fn child(&self) -> &T {
        &self.child
    }
    pub fn dimension(&self) -> Dimension {
        self.dimension
    }
    pub fn offset(&self) -> usize {
        self.offset
    }
    pub fn map_to<U, F: Fn(&T) -> U>(&self, map: F) -> Edge<U> {
        Edge::new(
            map(&self.parent),
            map(&self.child),
            self.dimension,
            self.offset,
        )
    }
    pub fn map_into<U, F: Fn(T) -> U>(self, map: F) -> Edge<U> {
        Edge::new(
            map(self.parent),
            map(self.child),
            self.dimension,
            self.offset,
        )
    }
}

/// Describes a context in which a template might be evaluated.
#[derive(Debug, Clone)]
pub enum Situated<T: Sized> {
    /// Identifies a note as though it is the "root" note of the larger template context.
    Root(T),

    /// Identifies a note along with the edge that led to it.
    Child(Edge<T>),
}

impl<T: Sized> Situated<T> {
    pub fn child(&self) -> &T {
        match self {
            Situated::Root(note) => note,
            Situated::Child(edge) => edge.child(),
        }
    }
    pub fn edge(&self) -> Option<&Edge<T>> {
        match self {
            Situated::Root(_) => None,
            Situated::Child(edge) => Some(edge),
        }
    }
}

/// Describes a simple predicate for notes.
///
/// A predicate matches only on the immediate properties of a note, that is on [Properties].  For
/// example, a `Predicate::IsA` can be used to check whether a note is an instance of some type:
/// ```
/// use notemaps_core::{Note, Predicate, Properties, PropertiesSnapshot};
/// let some_type = Note::random();
/// let mut props = PropertiesSnapshot::default();
/// assert!(!props.matches(&Predicate::IsA(some_type)));
/// ```
#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum Predicate {
    HasValueDatatype(Note),
    IsA(Note),
}

/// Represents a [Dimension] filtered by a set of [Predicate]s.
///
/// A filtered dimension can express some useful basic queries. For example, if we use a [Note]
/// that represents the idea of a "name" as the type (is-a) of occurrences that represent names,
/// then we can find all the names of a note by filtering occurrences by type:
/// ```
/// use notemaps_core::{Dimension, FilteredDimension, Predicate, Note};
/// let name_type = Note::NAME;
/// let name_dimension: FilteredDimension = (Dimension::Occurrences, Predicate::IsA(name_type)).into();
/// ```
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct FilteredDimension {
    dimension: Dimension,
    predicates: Vec<Predicate>,
}

impl FilteredDimension {
    pub fn new(dimension: Dimension, predicates: Vec<Predicate>) -> Self {
        Self {
            dimension,
            predicates,
        }
    }
    pub fn dimension(&self) -> Dimension {
        self.dimension
    }
    pub fn predicates(&self) -> &[Predicate] {
        self.predicates.as_slice()
    }
}

impl From<Dimension> for FilteredDimension {
    fn from(dimension: Dimension) -> Self {
        FilteredDimension::new(dimension, vec![])
    }
}

impl From<(Dimension, Predicate)> for FilteredDimension {
    fn from((dimension, predicate): (Dimension, Predicate)) -> Self {
        FilteredDimension::new(dimension, vec![predicate])
    }
}

impl From<(Dimension, Vec<Predicate>)> for FilteredDimension {
    fn from((dimension, predicates): (Dimension, Vec<Predicate>)) -> Self {
        FilteredDimension::new(dimension, predicates)
    }
}

/// Describes a query as a path through a graph of notes, where each step in the path is a
/// [FilteredDimension].
///
/// For example, to find the names of a note's types:
/// ```
/// use notemaps_core::{Dimension, FilteredDimension, Note, Path, Predicate};
/// let type_names: Path = [
///     FilteredDimension::from(Dimension::IsA),
///     (Dimension::Occurrences, Predicate::IsA(Note::NAME)).into(),
/// ].iter().cloned().collect();
/// ```
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct Path(Vec<FilteredDimension>);

impl Path {
    pub fn as_slice(&self) -> &[FilteredDimension] {
        self.0.as_slice()
    }
    pub fn is_single_step(&self) -> bool {
        self.0.len() == 1
    }
}

impl From<Vec<FilteredDimension>> for Path {
    fn from(value: Vec<FilteredDimension>) -> Self {
        Path(value)
    }
}

impl FromIterator<FilteredDimension> for Path {
    fn from_iter<T: IntoIterator<Item = FilteredDimension>>(iter: T) -> Self {
        Path(Vec::from_iter(iter))
    }
}

impl Extend<FilteredDimension> for Path {
    fn extend<T: IntoIterator<Item = FilteredDimension>>(&mut self, iter: T) {
        self.0.extend(iter)
    }
}

/// Represents a [Note] within a [NoteMap], providing traits [Properties] and [Identified].
///
/// Also provides [PropertiesMut] if possible.
///
/// Designed to be useful against all note map backends, GraphNote is intended to support fluent access
/// to notes in the form of a graph, and to provide all relevant traits that the backend provides.
#[derive(Clone, Debug)]
pub struct GraphNote<NM: NoteMap>(NM, Note);

impl<NM> GraphNote<NM>
where
    NM: NoteMap,
{
    /// Constructs a [GraphNote] that will dynamically look up the [Properties] of `note` in `notemap`.
    pub fn new(notemap: NM, note: Note) -> Self {
        Self(notemap, note)
    }
}

impl<NM> GraphNote<NM>
where
    NM: NoteMap,
{
    /// Returns a reference to the backing note map.
    pub fn notemap(&self) -> &NM {
        &self.0
    }

    /// Returns a [GraphNote] for each [Note] in this note's "isa" property.
    pub fn isa(&self) -> Vec<Self> {
        <Self as Properties>::isa(self)
            .into_iter()
            .map(|n| Self::new(self.0.clone(), n))
            .collect()
    }

    /// Returns a [GraphNote] for each [Note] in this note's "occurrences" property.
    pub fn occurrences(&self) -> Vec<Self> {
        <Self as Properties>::occurrences(self)
            .into_iter()
            .map(|n| Self::new(self.0.clone(), n))
            .collect()
    }

    /// Traverses `path`, calling `visit` for each leaf.
    pub fn traverse(&self, path: &[FilteredDimension], visit: &mut impl Extend<Edge<Self>>) {
        if let Some(fd) = path.first() {
            let step = self.step(fd.dimension, fd.predicates.as_slice());
            let path = &path[1..];
            if path.is_empty() {
                visit.extend(step.into_iter().map(|(offset, child)| {
                    Edge::new(
                        self.clone(),
                        child, // TODO: remove clone here
                        fd.dimension,
                        offset,
                    )
                }));
            } else {
                // TODO: There is a risk of stack overflow here given a long enough path. Refactor
                // to use O(1) stack frames.
                step.for_each(|(_, recurse)| recurse.traverse(path, visit));
            }
        }
    }

    fn step<'a: 'c, 'b: 'c, 'c>(
        &'a self,
        dimension: Dimension,
        predicates: &'b [Predicate],
    ) -> impl 'c + Iterator<Item = (usize, Self)> {
        <Self as Properties>::traverse(self, dimension)
            .into_iter()
            .enumerate()
            .map(move |(offset, note)| (offset, Self::new(self.0.clone(), note)))
            .filter(move |(_, recurse)| recurse.matches_all(predicates))
    }

    /// Traverses `path`, returning the first matching note, if any.
    pub fn traverse_first(&self, path: &[FilteredDimension]) -> Option<Situated<Self>> {
        if let Some(fd) = path.first() {
            let mut step = <Self as Properties>::traverse(self, fd.dimension)
                .into_iter()
                .enumerate()
                .map(|(offset, note)| (offset, Self::new(self.0.clone(), note)))
                .filter(|(_, recurse)| recurse.matches_all(fd.predicates.as_slice()));
            let path = &path[1..];
            if path.is_empty() {
                step.next().map(|(offset, child)| {
                    Situated::Child(Edge::new(self.clone(), child, fd.dimension, offset))
                })
            } else {
                step.map(|(_, recurse)| recurse.traverse_first(path).into_iter())
                    .flatten()
                    .next()
            }
        } else {
            Some(Situated::Root(self.clone()))
        }
    }
}

impl<NM> Identified for GraphNote<NM>
where
    NM: NoteMap,
{
    fn note(&self) -> Note {
        self.1
    }
}

impl<NM> Properties for GraphNote<NM>
where
    NM: NoteMap,
{
    fn value(&self) -> Value {
        self.0.get(&self.1).value()
    }
    fn isa(&self) -> Vec<Note> {
        self.0.get(&self.1).isa()
    }
    fn occurrences(&self) -> Vec<Note> {
        self.0.get(&self.1).occurrences()
    }
}

impl<NM> PropertiesMut for GraphNote<NM>
where
    NM: NoteMap,
    NM::Properties: PropertiesMut,
{
    fn update_value_text<'a>(&mut self, delta: &[StrOp<'a>]) -> Result<&mut Self, UserError> {
        self.0.get(&self.1).update_value_text(delta)?;
        Ok(self)
    }
    fn update_value_datatype(&mut self, datatype: Note) -> Result<&mut Self, UserError> {
        self.0.get(&self.1).update_value_datatype(datatype)?;
        Ok(self)
    }
    fn update_isa(&mut self, delta: &[NotesOp]) -> Result<&mut Self, UserError> {
        self.0.get(&self.1).update_isa(delta)?;
        Ok(self)
    }
    fn update_occurrences(&mut self, delta: &[NotesOp]) -> Result<&mut Self, UserError> {
        self.0.get(&self.1).update_occurrences(delta)?;
        Ok(self)
    }
}

/// Represents the ability to make atomic edits to a note map.
///
/// Mutable note maps typically should only be written through a type that provides the
/// [AtomicNoteMap] trait.
pub trait AtomicNoteMap {
    type PropertiesMut<'a>: PropertiesMut;
    type NoteMapMut<'a>: NoteMap<Properties = Self::PropertiesMut<'a>>;

    /// Create a change by applying `edit` to a [NoteMap].
    fn merge_local<F, O>(&mut self, msg: &'static str, edit: F) -> Result<O, UserError>
    where
        F: for<'a> FnOnce(Self::NoteMapMut<'a>) -> Result<O, UserError>;
}

/// A note map adapter that provides useful traits around an Arc<Mutex<T>> for any T that also
/// provides those traits.
#[derive(Default)]
pub struct ArcNoteMap<T: NoteMap>(Arc<Mutex<T>>);

impl<T: NoteMap> From<T> for ArcNoteMap<T> {
    fn from(map: T) -> Self {
        Self(Arc::new(Mutex::new(map)))
    }
}

impl<T: NoteMap> NoteMap for ArcNoteMap<T> {
    type Properties = T::Properties;

    fn get(&self, index: &Note) -> Self::Properties {
        self.lock().expect("mutex is poisoned").get(index)
    }
}

impl<T: NoteMap + AtomicNoteMap> AtomicNoteMap for ArcNoteMap<T> {
    type PropertiesMut<'a> = T::PropertiesMut<'a>;
    type NoteMapMut<'a> = T::NoteMapMut<'a>;

    fn merge_local<F, O>(&mut self, msg: &'static str, edit: F) -> Result<O, UserError>
    where
        F: for<'a> FnOnce(Self::NoteMapMut<'a>) -> Result<O, UserError>,
    {
        self.0
            .as_ref()
            .lock()
            .unwrap() // panic if mutex is poisoned
            .merge_local(msg, edit)
    }
}

impl<T: NoteMap> Clone for ArcNoteMap<T> {
    fn clone(&self) -> Self {
        Self(self.0.clone())
    }
}

impl<T: NoteMap> Deref for ArcNoteMap<T> {
    type Target = Mutex<T>;

    fn deref(&self) -> &Self::Target {
        self.0.deref()
    }
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum NoteDelta<'a> {
    ValueText(Vec<StrOp<'a>>),
    ValueDatatype(Note),
    Occurrence(Vec<NotesOp>),
    IsA(Vec<NotesOp>),
}

impl<'a> NoteDelta<'a> {
    fn into_owned(self) -> NoteDelta<'static> {
        use NoteDelta::*;
        match self {
            ValueText(ops) => ValueText(
                ops.into_iter()
                    .map(|op| {
                        use Op::*;
                        match op {
                            Retain(len) => Retain(len),
                            Delete(len) => Delete(len),
                            Insert(text) => Insert(Cow::from(text.to_string())),
                        }
                    })
                    .collect(),
            ),
            ValueDatatype(note) => ValueDatatype(note),
            Occurrence(note) => Occurrence(note),
            IsA(note) => IsA(note),
        }
    }

    fn normalized(self) -> Self {
        use NoteDelta::*;
        match self {
            ValueText(ops) => ValueText(ops.normalized()),
            ValueDatatype(_) => self,
            Occurrence(ops) => Occurrence(ops.normalized()),
            IsA(ops) => IsA(ops.normalized()),
        }
    }
}

/// A collection of [NoteDelta] values together with the [Note]s they're for.
///
/// A NoteMapDelta an be constructed or extended both as a seqeuence of `(Note, NoteDelta)` and as
/// a sequence of `(Note, Vec<NoteDelta>)` pairs.
///
/// Intended to be used as an intermediate representation of a change to a note map just before
/// actually applying that change.
#[derive(Clone, Debug, Default, Eq)]
pub struct NoteMapDelta<'a>(std::collections::HashMap<Note, Vec<NoteDelta<'a>>>);

impl<'a> NoteMapDelta<'a> {
    pub fn entry_or_default(&mut self, note: Note) -> &mut Vec<NoteDelta<'a>> {
        self.0.entry(note).or_default()
    }
    pub fn into_owned(self) -> NoteMapDelta<'static> {
        self.into_iter()
            .map(|(note, vec)| {
                (
                    note,
                    Vec::from_iter(vec.into_iter().map(|delta| delta.into_owned())),
                )
            })
            .collect()
    }

    pub fn push(&mut self, note: Note, delta: NoteDelta<'a>) {
        let deltas = self.entry_or_default(note);
        //for prior in deltas {
        //   if
        deltas.push(delta.normalized());
    }
}

impl<'a> IntoIterator for NoteMapDelta<'a> {
    type Item = (Note, Vec<NoteDelta<'a>>);
    type IntoIter = <HashMap<Note, Vec<NoteDelta<'a>>> as IntoIterator>::IntoIter;

    fn into_iter(self) -> Self::IntoIter {
        self.0.into_iter()
    }
}

impl<'a> FromIterator<(Note, Vec<NoteDelta<'a>>)> for NoteMapDelta<'a> {
    fn from_iter<T: IntoIterator<Item = (Note, Vec<NoteDelta<'a>>)>>(iter: T) -> Self {
        Self(HashMap::from_iter(iter))
    }
}

impl<'a> FromIterator<(Note, NoteDelta<'a>)> for NoteMapDelta<'a> {
    fn from_iter<T: IntoIterator<Item = (Note, NoteDelta<'a>)>>(iter: T) -> Self {
        let mut result = Self::default();
        for (note, delta) in iter.into_iter() {
            result.entry_or_default(note).push(delta)
        }
        result
    }
}

impl<'a> Extend<(Note, Vec<NoteDelta<'a>>)> for NoteMapDelta<'a> {
    fn extend<T: IntoIterator<Item = (Note, Vec<NoteDelta<'a>>)>>(&mut self, iter: T) {
        for (note, deltas) in iter.into_iter() {
            self.entry_or_default(note).extend(deltas);
        }
    }
}

impl<'a> Extend<(Note, NoteDelta<'a>)> for NoteMapDelta<'a> {
    fn extend<T: IntoIterator<Item = (Note, NoteDelta<'a>)>>(&mut self, iter: T) {
        for (note, delta) in iter.into_iter() {
            self.entry_or_default(note).push(delta);
        }
    }
}

impl<'a> PartialEq for NoteMapDelta<'a> {
    fn eq(&self, other: &Self) -> bool {
        self.0.len() == other.0.len()
            && self
                .0
                .iter()
                .all(|(k, v)| v.iter().zip(other.0[k].iter()).all(|(s, o)| s == o))
    }
}

use std::ops::Index;
impl<'a> Index<Note> for NoteMapDelta<'a> {
    type Output = Vec<NoteDelta<'a>>;

    fn index(&self, index: Note) -> &Self::Output {
        &self.0[&index]
    }
}

#[cfg(test)]
mod test {
    /*
    #[test]
    fn default_empty() {
        let notemap = ArcAutomergeNoteMap::default();
        let note = Note::random();
        let props = GraphNote::new(notemap.clone(), note);
        assert_eq!(props.note(), note);
        assert_eq!(props.value(), Default::default());
        assert_eq!(props.occurrences().len(), 0);
        assert!(props.is_empty());
    }

    #[test]
    fn observe_updated_value() {
        let mut notemap = ArcAutomergeNoteMap::default();
        let note = Note::random();
        let test_note_0 = GraphNote::new(notemap.clone(), note);
        notemap
            .merge_local("", |notemap| {
                notemap
                    .get(&note)
                    .update_value_text(&["test_value_0".as_graphemes().into()])?;
                Ok(())
            })
            .expect("failed to set initial content for testing");
        assert_eq!(test_note_0.value(), Value::from("test_value_0"));
        assert!(!test_note_0.is_empty());
    }

    #[test]
    fn observe_updated_occurrences() {
        let mut notemap = ArcAutomergeNoteMap::default();
        let note = Note::random();
        let occurrence = Note::random();
        let test_note_0 = GraphNote::new(notemap.clone(), note);
        notemap
            .merge_local("", |notemap| {
                notemap.get(&note).link_occurrence(0, occurrence)
            })
            .expect("failed to set initial content for testing");
        assert_eq!(test_note_0.occurrences()[0].note(), occurrence);
        assert!(!test_note_0.is_empty());
    }

    #[test]
    fn observe_nearby_value() {
        let mut notemap = ArcAutomergeNoteMap::default();
        let note = Note::random();
        let occurrence = Note::random();
        let test_note_0 = GraphNote::new(notemap.clone(), note);
        notemap
            .merge_local("", |notemap| {
                notemap.get(&note).link_occurrence(0, occurrence)
            })
            .expect("failed to set initial content for testing");
        let test_occurrence_0 = GraphNote::new(notemap.clone(), occurrence);
        notemap
            .merge_local("", |notemap| {
                notemap
                    .get(&occurrence)
                    .update_value_text(&["test_value_0".as_graphemes().into()])?;
                Ok(())
            })
            .expect("failed to set initial content for testing");
        assert_eq!(test_occurrence_0.value().text(), "test_value_0");
        assert_eq!(test_note_0.occurrences().len(), 1);
        assert_eq!(test_note_0.occurrences()[0].value().text(), "test_value_0");
    }
    */
}
