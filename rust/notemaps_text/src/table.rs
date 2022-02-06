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
use std::borrow::Borrow;
use std::fmt;
use std::iter;
use std::rc::Rc;

use crate::offsets::*;
use crate::*;

/// [Table] is a sequence of [MarkStr] values, effectively a [piece table][].
///
/// Although currently based on a [Vec], future iterations of development may replace the internal
/// implementation with something like a [rope][] or [gap buffer][]. The API of [Table] is
/// deliberately agnostic to these implementation details, committing only to presenting the data
/// as no more than a sequence of [MarkStr] values that may or may not be usefully optimized for
/// interesting uses.
///
/// [piece table]: https://en.wikipedia.org/wiki/MarkStr_table
/// [rope]: https://en.wikipedia.org/wiki/Rope_(computer_science)
/// [gap buffer]: https://en.wikipedia.org/wiki/Gap_buffer
///
/// # Examples
///
/// ```rust
/// use notemaps_text::Table;
/// use notemaps_text::MarkStr;
///
/// let text: Table = [MarkStr::from("Hello, world!"), MarkStr::from("\n")].into_iter().collect();
/// assert_eq!(text.to_string(), "Hello, world!\n");
/// ```
#[derive(Clone, Debug)]
pub struct Table<S: Borrow<str> = Rc<str>> {
    pieces: Vec<MarkStr<S>>,
    len: Locus,
}

pub type MarkStrLocus = (usize, Locus);

impl<S: Borrow<str>> Table<S> {
    /// Creates a new, empty [Table].
    pub fn new() -> Self {
        Self {
            pieces: Vec::new(),
            len: Locus::zero(),
        }
    }

    /// Returns an iterator over all the individual graphemes in `self`.
    pub fn graphemes(&self) -> impl '_ + Iterator<Item = MarkStr<S>>
    where
        S: Clone,
    {
        self.pieces().flat_map(|p| p.graphemes())
    }

    //pub fn marked_graphemes(&self)->impl Iterator<Item=MarkStr>{
    //self.pieces.iter().map(|p|p.graphemes().m
    //}

    /// Returns the `n`th piece, or [None] if `n` is greater than the number of pieces in `self`.
    ///
    /// NOTE: This is a low-level API that risks coupling the usage of [Table] to implementation
    /// details.
    pub fn get_piece(&self, n: usize) -> Option<&MarkStr<S>> {
        if n < self.pieces.len() {
            Some(&self.pieces[n])
        } else {
            None
        }
    }

    /// Returns a reference to each [MarkStr] in `self`, which is the entire content or meaning of
    /// this [Table].
    ///
    /// NOTE: This is a low-level API that risks coupling the usage of [Table] to implementation
    /// details.
    pub fn pieces(&self) -> Pieces<S> {
        Pieces(self.pieces.iter())
    }

    /// Returns a mutable reference to each [MarkStr] in `self`, which is the entire content or
    /// meaning of this [Table].
    pub fn pieces_mut(&mut self) -> PiecesMut<S> {
        PiecesMut(self.pieces.iter_mut())
    }

    /// Returns the total length of the text in `U` elements.
    pub fn len<U>(&self) -> U
    where
        U: Clone,
        Locus: AsRef<U>,
    {
        self.len.as_ref().clone()
    }

    /// Returns a specialized representation of the location of `offset` within `self`.
    pub fn locate(&self, offset: Grapheme) -> Result<MarkStrLocus, MarkStrLocus> {
        if self.pieces.is_empty() {
            return if offset.0 == 0 {
                Ok((0, Locus::zero()))
            } else {
                Err((0, Locus::zero()))
            };
        }
        use std::cmp;
        match offset.cmp(&self.len.grapheme()) {
            cmp::Ordering::Greater => {
                return Err((
                    self.pieces.len() - 1,
                    self.pieces[self.pieces.len() - 1].as_ui_str().len(),
                ));
            }
            cmp::Ordering::Equal => {
                return Ok((
                    self.pieces.len() - 1,
                    self.pieces[self.pieces.len() - 1].as_ui_str().len(),
                ));
            }
            _ => {}
        }
        let mut todo = offset;
        for (i, p) in self.pieces.iter().enumerate() {
            if p.as_ui_str().len::<Grapheme>() > todo {
                return Ok((
                    i,
                    p.as_ui_str()
                        .locate(todo)
                        .expect("locating an offset less than the length always works"),
                ));
            } else {
                todo -= p.as_ui_str().len::<Grapheme>();
            }
        }
        panic!("this should never happen...");
    }

    /// Returns a [Cursor] positioned at `offset` within `self`.
    pub fn cursor(&self, offset: Grapheme) -> Cursor<S> {
        Cursor::new(self, offset)
    }

    /// Copies the content of `self` from range `r` into a new [Table].
    #[must_use]
    pub fn slice(&self, r: Range<Grapheme>) -> Self
    where
        S: Clone,
    {
        if r.end <= r.start {
            return Table::new();
        }
        let start = self
            .locate(r.start)
            .expect("argument to slice is always valid");
        let end = self
            .locate(r.end)
            .expect("argument to slice is always valid");
        if start == end {
            return Table::new();
        }
        if start.0 == end.0 {
            return self.pieces[start.0]
                .slice(start.1.whatever()..end.1.whatever())
                .into();
        }
        iter::once(
            self.pieces[start.0].slice(start.1.whatever()..self.pieces[start.0].as_ui_str().len()),
        )
        .chain(self.pieces[(start.0 + 1)..end.0].iter().cloned())
        .chain(iter::once(
            self.pieces[end.0].slice(Grapheme(0)..end.1.whatever()),
        ))
        .collect()
    }

    #[must_use]
    pub fn with_insert<I: IntoIterator>(&self, n: Grapheme, text: I) -> Self
    where
        Table<S>: FromIterator<I::Item>,
        S: Clone,
    {
        self.slice(Grapheme::MIN..n) + Self::from_iter(text) + self.slice(n..self.len())
    }

    /// Pushes the mark `m` onto every [MarkStr] in `self`.
    pub fn mark<M: Any>(&mut self, m: Rc<M>) {
        for piece in self.pieces_mut() {
            piece.marks_mut().push(m.clone());
        }
    }

    /// Removes the mark `m` from every [MarkStr] in `self`.
    pub fn unmark<M: Any + PartialEq>(&mut self, m: &M) {
        for piece in self.pieces_mut() {
            if piece.marks_mut().contains(&*m) {
                piece.marks_mut().take_any::<M>();
            }
        }
    }

    /// Consumes `self`, pushes the mark `m` onto every [MarkStr], and returns the result.
    pub fn with_mark<M: Any>(mut self, m: Rc<M>) -> Self {
        self.mark(m);
        self
    }

    /// Consumes `self`, removes the mark `m` from every [MarkStr], and returns the result.
    pub fn with_unmark<M: Any + PartialEq>(mut self, m: &M) -> Self {
        self.unmark(m);
        self
    }
}

impl<S: Borrow<str>> Default for Table<S> {
    fn default() -> Self {
        Self::new()
    }
}

impl<S: Borrow<str>> FromIterator<MarkStr<S>> for Table<S> {
    fn from_iter<T: IntoIterator<Item = MarkStr<S>>>(iter: T) -> Self {
        let pieces: Vec<MarkStr<S>> = iter.into_iter().collect();
        let len: Locus = pieces.iter().map(|p| p.as_ui_str().len()).sum();
        Self { pieces, len }
    }
}

impl<S: Borrow<str>> From<MarkStr<S>> for Table<S> {
    fn from(piece: MarkStr<S>) -> Self {
        iter::once(piece).collect()
    }
}

impl<'a, S: Borrow<str>> From<&'a str> for Table<S>
where
    S: From<&'a str>,
{
    fn from(string: &'a str) -> Self {
        MarkStr::from(string).into()
    }
}

// TODO: consider refactoring these implementations of ops::Add to more closely resemble what's
// done for std::string::String.

impl<S: Borrow<str>> ops::Add<Self> for Table<S> {
    type Output = Self;
    fn add(self, other: Self) -> Self {
        self.into_iter().chain(other.into_iter()).collect()
    }
}

impl<S: Borrow<str>> ops::Add<MarkStr<S>> for Table<S> {
    type Output = Self;
    fn add(self, other: MarkStr<S>) -> Self {
        self.into_iter().chain(iter::once(other)).collect()
    }
}

impl<S: Borrow<str>> IntoIterator for Table<S> {
    type Item = MarkStr<S>;
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

/// [Pieces] is the [Iterator] type returned by [Table::pieces].
pub struct Pieces<'a, S: Borrow<str>>(std::slice::Iter<'a, MarkStr<S>>);

impl<'a, S: Borrow<str>> Iterator for Pieces<'a, S> {
    type Item = &'a MarkStr<S>;

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
pub struct PiecesMut<'a, S: Borrow<str>>(std::slice::IterMut<'a, MarkStr<S>>);

impl<'a, S: Borrow<str>> Iterator for PiecesMut<'a, S> {
    type Item = &'a mut MarkStr<S>;

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
        let text: Table = MarkStr::new(MarkSet::new(), "a̐éö̲\r\n".into()).into();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
    }

    #[test]
    fn can_be_collected_from_pieces() {
        let text: Table = [MarkStr::from("a̐éö̲"), MarkStr::from("\r\n")]
            .into_iter()
            .collect();
        assert_eq!(text.to_string(), "a̐éö̲\r\n");
        assert_eq!(text.len::<Grapheme>(), Grapheme(4));
        assert_eq!(
            text.pieces().map(|p| p.as_str()).collect::<Vec<&str>>(),
            vec!["a̐éö̲", "\r\n"]
        );
    }

    #[test]
    fn can_be_built_from_concatenation() {
        assert_eq!(
            (Table::<Rc<str>>::from("a̐éö̲") + Table::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
        assert_eq!(
            (Table::<Rc<str>>::from("a̐éö̲") + MarkStr::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
        assert_eq!(
            (MarkStr::<Rc<str>>::from("a̐éö̲") + MarkStr::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
        assert_eq!(
            (MarkStr::<Rc<str>>::from("a̐éö̲") + Table::from("\r\n")).to_string(),
            "a̐éö̲\r\n"
        );
    }

    #[test]
    fn can_be_sliced() {
        let text = Table::<Rc<str>>::from_iter([MarkStr::from("a̐éö̲"), MarkStr::from("\r\n")]);
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
        let mut text = Table::from_iter([MarkStr::from("a̐éö̲"), MarkStr::from("\r\n")]);
        text.mark(Rc::new("test mark"));
        assert!(text
            .pieces()
            .all(|p: &MarkStr| p.marks().contains(&"test mark")));
        text.unmark(&"test mark");
        assert!(text.pieces().all(|p| !p.marks().contains(&"test mark")));
    }

    #[test]
    fn creates_new_text_with_insertion() {
        let text = Table::<Rc<str>>::from("Hello!");
        let text = text.with_insert(Grapheme(5), [MarkStr::from(", world")]);
        assert_eq!(text.slice(Grapheme(9)..Grapheme(10)).to_string(), "r");
        assert_eq!(text.slice(Grapheme(10)..Grapheme(11)).to_string(), "l");
        assert_eq!(text.slice(Grapheme(11)..Grapheme(12)).to_string(), "d");
        assert_eq!(text.slice(Grapheme(12)..Grapheme(13)).to_string(), "!");
    }

    /*
    #[test]
    fn can_be_inspected_in_detail(){
        let text = Table::from("Hello, world!");
        #[derive(Debug, PartialEq, Hash)]
        struct Word {}
        let is_word = Rc::from(Word {});
        let text:Table = [MarkStr::from("a̐éö̲").with_mark(is_word.clone()), MarkStr::from("\r\n")].into_iter().collect();
        assert_eq!(text.to_string(),"a̐éö̲\r\n");
        assert_eq!(
            text.pieces()
                .flat_map(|p| p.graphemes().map(|g| (g, p.marks().get::<Word>())))
                .collect::<Vec<_>>(),
            [
                ("H", Some(&*is_word)),
                ("e", Some(&*is_word)),
                ("l", Some(&*is_word)),
                ("l", Some(&*is_word)),
                ("o", Some(&*is_word)),
                (",", None),
                (" ", None),
                ("w", Some(&*is_word)),
                ("o", Some(&*is_word)),
                ("r", Some(&*is_word)),
                ("l", Some(&*is_word)),
                ("d", Some(&*is_word)),
                ("!", None),
            ]
        );
    }
    */

    #[test]
    fn can_mark_a_slice() {
        let text = Table::from("Hello, world!");
        #[derive(Clone, Debug, PartialEq, Hash)]
        struct Word {}
        let is_word = Rc::from(Word {});
        let text = text
            .slice(Grapheme(0)..Grapheme(5))
            .with_mark(is_word.clone())
            + text.slice(Grapheme(5)..Grapheme(7))
            + text
                .slice(Grapheme(7)..Grapheme(12))
                .with_mark(is_word.clone())
            + text.slice(Grapheme(12)..Grapheme(13));
        assert_eq!(
            text.locate(Grapheme(13)),
            Ok((3, Locus(1.into(), 1.into(), 1.into())))
        );
        assert_eq!(text.get_piece(3).unwrap().as_str(), "!");
        assert_eq!(
            text.graphemes()
                .map(|g: MarkStr| (g.to_ui_str(), g.marks().get::<Word>().cloned()))
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
            MarkStr::from("Hello").with_mark(is_word.clone()),
            MarkStr::from(", "),
            MarkStr::from("world").with_mark(is_word.clone()),
            MarkStr::from("!"),
        ]);
        assert_eq!(
            text.pieces()
                .filter(|p: &&MarkStr| p.marks().contains_any::<Word>())
                .map(|p| p.as_str())
                .collect::<Vec<&str>>(),
            vec!["Hello", "world"]
        );
    }
}
