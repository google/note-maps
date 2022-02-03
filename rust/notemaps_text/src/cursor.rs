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
use core::ops;
use core::ops::Range;
use std::rc::Rc;
//use core::ops::Deref;
use std::iter;

use crate::*;

/// [Piece] is a `str`-like type that also:
/// - is immutable,
/// - shares a backing buffer for cheap clones and slices,
/// - and measure offsets in user-perceived graphemes instead of bytes or chars.
///
/// [Piece] is intended to be used within a [Text].
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

    #[must_use]
    pub fn slice(&self, r: Range<Grapheme>) -> Self {
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
            len_graphemes: r.end - r.start,
            marks: self.marks.clone(),
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

    #[must_use]
    pub fn with_mark<M: Any>(mut self, m: Rc<M>) -> Self {
        self.marks.push(m);
        self
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

// An internal-only helper type for [Text].
#[derive(Clone, Debug)]
struct Table {
    pieces: Vec<Piece>,
    len_graphemes: Grapheme,
}

impl Table {
    pub fn len(&self) -> Grapheme {
        self.len_graphemes
    }
}

impl FromIterator<Piece> for Table {
    fn from_iter<T: IntoIterator<Item = Piece>>(iter: T) -> Self {
        let pieces: Vec<_> = iter.into_iter().collect();
        let len_graphemes = pieces.iter().map(|m| m.len()).sum();
        Self {
            pieces,
            len_graphemes,
        }
    }
}

enum TextInternal {
    Empty,
    Piece(Piece),
    Table(Table),
}

use std::any::Any;

/// [Text] is a "piece chain" or "piece table" using [Piece] to represent a
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
    pub fn new() -> Self {
        Self(TextInternal::Empty)
    }

    pub fn graphemes(&self) -> impl Iterator<Item = &str> {
        use unicode_segmentation::UnicodeSegmentation;
        self.pieces().flat_map(|p| p.as_str().graphemes(true))
    }

    pub fn pieces(&self) -> Pieces {
        Pieces(match &self.0 {
            TextInternal::Empty => PiecesInternal::Empty(iter::empty()),
            TextInternal::Piece(piece) => PiecesInternal::Piece(iter::once(piece)),
            TextInternal::Table(table) => PiecesInternal::Table(table.pieces.iter()),
        })
    }

    pub fn pieces_mut(&mut self) -> PiecesMut {
        PiecesMut(match &mut self.0 {
            TextInternal::Empty => PiecesMutInternal::Empty(iter::empty()),
            TextInternal::Piece(piece) => PiecesMutInternal::Piece(iter::once(piece)),
            TextInternal::Table(table) => PiecesMutInternal::Table(table.pieces.iter_mut()),
        })
    }

    pub fn len(&self) -> Grapheme {
        match &self.0 {
            TextInternal::Empty => Grapheme(0),
            TextInternal::Piece(piece) => piece.len(),
            TextInternal::Table(table) => table.len(),
        }
    }

    #[must_use]
    pub fn slice(&self, r: Range<Grapheme>) -> Self {
        if r.end <= r.start {
            return Text(TextInternal::Empty);
        }
        let mut start = r.start;
        let mut all_pieces = self.pieces();
        let mut first_piece = None;
        for piece in all_pieces.by_ref() {
            let piece_len = piece.len();
            if piece_len < start {
                start = start - piece_len;
            } else {
                first_piece = Some(piece.slice(start..piece_len));
                break;
            }
        }
        let first_piece = first_piece.expect("text slice range within bounds");
        let mut take = r.end - r.start;
        if first_piece.len() >= take {
            return Self(TextInternal::Piece(first_piece.slice(Grapheme(0)..take)));
        } else {
            take = take - first_piece.len();
        }
        let mut pieces = vec![first_piece];
        for piece in all_pieces {
            if piece.len() < take {
                pieces.push(piece.clone());
            } else {
                pieces.push(piece.slice(Grapheme(0)..take));
                return Self(TextInternal::Table(Table {
                    pieces,
                    len_graphemes: r.end - r.start,
                }));
            }
        }
        panic!("text slice r exceeds length of text");
    }

    #[must_use]
    pub fn with_insert<I: IntoIterator>(&self, _at: Grapheme, _text: I) -> Self
    where
        Text: FromIterator<I::Item>,
    {
        todo!("");
    }

    pub fn mark<M: Any>(&mut self, m: Rc<M>) {
        for piece in self.pieces_mut() {
            piece.marks_mut().push(m.clone());
        }
    }

    pub fn unmark<M: Any + PartialEq>(&mut self, m: &M) {
        for piece in self.pieces_mut() {
            if piece.marks_mut().contains(&*m) {
                piece.marks_mut().take_any::<M>();
            }
        }
    }
}

impl Default for Text {
    fn default() -> Self {
        Self::new()
    }
}

impl FromIterator<Text> for Text {
    fn from_iter<T: IntoIterator<Item = Text>>(iter: T) -> Self {
        iter.into_iter().fold(Text::new(), |acc, elem| acc + elem)
    }
}

impl FromIterator<Piece> for Text {
    fn from_iter<T: IntoIterator<Item = Piece>>(iter: T) -> Self {
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

impl<'a> FromIterator<&'a str> for Text {
    fn from_iter<T: IntoIterator<Item = &'a str>>(iter: T) -> Self {
        iter.into_iter().map(Piece::from).collect()
    }
}

impl From<Piece> for Text {
    fn from(piece: Piece) -> Self {
        iter::once(piece).collect()
    }
}

impl<'a> From<&'a str> for Text {
    fn from(string: &'a str) -> Self {
        Piece::from(string).into()
    }
}

// TODO: consider refactoring these implementations of ops::Add to more closely resemble what's
// done for std::string::String.

impl ops::Add<Self> for Text {
    type Output = Self;
    fn add(self, other: Self) -> Self {
        self.pieces().chain(other.pieces()).cloned().collect()
    }
}

impl ops::Add<Piece> for Text {
    type Output = Self;
    fn add(self, other: Piece) -> Self {
        self.pieces().cloned().chain(iter::once(other)).collect()
    }
}

impl ops::Add<Piece> for Piece {
    type Output = Text;
    fn add(self, other: Piece) -> Self::Output {
        Text::from_iter([self, other])
    }
}

impl ops::Add<Text> for Piece {
    type Output = Text;
    fn add(self, other: Text) -> Self::Output {
        Text::from_iter(iter::once(self).chain(other.pieces().cloned()))
    }
}

use std::fmt;
impl fmt::Display for Text {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.pieces().try_for_each(|p| p.as_str().fmt(f))
    }
}

// A helper type for [Pieces]
enum PiecesInternal<'a> {
    Empty(std::iter::Empty<&'a Piece>),
    Piece(std::iter::Once<&'a Piece>),
    Table(std::slice::Iter<'a, Piece>),
}

/// [Pieces] is the [Iterator] type returned by [Text::pieces].
pub struct Pieces<'a>(PiecesInternal<'a>);

impl<'a> Iterator for Pieces<'a> {
    type Item = &'a Piece;
    fn next(&mut self) -> Option<Self::Item> {
        use PiecesInternal::*;
        match &mut self.0 {
            Empty(iter) => iter.next(),
            Piece(iter) => iter.next(),
            Table(iter) => iter.next(),
        }
    }
}

// A helper type for [Pieces]
enum PiecesMutInternal<'a> {
    Empty(std::iter::Empty<&'a mut Piece>),
    Piece(std::iter::Once<&'a mut Piece>),
    Table(std::slice::IterMut<'a, Piece>),
}

/// [PiecesMut] is the [Iterator] type returned by [Text::pieces_mut].
pub struct PiecesMut<'a>(PiecesMutInternal<'a>);

impl<'a> Iterator for PiecesMut<'a> {
    type Item = &'a mut Piece;
    fn next(&mut self) -> Option<Self::Item> {
        use PiecesMutInternal::*;
        match &mut self.0 {
            Empty(iter) => iter.next(),
            Piece(iter) => iter.next(),
            Table(iter) => iter.next(),
        }
    }
}

#[cfg(test)]
mod a_text {
    use super::*;

    #[test]
    fn can_be_built_from_a_str() {
        let text: Text = "a̐éö̲\r\n".into();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
    }

    #[test]
    fn can_be_built_from_a_piece() {
        let text: Text = Piece::new(Rc::from("a̐éö̲\r\n")).into();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
    }

    #[test]
    fn can_be_collected_from_strs() {
        let text: Text = ["a̐éö̲", "\r\n"].into_iter().collect();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
        assert_eq!(text.len(), Grapheme(4));
        assert_eq!(
            text.pieces().map(|p| p.as_str()).collect::<Vec<&str>>(),
            vec!["a̐éö̲", "\r\n"]
        );
    }

    #[test]
    fn can_be_collected_from_pieces() {
        let text: Text = [Piece::from("a̐éö̲"), Piece::from("\r\n")]
            .into_iter()
            .collect();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
        assert_eq!(text.len(), Grapheme(4));
        assert_eq!(
            text.pieces().map(|p| p.as_str()).collect::<Vec<&str>>(),
            vec!["a̐éö̲", "\r\n"]
        );
    }

    #[test]
    fn can_be_collected_from_texts() {
        let text: Text = [Text::from("a̐éö̲"), Text::from("\r\n")]
            .into_iter()
            .collect();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
        assert_eq!(text.len(), Grapheme(4));
        assert_eq!(
            text.pieces().map(|p| p.as_str()).collect::<Vec<&str>>(),
            vec!["a̐éö̲", "\r\n"]
        );
    }

    #[test]
    fn can_be_built_from_concatenation() {
        assert_eq!(
            (Text::from("a̐éö̲") + Text::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
        assert_eq!(
            (Text::from("a̐éö̲") + Piece::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
        assert_eq!(
            (Piece::from("a̐éö̲") + Piece::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
        assert_eq!(
            (Piece::from("a̐éö̲") + Text::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
    }

    #[test]
    fn can_be_sliced() {
        let text = Text::from_iter([Piece::from("a̐éö̲"), Piece::from("\r\n")]);
        assert_eq!(text.slice(Grapheme(0)..Grapheme(0)).to_string(), "");
        assert_eq!(text.slice(Grapheme(0)..Grapheme(1)).to_string(), "a̐");
        assert_eq!(text.slice(Grapheme(0)..Grapheme(2)).to_string(), "a̐é");
        assert_eq!(text.slice(Grapheme(0)..Grapheme(3)).to_string(), "a̐éö̲");
        assert_eq!(text.slice(Grapheme(0)..Grapheme(4)).to_string(), "a̐éö̲\r\n");
        assert_eq!(text.slice(Grapheme(1)..Grapheme(4)).to_string(), "éö̲\r\n");
        assert_eq!(text.slice(Grapheme(2)..Grapheme(4)).to_string(), "ö̲\r\n");
        assert_eq!(text.slice(Grapheme(3)..Grapheme(4)).to_string(), "\r\n");
        assert_eq!(text.slice(Grapheme(4)..Grapheme(4)).to_string(), "");
    }

    #[test]
    fn can_be_marked_and_unmarked() {
        let mut text = Text::from_iter([Piece::from("a̐éö̲"), Piece::from("\r\n")]);
        text.mark(Rc::new("test mark"));
        assert!(text.pieces().all(|p| p.marks().contains(&"test mark")));
        text.unmark(&"test mark");
        assert!(text.pieces().all(|p| !p.marks().contains(&"test mark")));
    }

    #[test]
    fn foo() {
        struct Word {}
        let is_word = Rc::from(Word {});
        let text = Text::from_iter([
            Piece::from("Hello").with_mark(is_word.clone()),
            Piece::from(", "),
            Piece::from("world").with_mark(is_word.clone()),
            Piece::from("!"),
        ]);
        assert_eq!(
            text.pieces()
                .filter(|p| p.marks().contains_any::<Word>())
                .map(|p| p.as_str())
                .collect::<Vec<&str>>(),
            vec!["Hello", "world"]
        );
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
