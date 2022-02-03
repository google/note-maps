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

use super::offsets::Grapheme;
use core::ops;
use core::ops::Range;
use std::iter;
use std::rc::Rc;

use crate::*;

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
                start -= piece_len;
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
            take -= first_piece.len();
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
