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

//use super::offsets::Byte;
use super::offsets::Grapheme;
//use core::any::Any;
use core::ops::Range;
use std::rc::Rc;
//use core::ops::Deref;

use crate::*;

/// [Piece] is a `str`-like type that also:
/// - is immutable,
/// - shares a backing buffer for cheap clones and slices,
/// - and measure offsets in user-perceived graphemes instead of bytes or chars.
///
/// [Piece] is intended to be used with [MarkStr] and [Text].
///
/// # Examples
///
/// ```
/// use notemaps_text::Piece;
/// use notemaps_text::offsets::Grapheme;
///
/// let piece: Piece = "this is a test".into();
/// let slice: Piece = piece.slice(Grapheme(10)..Grapheme(14));
/// assert_eq!(slice.as_str(), "test");
/// ```
#[derive(Clone, Debug)]
pub struct Piece {
    buffer: Rc<str>,
    byte_range: Range<usize>,
    len_graphemes: Grapheme,
    marks: MarkSet,
}

impl Piece {
    pub fn new(buffer: Rc<str>) -> Self {
        use unicode_segmentation::UnicodeSegmentation;
        let byte_range = 0..buffer.len();
        let len_graphemes = buffer.graphemes(true).count().into();
        Self {
            buffer,
            byte_range,
            len_graphemes,
            marks: MarkSet::new(),
        }
    }

    pub fn slice(&self, r: Range<Grapheme>) -> Self {
        use std::iter;
        use unicode_segmentation::UnicodeSegmentation;
        let mut graphemes = self
            .as_str()
            .grapheme_indices(true)
            .map(|t| t.0)
            .chain(iter::once(self.as_str().len()));
        let start = graphemes
            .by_ref()
            .nth(*r.start.as_ref())
            .expect("range starts within bounds of this piece");
        let end = if r.is_empty() {
            start
        } else {
            graphemes
                .by_ref()
                .nth(*r.end.as_ref() - 1 - *r.start.as_ref())
                .expect("range ends within bounds of piece")
        };
        Self {
            buffer: self.buffer.clone(),
            byte_range: start..end,
            len_graphemes: (r.end - r.start).into(),
            marks: MarkSet::new(),
        }
    }

    pub fn len(&self) -> Grapheme {
        self.len_graphemes
    }

    pub fn as_str(&self) -> &str {
        &self.buffer[self.byte_range.clone()]
    }

    pub fn marks(&self) -> &MarkSet {
        &self.marks
    }

    pub fn marks_mut(&mut self) -> &mut MarkSet {
        &mut self.marks
    }
}

impl AsRef<str> for Piece {
    fn as_ref(&self) -> &str {
        self.as_str()
    }
}

impl<'a> From<&'a str> for Piece {
    fn from(s: &'a str) -> Self {
        Self::new(s.into())
    }
}

#[derive(Clone, Debug)]
struct Table {
    pieces: Vec<MarkStr<Piece>>,
    len_graphemes: Grapheme,
}

impl Table {
    pub fn len(&self) -> Grapheme {
        self.len_graphemes
    }
}

impl FromIterator<MarkStr<Piece>> for Table {
    fn from_iter<T: IntoIterator<Item = MarkStr<Piece>>>(iter: T) -> Self {
        let pieces: Vec<_> = iter.into_iter().collect();
        let len_graphemes = pieces.iter().map(|m| m.get().len()).sum();
        Self {
            pieces,
            len_graphemes,
        }
    }
}

enum TextInternal {
    Empty,
    Piece(MarkStr<Piece>),
    Table(Table),
}

use std::any::Any;

/// [Text] is a "piece chain" or "piece table" using [Piece] and [MarkStr] to represent a
/// formatted, or "rich-text", document.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::Text;
///
/// let text: Text = ["Hello, world!", "\n"].into_iter().collect();
/// assert_eq!(text.to_string(), "Hello, world!\n");
/// ```
pub struct Text(TextInternal);

impl Text {
    pub fn pieces(&self) -> Pieces {
        use std::iter;
        Pieces(match &self.0 {
            TextInternal::Empty => PiecesInternal::Empty(iter::empty()),
            TextInternal::Piece(piece) => PiecesInternal::Piece(iter::once(&piece)),
            TextInternal::Table(table) => PiecesInternal::Table(table.pieces.iter()),
        })
    }

    pub fn len(&self) -> Grapheme {
        match &self.0 {
            TextInternal::Empty => Grapheme(0),
            TextInternal::Piece(piece) => piece.get().len(),
            TextInternal::Table(table) => table.len(),
        }
    }

    pub fn to_string(&self) -> String {
        self.pieces().map(|p| p.as_str()).collect()
    }

    pub fn with_insert<I: IntoIterator>(&self, _at: Grapheme, _text: I) -> Self
    where
        Text: FromIterator<I::Item>,
    {
        todo!("");
    }

    pub fn with_mark<M: Any>(&self, _r: Range<Grapheme>, _mark: M) -> Self {
        todo!("");
    }
}

impl FromIterator<MarkStr<Piece>> for Text {
    fn from_iter<T: IntoIterator<Item = MarkStr<Piece>>>(iter: T) -> Self {
        use std::iter;
        let mut iter = iter.into_iter();
        Text(match iter.next() {
            Some(piece0) => match iter.next() {
                Some(piece1) => TextInternal::Table(
                    iter::once(piece0)
                        .chain(iter::once(piece1))
                        .chain(iter)
                        .collect(),
                ),
                None => TextInternal::Piece(piece0),
            },
            None => TextInternal::Empty,
        })
    }
}

impl FromIterator<Piece> for Text {
    fn from_iter<T: IntoIterator<Item = Piece>>(iter: T) -> Self {
        iter.into_iter()
            .map(|piece| MarkStr::new(MarkSet::new(), piece))
            .collect()
    }
}

impl<'a> FromIterator<&'a str> for Text {
    fn from_iter<T: IntoIterator<Item = &'a str>>(iter: T) -> Self {
        iter.into_iter().map(Piece::from).collect()
    }
}

use core::ops;

impl ops::Add<Self> for Text {
    type Output = Self;
    fn add(self, other: Self) -> Self {
        self.pieces().chain(other.pieces()).cloned().collect()
    }
}

enum PiecesInternal<'a> {
    Empty(std::iter::Empty<&'a MarkStr<Piece>>),
    Piece(std::iter::Once<&'a MarkStr<Piece>>),
    Table(std::slice::Iter<'a, MarkStr<Piece>>),
}

/// [Pieces] is the [Iterator] type returned by [Text::pieces].
pub struct Pieces<'a>(PiecesInternal<'a>);

impl<'a> Iterator for Pieces<'a> {
    type Item = &'a MarkStr<Piece>;
    fn next(&mut self) -> Option<Self::Item> {
        match &mut self.0 {
            PiecesInternal::Empty(iter) => iter.next(),
            PiecesInternal::Piece(iter) => iter.next(),
            PiecesInternal::Table(iter) => iter.next(),
        }
    }
}

#[cfg(test)]
mod a_piece_table {
    use super::*;
    #[test]
    fn constructed_from_strs() {
        let text: Text = ["a̐éö̲", "\r\n"].into_iter().collect();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
        assert_eq!(text.len(), Grapheme(4));
    }
}

/*
pub trait Cursor {
    type Item:?Sized;
    fn move_next(&mut self);
    fn move_prev(&mut self);
    fn current(&self) -> Option<&Self::Item>;
    fn index(&self)->Option<usize>;
}

pub struct SliceCursor<'a, T> {
    slice: &'a [T],
    i: usize,
}

impl<'a, T> Cursor for SliceCursor<'a, T> {
    type Item = T;
    fn move_next(&mut self) {
        if self.i < self.slice.len() {
            self.i += 1;
        } else {
            self.i = 0;
        }
    }
    fn move_prev(&mut self) {
        if self.i > 0 {
            self.i -= 1;
        } else {
            self.i = self.slice.len();
        }
    }
    fn current(&self) -> Option<&T> {
        if self.i < self.slice.len() {
            Some(&self.slice[self.i])
        } else {
            None
        }
    }
    fn index(&self)->Option<usize>{
        if self.i<self.slice.len(){
            Some(self.i)
        }else{
            None
        }
    }
}

impl<'a, T> From<&'a [T]> for SliceCursor<'a, T> {
    fn from(slice: &'a [T]) -> Self {
        Self { slice, i: 0 }
    }
}

#[cfg(test)]
mod a_slice_cursor {
    use super::*;

    #[test]
    fn moves_forward_through_a_slice_as_ring() {
        let slice = vec!["red", "blue", "green"];
        let mut cursor = SliceCursor::from(slice.as_ref());
        assert_eq!(cursor.current().copied(), Some("red"));
        cursor.move_next();
        assert_eq!(cursor.current().copied(), Some("blue"));
        cursor.move_next();
        assert_eq!(cursor.current().copied(), Some("green"));
        cursor.move_next();
        assert_eq!(cursor.current(), None);
        cursor.move_next();
        assert_eq!(cursor.current().copied(), Some("red"));
    }

    #[test]
    fn moves_backward_through_a_slice_as_ring() {
        let slice = vec!["red", "blue", "green"];
        let mut cursor = SliceCursor::from(slice.as_ref());
        assert_eq!(cursor.current().copied(), Some("red"));
        cursor.move_prev();
        assert_eq!(cursor.current(), None);
        cursor.move_prev();
        assert_eq!(cursor.current().copied(), Some("green"));
        cursor.move_prev();
        assert_eq!(cursor.current().copied(), Some("blue"));
    }
}

use core::ops::Range;
use unicode_segmentation::GraphemeCursor as GraphemeBoundaryCursor;
use unicode_segmentation::GraphemeIncomplete;
//use std::borrow::Cow;

pub struct GraphemeCursor< T> {
    //'a, T:Cursor<'a,U >, U:AsRef<str>> {
    strings: T,
    absolute: Range<usize>,
    relative: Range<usize>,
    boundaries: GraphemeBoundaryCursor,
    broken: Option<GraphemeIncomplete>,
}

impl< T: Cursor> GraphemeCursor< T> {}

impl< T: Cursor> Cursor for GraphemeCursor< T>
where
    T::Item: AsRef<str>,
{
    type Item = str;

    fn move_next(&mut self) {
        //if self.strings.current().is_none() { self.strings.move_next(); self.start = 0; self.boundaries.set_cursor(0); self.broken = None; }
        while let Some(s) = self.strings.current().map(|s|s.as_ref()) {
            let start = self.boundaries.cur_cursor();
            match self.boundaries.next_boundary(s, 0) {
                Ok(Some(end)) => {
                    // This is the typical case: we have moved to the next grapheme within the
                    // current string.
                    self.relative = start..end;
                    self.absolute =
                    return;
                }
                Ok(None) => {
                    // We've reached the end of current string, so let's start anew at the
                    // beginning of the next one.
                    self.strings.move_next();
                    self.cur = 0..0;
                    self.boundaries.set_cursor(0);
                }
                Err(err) => {
                    self.broken = Some(err);
                    return;
                }
            }
        }
        // In case we break out of the loop without returning, we've reached the end of the
        // sequence of underlying strings.
    }

    fn move_prev(&mut self) {
        todo!("")
    }

    fn current(&self) -> Option<&str> {
        self.strings.current().map(|s|&s.as_ref()[self.cur.clone()])
    }

    fn index(&self)->Option<usize>{
        self.
    }
}

impl< T: Cursor> From<T> for GraphemeCursor< T>
where
    T::Item: AsRef<str>,
{
    fn from(strings: T) -> Self {
        let mut self_ = Self {
            strings,
            cur: 0..0,
            boundaries: GraphemeBoundaryCursor::new(0, usize::MAX, true),
            broken: None,
        };
        self_.move_next();
        self_
    }
}

#[cfg(test)]
mod a_grapheme_cursor {
    use super::*;

    #[test]
    fn moves_forward_through_slice_of_strings() {
        let slice = vec!["a̐éö̲", "", "\r\n"];
        let strs = SliceCursor::from(slice.as_ref());
        let mut graphemes = GraphemeCursor::from(strs);
        assert_eq!(graphemes.current(), Some("a̐"));
        graphemes.move_next();
        assert_eq!(graphemes.current(), Some("é"));
        graphemes.move_next();
        assert_eq!(graphemes.current(), Some("ö̲"));
        // graphemes.move_next();
        //assert_eq!(graphemes.current(),Some("\r\n"));
        // graphemes.move_next();
        //assert_eq!(graphemes.current(),None);
    }
}
*/
