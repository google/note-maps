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

use std::borrow::Borrow;
use unicode_segmentation::UnicodeSegmentation;

use crate::offsets::*;
use crate::*;

pub enum Dir {
    Next,
    Prev,
}

/// A representation of a location within a [Table], intended to be close to the mental model of
/// location that a user might have while moving a cursor in a text editor.
///
/// Every [Cursor] represents a location within the [Table] it was created with, and the location is
/// always one of:
/// - the beginning of the text,
/// - the end of the text,
/// - between two graphemes within the text.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::{Cursor,Table};
///
/// let text: Table = "Hello, World!\r\n".into();
/// let cursor = Cursor::new(&text, 13.into());
/// assert_eq!(cursor.peek_prev(), Some("!"));
/// assert_eq!(cursor.peek_next(), Some("\r\n"));
/// ```
#[derive(Copy, Clone)]
pub struct Cursor<'a, S> {
    text: &'a Table<S>,
    text_offsets: Locus,
    piece: Piece,
    piece_offsets: Locus,
}

impl<'a, S> Cursor<'a, S>
where
    S: Borrow<str> + Clone + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
{
    pub fn new(text: &'a Table<S>, offset: Grapheme) -> Self {
        Self {
            text,
            text_offsets: Locus::zero(),
            piece: Piece(0),
            piece_offsets: Locus::zero(),
        }
        .with_offset(offset)
    }

    /// Consumes `self`, setting the offset of this [Cursor] to `offset`.
    #[must_use]
    pub fn with_offset(mut self, offset: Grapheme) -> Self {
        self.set_offset(offset).ok();
        self
    }

    pub fn set_offset(&mut self, offset: Grapheme) -> Result<(), Grapheme> {
        match self.text.locate(offset) {
            Ok((piece, offsets)) => {
                self.piece = piece;
                self.piece_offsets = if offsets.0 == 0 {
                    Locus::zero()
                } else {
                    Locus::from((
                        self.text
                            .get_piece(piece)
                            .expect("piece identified by Table::locate should be valid"),
                        offsets,
                    ))
                };
                self.text_offsets = self
                    .text
                    .pieces()
                    .take(piece.0)
                    .map(|p| Locus::from_len(p.as_ref()))
                    .sum::<Locus>()
                    + self.piece_offsets;
                Ok(())
            }
            Err((piece, offsets)) => {
                self.text_offsets = Locus::from_len(self.text);
                self.piece = piece;
                self.piece_offsets = if offsets.0 == 0 {
                    Locus::zero()
                } else {
                    Locus::from((
                        self.text
                            .get_piece(piece)
                            .expect("piece identified by Table::locate should be valid"),
                        offsets,
                    ))
                };
                Err(*self.text_offsets.as_ref())
            }
        }
    }

    pub fn offset(&self) -> Grapheme {
        *self.text_offsets.as_ref()
    }

    pub fn location(&self) -> (Piece, Byte) {
        (self.piece, *self.piece_offsets.as_ref())
    }

    fn get_piece_offset_prev(&self) -> Option<(&'a Marked<S>, Byte)>
    where
        S: Slice<Byte>,
    {
        if self.piece_offsets.byte() == Byte(0) {
            if self.piece.0 == 0 {
                None
            } else {
                self.text
                    .get_piece(self.piece - 1)
                    .map(|p| (p, p.as_ref().len()))
            }
        } else {
            self.text
                .get_piece(self.piece)
                .map(|p| (p, self.piece_offsets.byte()))
        }
    }

    fn get_piece_offset_next(&self) -> Option<(&'a Marked<S>, Byte)> {
        self.text.get_piece(self.piece).and_then(|p| {
            if self.piece_offsets.byte() < p.len() || self.piece.0 == self.text.pieces().len() {
                Some((p, self.piece_offsets.byte()))
            } else {
                self.text.get_piece(self.piece + 1).map(|p| (p, Byte(0)))
            }
        })
    }

    pub fn peek_marks(&self, d: Dir) -> Option<&MarkSet>
    where
        S: Slice<Byte>,
    {
        match d {
            Dir::Next => self.get_piece_offset_next().map(|(p, _)| p.marks()),
            Dir::Prev => self.get_piece_offset_prev().map(|(p, _)| p.marks()),
        }
    }

    pub fn is_piece_boundary(&self) -> bool {
        self.piece_offsets.byte() == Byte(0)
            || match self.text.get_piece(self.piece) {
                Some(piece) => self.piece_offsets.byte() == piece.as_ref().len(),
                None => true,
            }
    }

    pub fn peek_next(&self) -> Option<&'a str> {
        self.get_piece_offset_next()
            .and_then(|(p, o)| (&p.as_str()[o.0..]).graphemes(true).next())
    }

    pub fn peek_prev(&self) -> Option<&'a str>
    where
        S: Slice<Byte>,
    {
        self.get_piece_offset_prev()
            .and_then(|(p, o)| (&p.as_str()[..o.0]).graphemes(true).next_back())
    }

    /// Returns the total length of the underlying text in `U` elements.
    pub fn len<U>(&self) -> U
    where
        U: Clone,
        Locus: AsRef<U>,
    {
        self.text_offsets.as_ref().clone()
    }

    /// Returns the cursor position index in `U` elements.
    pub fn index<U>(&self) -> U
    where
        U: offsets::Unit,
        Locus: AsRef<U>,
    {
        *self.text_offsets.as_ref()
    }

    /// Moves the cursor forward by `n` elements.
    pub fn move_by(&mut self, n: Grapheme) -> Result<Locus, Locus> {
        let from = self.text_offsets;
        self.set_offset(if self.index::<Grapheme>() + n >= self.text.len() {
            self.text.len()
        } else {
            self.text_offsets.grapheme() + n
        })
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
        let text = Table::from(Marked::<Measured>::from("AB").with_mark(word.clone()));
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
        let text = Table::<Measured>::from(Marked::from("ABC").with_mark(word.clone()));
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
    fn can_be_moved_to_arbitrary_location() {
        let word: Rc<Word> = Rc::default();
        let text = Table::<Measured>::from_iter([
            Marked::from("a̐éö̲").with_mark(word.clone()),
            Marked::from("\r\n"),
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
