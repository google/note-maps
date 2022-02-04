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

use core::any::Any;
use core::ops;
use core::ops::Range;
use std::fmt;
use std::iter;
use std::rc::Rc;

use crate::offsets::*;
use crate::*;

/// [Text] is a "piece chain" or "piece table" which, together with [Piece] which can apply
/// arbitrary marks, can represent almost any rich-text document.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::Text;
/// use notemaps_text::Piece;
///
/// let text: Text = [Piece::from("Hello, world!"), Piece::from("\n")].into_iter().collect();
/// assert_eq!(text.to_string(), "Hello, world!\n");
/// ```
#[derive(Clone, Debug)]
pub struct Text {
    pieces: Vec<Piece>,
    len: Offsets,
}

pub type PieceLocus = (usize, Offsets);

impl Text {
    pub const fn new() -> Self {
        Self {
            pieces: Vec::new(),
            len: Offsets::new_zero(),
        }
    }

    pub fn graphemes(&self) -> impl Iterator<Item = &str> {
        use unicode_segmentation::UnicodeSegmentation;
        self.pieces().flat_map(|p| p.as_str().graphemes(true))
    }

    pub fn get_piece(&self, n: usize) -> Option<&Piece> {
        if n < self.pieces.len() {
            Some(&self.pieces[n])
        } else {
            None
        }
    }

    pub fn pieces(&self) -> Pieces {
        Pieces(self.pieces.iter())
    }

    pub fn pieces_mut(&mut self) -> PiecesMut {
        PiecesMut(self.pieces.iter_mut())
    }

    pub fn len_offsets(&self) -> Offsets {
        self.len
    }

    pub fn len(&self) -> Grapheme {
        *self.len.as_ref()
    }

    pub fn locate(&self, offset: Grapheme) -> Result<PieceLocus, PieceLocus> {
        if self.pieces.is_empty() {
            return if offset.0 == 0 {
                Ok((0, Offsets::new_zero()))
            } else {
                Err((0, Offsets::new_zero()))
            };
        }
        use std::cmp;
        match offset.cmp(&self.len.grapheme()) {
            cmp::Ordering::Greater => {
                return Err((
                    self.pieces.len() - 1,
                    self.pieces[self.pieces.len() - 1].len_offsets(),
                ));
            }
            cmp::Ordering::Equal => {
                return Ok((
                    self.pieces.len() - 1,
                    self.pieces[self.pieces.len() - 1].len_offsets(),
                ));
            }
            _ => {}
        }
        let mut todo = offset;
        for (i, p) in self.pieces.iter().enumerate() {
            if p.len() > todo {
                return Ok((
                    i,
                    p.locate(todo)
                        .expect("locating an offset less than the length always works"),
                ));
            } else {
                todo -= p.len();
            }
        }
        panic!("this should never happen...");
    }

    pub fn cursor(&self, offset: Grapheme) -> Point {
        Point::new(self, offset)
    }

    #[must_use]
    pub fn slice(&self, r: Range<Grapheme>) -> Self {
        if r.end <= r.start {
            return Text::new();
        }
        let start = self
            .locate(r.start)
            .expect("argument to slice is always valid");
        let end = self
            .locate(r.end)
            .expect("argument to slice is always valid");
        if start == end {
            return Text::new();
        }
        if start.0 == end.0 {
            return self.pieces[start.0].slice(start.1.to()..end.1.to()).into();
        }
        iter::once(self.pieces[start.0].slice(start.1.to()..self.pieces[start.0].len()))
            .chain(self.pieces[(start.0 + 1)..end.0].iter().cloned())
            .chain(iter::once(
                self.pieces[end.0].slice(Grapheme(0)..end.1.to()),
            ))
            .collect()
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

impl FromIterator<Piece> for Text {
    fn from_iter<T: IntoIterator<Item = Piece>>(iter: T) -> Self {
        let pieces: Vec<Piece> = iter.into_iter().map(Into::into).collect();
        let len: Offsets = pieces.iter().map(|p| p.len_offsets()).sum();
        Self { pieces, len }
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

impl fmt::Display for Text {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.pieces().try_for_each(|p| p.as_str().fmt(f))
    }
}

/// [Pieces] is the [Iterator] type returned by [Text::pieces].
pub struct Pieces<'a>(std::slice::Iter<'a, Piece>);

impl<'a> Iterator for Pieces<'a> {
    type Item = &'a Piece;

    fn next(&mut self) -> Option<Self::Item> {
        self.0.next()
    }

    fn advance_by(&mut self, n: usize) -> Result<(), usize> {
        self.0.advance_by(n)
    }

    fn fold<B, F>(self, init: B, f: F) -> B
    where
        Self: Sized,
        F: FnMut(B, Self::Item) -> B,
    {
        self.0.fold(init, f)
    }

    fn size_hint(&self) -> (usize, Option<usize>) {
        self.0.size_hint()
    }
}

impl<'a> ExactSizeIterator for Pieces<'a> {}

/// [PiecesMut] is the [Iterator] type returned by [Text::pieces_mut].
pub struct PiecesMut<'a>(std::slice::IterMut<'a, Piece>);

impl<'a> Iterator for PiecesMut<'a> {
    type Item = &'a mut Piece;

    fn next(&mut self) -> Option<Self::Item> {
        self.0.next()
    }

    fn advance_by(&mut self, n: usize) -> Result<(), usize> {
        self.0.advance_by(n)
    }

    fn fold<B, F>(self, init: B, f: F) -> B
    where
        Self: Sized,
        F: FnMut(B, Self::Item) -> B,
    {
        self.0.fold(init, f)
    }

    fn size_hint(&self) -> (usize, Option<usize>) {
        self.0.size_hint()
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
