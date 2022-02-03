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

use crate::offsets::Byte;
use crate::offsets::Grapheme;
use crate::*;

pub enum Dir {
    Next,
    Prev,
}

/// Describes a location in a [Text].
///
/// Every [Point] describes a location in a [Text] that is either:
/// - at the beginning of the text,
/// - at the end of the text,
/// - or between two graphemes within the text.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::Point;
/// use notemaps_text::Text;
///
/// let text: Text = "Hello, world!".into();
/// let point = Point::new(&text);
/// assert_eq!(point.offset().0, 0);
/// ```
#[derive(Copy, Clone)]
pub struct Point<'a> {
    text: &'a Text,
    text_offset: Grapheme,
    piece: usize,
    piece_offset: Byte,
}

impl<'a> Point<'a> {
    pub fn new(text: &'a Text) -> Self {
        Self {
            text,
            text_offset: Grapheme(0),
            piece: 0,
            piece_offset: Byte(0),
        }
    }

    pub fn move_next(&mut self) {
        match self.text.get_piece(self.piece) {
            None => {
                self.text_offset = Grapheme(0);
                self.piece = 0;
                self.piece_offset = Byte(0);
            }
            Some(piece) => {
                self.text_offset += 1;
                match (&piece.as_str()[self.piece_offset.0..])
                    .grapheme_indices(true)
                    .nth(1)
                    .map(|(o, _)| Byte(o))
                {
                    Some(grapheme_width) => {
                        self.piece_offset += grapheme_width;
                    }
                    None => {
                        self.piece += 1;
                        self.piece_offset = Byte(0);
                    }
                }
            }
        }
    }

    pub fn offset(&self) -> Grapheme {
        self.text_offset
    }

    fn get_piece_offset_prev(&self) -> Option<(&Piece, Byte)> {
        if self.piece_offset == Byte(0) {
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
                .map(|p| (p, self.piece_offset))
        }
    }

    fn get_piece_offset_next(&self) -> Option<(&Piece, Byte)> {
        self.text
            .get_piece(self.piece)
            .map(|p| (p, self.piece_offset))
    }

    pub fn peek_grapheme(&self, d: Dir) -> Option<&str> {
        match d {
            Dir::Next => self
                .get_piece_offset_next()
                .and_then(|(p, o)| (&p.as_str()[o.0..]).graphemes(true).next()),
            Dir::Prev => self
                .get_piece_offset_prev()
                .and_then(|(p, o)| (&p.as_str()[..o.0]).graphemes(true).next_back()),
        }
    }

    pub fn peek_marks(&self, d: Dir) -> Option<&MarkSet> {
        match d {
            Dir::Next => self.get_piece_offset_next().map(|(p, _)| p.marks()),
            Dir::Prev => self.get_piece_offset_prev().map(|(p, _)| p.marks()),
        }
    }

    pub fn is_piece_boundary(&self) -> bool {
        self.piece_offset.0 == 0
            || match self.text.get_piece(self.piece) {
                Some(piece) => piece.len_bytes() == self.piece_offset,
                None => true,
            }
    }
}

#[cfg(test)]
mod a_point {
    use crate::*;
    use std::rc::Rc;

    #[derive(Default, Eq, PartialEq, Hash)]
    struct Word {}

    #[test]
    fn starts_at_the_beginning() {
        let word: Rc<Word> = Rc::default();
        let text = Text::from(Piece::from("AB").with_mark(word.clone()));
        let point = Point::new(&text);
        assert_eq!(point.offset(), offsets::Grapheme(0));
        assert!(point.is_piece_boundary());
        assert_eq!(point.peek_grapheme(Dir::Next), Some("A"));
        assert!(point.peek_marks(Dir::Next).unwrap().contains(&*word));
        assert_eq!(point.peek_grapheme(Dir::Prev), None);
        assert!(point.peek_marks(Dir::Prev).is_none());
    }

    #[test]
    fn can_move_to_next_point() {
        let word: Rc<Word> = Rc::default();
        let text = Text::from(Piece::from("ABC").with_mark(word.clone()));
        let mut point = Point::new(&text);
        point.move_next();
        assert_eq!(point.offset(), offsets::Grapheme(1));
        assert!(!point.is_piece_boundary());
        assert_eq!(point.peek_grapheme(Dir::Next), Some("B"));
        assert!(point.peek_marks(Dir::Next).unwrap().contains(&*word));
        assert_eq!(point.peek_grapheme(Dir::Prev), Some("A"));
        assert!(point.peek_marks(Dir::Prev).unwrap().contains(&*word));
        point.move_next();
        assert_eq!(point.offset(), offsets::Grapheme(2));
        assert!(!point.is_piece_boundary());
        assert_eq!(point.peek_grapheme(Dir::Next), Some("C"));
        assert!(point.peek_marks(Dir::Next).unwrap().contains(&*word));
        assert_eq!(point.peek_grapheme(Dir::Prev), Some("B"));
        assert!(point.peek_marks(Dir::Prev).unwrap().contains(&*word));
        point.move_next();
        assert_eq!(point.offset(), offsets::Grapheme(3));
        assert!(point.is_piece_boundary());
        assert_eq!(point.peek_grapheme(Dir::Next), None);
        assert!(point.peek_marks(Dir::Next).is_none());
        assert_eq!(point.peek_grapheme(Dir::Prev), Some("C"));
        assert!(point.peek_marks(Dir::Prev).unwrap().contains(&*word));
        // An experimental API for a LinkedList cursor currently rolling out in the Rust standard
        // library implements circular navigation. As this is also a cursor, users may expect the
        // same semantics here.
        point.move_next();
        assert_eq!(point.offset(), offsets::Grapheme(0));
        assert!(point.is_piece_boundary());
        assert_eq!(point.peek_grapheme(Dir::Next), Some("A"));
        assert!(point.peek_marks(Dir::Next).unwrap().contains(&*word));
        assert_eq!(point.peek_grapheme(Dir::Prev), None);
        assert!(point.peek_marks(Dir::Prev).is_none());
    }

    #[test]
    fn can_be_moved_to_random_location() {
        let word: Rc<Word> = Rc::default();

        let text = Text::from_iter([
            Piece::from("Testing").with_mark(word.clone()),
            Piece::from(", "),
            Piece::from("testing").with_mark(word.clone()),
            Piece::from("..."),
            Piece::from("\n"),
        ]);
        let point = Point::new(&text);

        assert_eq!(point.offset(), offsets::Grapheme(0));
        assert!(point.is_piece_boundary());

        assert_eq!(point.peek_grapheme(Dir::Next), Some("T"));
        assert!(point.peek_marks(Dir::Next).unwrap().contains(&*word));

        assert_eq!(point.peek_grapheme(Dir::Prev), None);
        assert!(point.peek_marks(Dir::Prev).is_none());
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
