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

use unicode_segmentation::UnicodeSegmentation;

use crate::offsets::*;
use crate::*;

pub enum Dir {
    Next,
    Prev,
}

/// A representation of a location within a [Text], intended to be close to the mental model of
/// location that a user might have while moving a cursor in a text editor.
///
/// Every [Cursor] represents a location within the [Text] it was created with, and the location is
/// always one of:
/// - the beginning of the text,
/// - the end of the text,
/// - between two graphemes within the text.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::{Cursor,Text};
///
/// let text: Text = "Hello, World!\r\n".into();
/// let cursor = Cursor::new(&text, 13.into());
/// assert_eq!(cursor.peek_prev(), Some("!"));
/// assert_eq!(cursor.peek_next(), Some("\r\n"));
/// ```
#[derive(Copy, Clone)]
pub struct Cursor<'a> {
    text: &'a Text,
    text_offsets: Locus,
    piece: usize,
    piece_offsets: Locus,
}

impl<'a> Cursor<'a> {
    pub fn new(text: &'a Text, offset: Grapheme) -> Self {
        Self {
            text,
            text_offsets: Locus::new_zero(),
            piece: 0,
            piece_offsets: Locus::new_zero(),
        }
        .with_offset(offset)
    }

    /// Consumes `self`, setting the offset of this [Cursor] to `offset`.
    #[must_use]
    pub fn with_offset(mut self, offset: Grapheme) -> Self {
        self.set_offset(offset).ok();
        self
    }

    pub fn set_offset(&mut self, offset: Grapheme) -> Result<(), Locus> {
        match self.text.locate(offset) {
            Ok((piece, offsets)) => {
                self.text_offsets = self
                    .text
                    .pieces()
                    .take(piece)
                    .map(Piece::len_offsets)
                    .sum::<Locus>()
                    + offsets;
                self.piece = piece;
                self.piece_offsets = offsets;
                Ok(())
            }
            Err((piece, offsets)) => {
                self.text_offsets = self.text.len_offsets();
                self.piece = piece;
                self.piece_offsets = offsets;
                Err(self.text_offsets)
            }
        }
    }

    pub fn offset(&self) -> Grapheme {
        *self.text_offsets.as_ref()
    }

    pub fn location(&self) -> (usize, Byte) {
        (self.piece, *self.piece_offsets.as_ref())
    }

    fn get_piece_offset_prev(&self) -> Option<(&'a Piece, Byte)> {
        if self.piece_offsets.byte() == Byte(0) {
            if self.piece == 0 {
                None
            } else {
                self.text
                    .get_piece(self.piece - 1)
                    .map(|p| (p, p.len_bytes()))
            }
        } else {
            self.text
                .get_piece(self.piece)
                .map(|p| (p, self.piece_offsets.byte()))
        }
    }

    fn get_piece_offset_next(&self) -> Option<(&'a Piece, Byte)> {
        self.text
            .get_piece(self.piece)
            .map(|p| (p, self.piece_offsets.byte()))
    }

    pub fn peek_marks(&self, d: Dir) -> Option<&MarkSet> {
        match d {
            Dir::Next => self.get_piece_offset_next().map(|(p, _)| p.marks()),
            Dir::Prev => self.get_piece_offset_prev().map(|(p, _)| p.marks()),
        }
    }

    pub fn is_piece_boundary(&self) -> bool {
        self.piece_offsets.byte() == Byte(0)
            || match self.text.get_piece(self.piece) {
                Some(piece) => piece.len_bytes() == self.piece_offsets.byte(),
                None => true,
            }
    }

    pub fn peek_next(&self) -> Option<&'a str> {
        self.get_piece_offset_next()
            .and_then(|(p, o)| (&p.as_str()[o.0..]).graphemes(true).next())
    }

    pub fn peek_prev(&self) -> Option<&'a str> {
        self.get_piece_offset_prev()
            .and_then(|(p, o)| (&p.as_str()[..o.0]).graphemes(true).next_back())
    }

    /// Returns the total length of the underlying text in `O` elements.
    pub fn len<O>(&self) -> O
    where
        O: offsets::Offset,
        Locus: AsRef<O>,
    {
        *self.text_offsets.as_ref()
    }

    /// Returns the cursor position index in `O` elements.
    pub fn index<O>(&self) -> O
    where
        O: offsets::Offset,
        Locus: AsRef<O>,
    {
        *self.text_offsets.as_ref()
    }

    /// Moves the cursor forward by `n` elements.
    pub fn move_by(&mut self, n: Grapheme) -> Result<Locus, Locus> {
        let from = self.text_offsets;
        self.set_offset(
            if self.index::<Grapheme>() + n >= *self.text.len_offsets().as_ref() {
                *self.text.len_offsets().as_ref()
            } else {
                self.text_offsets.grapheme() + n
            },
        )
        .map(|_| self.text_offsets - from)
        .map_err(|_| self.text_offsets - from)
    }

    /// Moves the cursor in reverse by `n` elements.
    pub fn move_back_by(&mut self, n: Grapheme) -> Result<Locus, Locus> {
        let from = self.text_offsets;
        self.set_offset(if self.text_offsets.byte().0 <= n.0 {
            Grapheme(0)
        } else {
            self.text_offsets.grapheme() - n
        })
        .map(|_| from - self.text_offsets)
        .map_err(|_| from - self.text_offsets)
    }
}

#[cfg(test)]
mod a_point {
    use crate::offsets::Grapheme;
    use crate::*;
    use std::rc::Rc;

    #[derive(Default, Eq, PartialEq, Hash)]
    struct Word {}

    #[test]
    fn starts_at_the_beginning() {
        let word: Rc<Word> = Rc::default();
        let text = Text::from(Piece::from("AB").with_mark(word.clone()));
        let cursor = Cursor::new(&text, Grapheme(0));
        assert_eq!(cursor.offset(), Grapheme(0));
        assert!(cursor.is_piece_boundary());
        assert_eq!(cursor.peek_next(), Some("A"));
        assert!(cursor.peek_marks(Dir::Next).unwrap().contains(&*word));
        assert_eq!(cursor.peek_prev(), None);
        assert!(cursor.peek_marks(Dir::Prev).is_none());
    }

    #[test]
    fn can_move_to_next_point() {
        let word: Rc<Word> = Rc::default();
        let text = Text::from(Piece::from("ABC").with_mark(word.clone()));
        let mut cursor = Cursor::new(&text, Grapheme(0));
        cursor
            .move_by(Grapheme(1))
            .expect("not moving past the end of the string");
        assert_eq!(cursor.offset(), Grapheme(1));
        assert!(!cursor.is_piece_boundary());
        assert_eq!(cursor.peek_next(), Some("B"));
        assert!(cursor.peek_marks(Dir::Next).unwrap().contains(&*word));
        assert_eq!(cursor.peek_prev(), Some("A"));
        assert!(cursor.peek_marks(Dir::Prev).unwrap().contains(&*word));
        cursor
            .move_by(Grapheme(1))
            .expect("not moving past the end of the string");
        assert_eq!(cursor.offset(), Grapheme(2));
        assert!(!cursor.is_piece_boundary());
        assert_eq!(cursor.peek_next(), Some("C"));
        assert!(cursor.peek_marks(Dir::Next).unwrap().contains(&*word));
        assert_eq!(cursor.peek_prev(), Some("B"));
        assert!(cursor.peek_marks(Dir::Prev).unwrap().contains(&*word));
        cursor
            .move_by(Grapheme(1))
            .expect("not moving past the end of the string");
        assert_eq!(cursor.offset(), Grapheme(3));
        assert!(cursor.is_piece_boundary());
        assert_eq!(cursor.peek_next(), None);
        assert_eq!(cursor.peek_prev(), Some("C"));
        assert!(cursor.peek_marks(Dir::Prev).unwrap().contains(&*word));
    }

    #[test]
    fn can_be_moved_to_random_location() {
        let word: Rc<Word> = Rc::default();
        let text = Text::from_iter([
            Piece::from("a̐éö̲").with_mark(word.clone()),
            Piece::from("\r\n"),
        ]);
        let cursor = Cursor::new(&text, Grapheme(0));
        assert_eq!(cursor.peek_prev(), None);
        assert_eq!(cursor.peek_next(), Some("a̐"));
        let cursor = Cursor::new(&text, Grapheme(1));
        assert_eq!(cursor.peek_prev(), Some("a̐"));
        assert_eq!(cursor.peek_next(), Some("é"));
        let cursor = Cursor::new(&text, Grapheme(2));
        assert_eq!(cursor.peek_prev(), Some("é"));
        assert_eq!(cursor.peek_next(), Some("ö̲"));
        let cursor = Cursor::new(&text, Grapheme(3));
        assert_eq!(cursor.peek_prev(), Some("ö̲"));
        assert_eq!(cursor.peek_next(), Some("\r\n"));
        let cursor = Cursor::new(&text, Grapheme(4));
        assert_eq!(cursor.peek_prev(), Some("\r\n"));
        assert_eq!(cursor.peek_next(), None);
    }
}

/*
pub struct TextCursor<'a> {
    text: &'a Text,
    text_offset: Grapheme,
    piece: usize,
    piece_offset: Byte,
}

impl TextCursor<'a> {
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
