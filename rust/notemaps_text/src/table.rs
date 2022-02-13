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
use core::marker::PhantomData;
use core::ops;
use core::ops::Range;
use std::borrow::Borrow;
use std::fmt;
use std::iter;
use std::rc::Rc;

use crate::offsets::*;
use crate::*;

/// [Table] is a sequence of [Marked] values, effectively a [piece table][].
///
/// Although currently based on a [Vec], future iterations of development may replace the internal
/// implementation with something like a [rope][] or [gap buffer][]. The API of [Table] is
/// deliberately agnostic to these implementation details, committing only to presenting the data
/// as no more than a sequence of [Marked] values that may or may not be usefully optimized for
/// interesting uses.
///
/// [piece table]: https://en.wikipedia.org/wiki/Marked_table
/// [rope]: https://en.wikipedia.org/wiki/Rope_(computer_science)
/// [gap buffer]: https://en.wikipedia.org/wiki/Gap_buffer
///
/// # Examples
///
/// ```rust
/// use notemaps_text::Table;
/// use notemaps_text::Marked;
///
/// let text: Table = [Marked::from("Hello, world!"), Marked::from("\n")].into_iter().collect();
/// assert_eq!(text.to_string(), "Hello, world!\n");
/// ```
#[derive(Clone, Debug)]
pub struct Table<S = Measured> {
    pieces: Vec<Marked<S>>,
    len: Locus,
}

pub use offsets::Piece;

/// [PieceOffset] is just a tuple of a [Piece] with some [Unit] type `U`. It may be replaced with
/// something else soon.
pub type PieceOffset<U> = (Piece, U);

impl<S> Table<S>
where
    S: Borrow<str>,
{
    /// Creates a new, empty [Table].
    pub fn new() -> Self {
        Self {
            pieces: Vec::new(),
            len: Locus::zero(),
        }
    }

    /// Returns an iterator over all the individual graphemes in `self`.
    pub fn graphemes(&self) -> impl '_ + Iterator<Item = Marked<S>>
    where
        S: Clone + Slice<Byte> + Slice<Grapheme>,
    {
        self.pieces().flat_map(|p| p.graphemes())
    }

    /// Returns the `n`th piece, or [None] if `n` is greater than the number of pieces in `self`.
    ///
    /// NOTE: This is a low-level API that risks coupling the usage of [Table] to implementation
    /// details.
    pub fn get_piece(&self, n: Piece) -> Option<&Marked<S>> {
        if n.0 < self.pieces.len() {
            Some(&self.pieces[n.0])
        } else {
            None
        }
    }

    /// Returns a reference to each [Marked] in `self`, which is the entire content or meaning of
    /// this [Table].
    ///
    /// NOTE: This is a low-level API that risks coupling the usage of [Table] to implementation
    /// details.
    pub fn pieces(&self) -> Pieces<S> {
        Pieces(self.pieces.iter())
    }

    /// Returns a mutable reference to each [Marked] in `self`, which is the entire content or
    /// meaning of this [Table].
    pub fn pieces_mut(&mut self) -> PiecesMut<S> {
        PiecesMut(self.pieces.iter_mut())
    }

    /// Returns a reference to each [Marked] in `self`, which is the entire content or meaning of
    /// this [Table].
    ///
    /// NOTE: This is a low-level API that risks coupling the usage of [Table] to implementation
    /// details.
    pub fn piece_indices<U: Unit>(&self) -> PieceIndices<U, S>
    where
        S: Slice<U>,
    {
        PieceIndices(0.into(), self.pieces.iter())
    }

    /// Returns a specialized representation of the location of `offset` within `self`.
    pub fn locate<U: Unit>(&self, offset: U) -> Result<PieceOffset<Byte>, PieceOffset<U>>
    where
        S: Clone + Slice<Byte> + Slice<Char> + Slice<Grapheme> + Slice<U>,
    {
        self.piece_indices()
            .enumerate()
            .find_map(|(n, (start, piece)): (usize, (U, &marked::Marked<S>))| {
                let piece_len: U = piece.len();
                let max: U = start + piece_len;
                if offset <= max {
                    Some((
                        Piece(n),
                        piece
                            .locate::<Byte, Byte>(offset - start)
                            .expect("arithmetic should work"),
                    ))
                } else {
                    None
                }
            })
            .ok_or_else(|| {
                (
                    Piece(self.pieces.len() - 1),
                    self.pieces[self.pieces.len() - 1].len(),
                )
            })
    }

    /// Returns a [Cursor] positioned at `offset` within `self`.
    pub fn cursor(&self, offset: Grapheme) -> Cursor<S>
    where
        S: Clone + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    {
        Cursor::new(self, offset)
    }

    #[must_use]
    pub fn with_replace<I: IntoIterator>(&self, r: Range<Grapheme>, text: I) -> Self
    where
        Table<S>: FromIterator<I::Item>,
        S: Clone + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    {
        self.slice(Grapheme::MIN..r.start) + Self::from_iter(text) + self.slice(r.end..self.len())
    }

    #[must_use]
    pub fn with_insert<I: IntoIterator>(&self, n: Grapheme, text: I) -> Self
    where
        Table<S>: FromIterator<I::Item>,
        S: Clone + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    {
        self.with_replace(n..n, text)
    }

    /// Pushes the mark `m` onto every [Marked] in `self`.
    pub fn mark<M: Any>(&mut self, m: Rc<M>) {
        for piece in self.pieces_mut() {
            piece.marks_mut().push(m.clone());
        }
    }

    /// Removes the mark `m` from every [Marked] in `self`.
    pub fn unmark<M: Any + PartialEq>(&mut self, m: &M) {
        for piece in self.pieces_mut() {
            if piece.marks_mut().contains(&*m) {
                piece.marks_mut().take_any::<M>();
            }
        }
    }

    /// Consumes `self`, pushes the mark `m` onto every [Marked], and returns the result.
    #[must_use]
    pub fn map_marks<F: for<'a> FnMut(&'a mut MarkSet)>(
        self,
        r: Range<Grapheme>,
        mut marker: F,
    ) -> Self
    where
        S: Clone + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    {
        let replacement = self
            .slice(r.start..r.end)
            .into_iter()
            .map(|p| p.map_marks(|ms| marker(ms)));
        self.with_replace(r, replacement)
    }

    /// Consumes `self`, pushes the mark `m` onto every [Marked], and returns the result.
    #[must_use]
    pub fn with_mark<M: Into<MarkSet>>(self, r: Range<Grapheme>, m: M) -> Self
    where
        S: Clone + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    {
        let ms: MarkSet = m.into();
        let mut marked = self.slice(r.clone());
        for p in marked.pieces_mut() {
            p.marks_mut().push_all(&ms)
        }
        self.with_replace(r, marked)
    }

    /// Consumes `self`, removes the mark `m` from every [Marked], and returns the result.
    #[must_use]
    pub fn with_unmark<M: Any + PartialEq>(self, r: Range<Grapheme>, m: &M) -> Self
    where
        S: Clone + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    {
        let mut unmarked = self.slice(r.clone());
        unmarked.unmark(m);
        self.with_replace(r, unmarked)
    }
}

impl<S: Borrow<str>> Default for Table<S> {
    fn default() -> Self {
        Self::new()
    }
}

impl<S> FromIterator<Marked<S>> for Table<S>
where
    S: Borrow<str> + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
{
    fn from_iter<T: IntoIterator<Item = Marked<S>>>(iter: T) -> Self {
        let pieces: Vec<Marked<S>> = iter
            .into_iter()
            .filter(|p| !p.as_str().is_empty())
            .collect();
        let len: Locus = pieces.iter().map(|p| Locus::from_len(p.as_ref())).sum();
        Self { pieces, len }
    }
}

impl<S> From<Marked<S>> for Table<S>
where
    S: Borrow<str> + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
{
    fn from(piece: Marked<S>) -> Self {
        iter::once(piece).collect()
    }
}

impl<'a, S: Borrow<str>> From<&'a str> for Table<S>
where
    S: From<&'a str> + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
{
    fn from(string: &'a str) -> Self {
        Marked::from(string).into()
    }
}

impl<S> ops::Add<Self> for Table<S>
where
    S: Borrow<str> + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
{
    type Output = Self;

    fn add(self, other: Self) -> Self {
        self.into_iter().chain(other.into_iter()).collect()
    }
}

impl<S> ops::Add<Marked<S>> for Table<S>
where
    S: Borrow<str> + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
{
    type Output = Self;

    fn add(self, other: Marked<S>) -> Self {
        self.into_iter().chain(iter::once(other)).collect()
    }
}

impl<S: Borrow<str>> IntoIterator for Table<S> {
    type Item = Marked<S>;
    type IntoIter = std::vec::IntoIter<Self::Item>;
    fn into_iter(self) -> Self::IntoIter {
        self.pieces.into_iter()
    }
}

impl<S: Borrow<str>> fmt::Display for Table<S> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.pieces().try_for_each(|p| p.as_str().fmt(f))
    }
}

impl<S, U: Unit> Slice<U> for Table<S>
where
    S: Clone + Borrow<str> + Slice<U> + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    for<'a> Locus: AsRef<U> + From<(&'a S, U)>,
{
    fn len(&self) -> U {
        self.len.as_ref().clone()
    }

    fn slice(&self, r: core::ops::Range<U>) -> Self {
        assert!(r.end >= r.start);
        let piece_start = self
            .locate(r.start)
            .expect("argument to slice is always valid");
        let piece_end = self
            .locate(r.end)
            .expect(format!("argument to slice is always valid: {:?}", r.end).as_str());
        if piece_start.0 == piece_end.0 {
            return self.pieces[piece_start.0 .0]
                .slice(piece_start.1..piece_end.1)
                .into();
        }
        iter::once(
            self.pieces[piece_start.0 .0]
                .slice(piece_start.1..self.pieces[piece_start.0 .0].as_ref().len()),
        )
        .chain(
            self.pieces[(piece_start.0 + 1).0..piece_end.0 .0]
                .iter()
                .cloned(),
        )
        .chain(iter::once(
            self.pieces[piece_end.0 .0].slice(Byte(0)..piece_end.1),
        ))
        .collect()
    }
}

/// [Pieces] is the [Iterator] type returned by [Table::pieces].
pub struct Pieces<'a, S: Borrow<str>>(std::slice::Iter<'a, Marked<S>>);

impl<'a, S: Borrow<str>> Iterator for Pieces<'a, S> {
    type Item = &'a Marked<S>;

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

impl<'a, S: Borrow<str>> ExactSizeIterator for Pieces<'a, S> {}

/// [PiecesMut] is the [Iterator] type returned by [Table::pieces_mut].
pub struct PiecesMut<'a, S: Borrow<str>>(std::slice::IterMut<'a, Marked<S>>);

impl<'a, S: Borrow<str>> Iterator for PiecesMut<'a, S> {
    type Item = &'a mut Marked<S>;

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

impl<'a, S: Borrow<str>> ExactSizeIterator for PiecesMut<'a, S> {}

/// [PieceIndices] is the [Iterator] type returned by [Table::pieces].
pub struct PieceIndices<'a, U: Unit, S: Borrow<str> + Slice<U>>(U, std::slice::Iter<'a, Marked<S>>);

impl<'a, U, S> Iterator for PieceIndices<'a, U, S>
where
    U: Unit,
    S: Borrow<str> + Slice<U>,
{
    type Item = (U, &'a Marked<S>);

    fn next(&mut self) -> Option<Self::Item> {
        self.1.next().map(|piece| {
            let index = self.0;
            self.0 += piece.len();
            (index, piece)
        })
    }

    fn advance_by(&mut self, n: usize) -> Result<(), usize> {
        self.1.advance_by(n)
    }

    fn size_hint(&self) -> (usize, Option<usize>) {
        self.1.size_hint()
    }
}

impl<'a, U, S> ExactSizeIterator for PieceIndices<'a, U, S>
where
    U: Unit,
    S: Borrow<str> + Slice<U>,
{
}

/// [SegmentBy] is the type of [Iterator] returned by [Table::segment_by].
pub struct SegmentBy<'a, S, M>(iter::Peekable<Pieces<'a, S>>, PhantomData<M>)
where
    S: Borrow<str> + Clone,
    M: Any + PartialEq;

impl<'a, S, M> Iterator for SegmentBy<'a, S, M>
where
    S: Borrow<str> + Clone + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    M: Any + PartialEq,
{
    type Item = (Locus, Option<&'a M>, Table<S>);

    fn next(&mut self) -> Option<Self::Item> {
        match self.0.next() {
            None => None,
            Some(piece) => {
                let mark = piece.marks().get::<M>();
                let mut table = vec![piece.clone()];
                while let Some(next) = self.0.peek() {
                    if mark != next.marks().get() {
                        break;
                    }
                    table.push((*next).clone());
                }
                Some((Locus::zero(), mark, table.into_iter().collect()))
            }
        }
    }
}

#[cfg(test)]
mod a_text {
    use super::*;

    #[test]
    fn can_be_built_from_a_str() {
        let text: Table = "a̐éö̲\r\n".into();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
    }

    #[test]
    fn can_be_built_from_a_piece() {
        let text: Table = Marked::new(MarkSet::new(), "a̐éö̲\r\n".into()).into();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
    }

    #[test]
    fn can_be_collected_from_pieces() {
        let text: Table = [Marked::from("a̐éö̲"), Marked::from("\r\n")]
            .into_iter()
            .collect();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
        assert_eq!(Grapheme(4), text.len());
        assert_eq!(
            text.pieces().map(|p| p.as_str()).collect::<Vec<&str>>(),
            vec!["a̐éö̲", "\r\n"]
        );
    }

    #[test]
    fn can_be_built_from_concatenation() {
        let piece: Marked = "a̐éö̲".into();
        assert_eq!(
            (Table::from(piece.clone()) + Table::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
        assert_eq!(
            (Table::from(piece.clone()) + Marked::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
        assert_eq!(
            (piece.clone() + Marked::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
        assert_eq!((piece.clone() + Table::from("\r\n")).to_string(), "a̐éö̲\r\n");
    }

    #[test]
    fn can_be_sliced() {
        let text = Table::<Measured>::from_iter([Marked::from("a̐éö̲"), Marked::from("\r\n")]);
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
        let mut text = Table::from_iter([Marked::from("a̐éö̲"), Marked::from("\r\n")]);
        text.mark(Rc::new("test mark"));
        assert!(text
            .pieces()
            .all(|p: &Marked| p.marks().contains(&"test mark")));
        text.unmark(&"test mark");
        assert!(text.pieces().all(|p| !p.marks().contains(&"test mark")));
    }

    #[test]
    fn creates_new_text_with_insertion() {
        let text = Table::<Measured>::from("Hello!");
        let text = text.with_insert(Grapheme(5), [Marked::from(", world")]);
        assert_eq!(text.slice(Grapheme(0)..Grapheme(1)).to_string(), "H");
        assert_eq!(text.slice(Grapheme(1)..Grapheme(2)).to_string(), "e");
        assert_eq!(text.slice(Grapheme(2)..Grapheme(3)).to_string(), "l");
        assert_eq!(text.slice(Grapheme(3)..Grapheme(4)).to_string(), "l");
        assert_eq!(text.slice(Grapheme(4)..Grapheme(5)).to_string(), "o");
        assert_eq!(text.slice(Grapheme(5)..Grapheme(6)).to_string(), ",");
        assert_eq!(text.slice(Grapheme(6)..Grapheme(7)).to_string(), " ");
        assert_eq!(text.slice(Grapheme(7)..Grapheme(8)).to_string(), "w");
        assert_eq!(text.slice(Grapheme(8)..Grapheme(9)).to_string(), "o");
        assert_eq!(text.slice(Grapheme(9)..Grapheme(10)).to_string(), "r");
        assert_eq!(text.slice(Grapheme(10)..Grapheme(11)).to_string(), "l");
        assert_eq!(text.slice(Grapheme(11)..Grapheme(12)).to_string(), "d");
        assert_eq!(text.slice(Grapheme(12)..Grapheme(13)).to_string(), "!");
    }

    #[test]
    fn can_mark_a_slice() {
        let text = Table::from("Hello, world!");
        assert_eq!(text.get_piece(Piece(0)).unwrap().as_str(), "Hello, world!");
        assert!(text.get_piece(Piece(1)).is_none());
        #[derive(Clone, Debug, PartialEq, Hash)]
        struct Word {}
        let is_word = Rc::from(Word {});
        let text = text
            .map_marks(Grapheme(0)..Grapheme(5), |ms| {
                ms.push(is_word.clone());
            })
            .map_marks(Grapheme(7)..Grapheme(12), |ms| {
                ms.push(is_word.clone());
            });
        assert_eq!(text.get_piece(Piece(0)).unwrap().as_str(), "Hello");
        assert_eq!(text.get_piece(Piece(1)).unwrap().as_str(), ", ");
        assert_eq!(text.get_piece(Piece(2)).unwrap().as_str(), "world");
        assert_eq!(text.get_piece(Piece(3)).unwrap().as_str(), "!");
        assert!(text.get_piece(Piece(4)).is_none());
        assert_eq!(Grapheme(13), text.len());
        assert_eq!(text.locate(Grapheme(13)), Ok((Piece(3), Byte(1))));
        assert_eq!(text.get_piece(Piece(3)).unwrap().as_str(), "!");
        assert_eq!(
            text.graphemes()
                .map(|g: Marked| (g.as_ref().to_owned(), g.marks().get::<Word>().cloned()))
                .collect::<Vec<_>>(),
            [
                ("H".into(), Some(is_word.as_ref().clone())),
                ("e".into(), Some(is_word.as_ref().clone())),
                ("l".into(), Some(is_word.as_ref().clone())),
                ("l".into(), Some(is_word.as_ref().clone())),
                ("o".into(), Some(is_word.as_ref().clone())),
                (",".into(), None),
                (" ".into(), None),
                ("w".into(), Some(is_word.as_ref().clone())),
                ("o".into(), Some(is_word.as_ref().clone())),
                ("r".into(), Some(is_word.as_ref().clone())),
                ("l".into(), Some(is_word.as_ref().clone())),
                ("d".into(), Some(is_word.as_ref().clone())),
                ("!".into(), None),
            ]
        );
    }

    #[test]
    fn foo() {
        struct Word {}
        let is_word = Rc::from(Word {});
        let text = Table::from_iter([
            Marked::from("Hello").map_marks(|ms| {
                ms.push(is_word.clone());
            }),
            Marked::from(", "),
            Marked::from("world").map_marks(|ms| {
                ms.push(is_word.clone());
            }),
            Marked::from("!"),
        ]);
        assert_eq!(
            text.pieces()
                .filter(|p: &&Marked| p.marks().contains_any::<Word>())
                .map(|p| p.as_str())
                .collect::<Vec<&str>>(),
            vec!["Hello", "world"]
        );
    }
}
