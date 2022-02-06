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

use core::borrow::Borrow;
use core::cmp::Ordering;
use core::hash::Hash;
use core::hash::Hasher;
use core::iter;
use core::ops::Range;
use std::rc::Rc;

use crate::offsets::*;

/*
pub trait Locii<U: Unit> {
    fn locus_at(&self, offset: U) -> Result<Locus, Locus>;
}

impl<'a> Locii<Grapheme> for &'a str {
    fn locus_at(&self, offset: Grapheme) -> Result<Locus, Locus> {
        Grapheme::nth_byte_offset(self, offset)
            .map(|ok| Locus::from_grapheme_byte(ok, offset, self))
            .map_err(|_| Locus::from_len(self))
    }
}

use std::fmt;

pub trait Cursor<U:Unit>{
    fn move(self, at:U)->Cursor{
    }
}

/// Types that implement [Text] support a minimal set of string operations that work as though the
/// [Unit] type `U` defines the boundaries between the smallest non-divisible atoms of a string.
///
/// [Text] requires implementors to implement [fmt::Display] because this eases generic testing and
/// debugging for [Text] implementations. This should be trivial anyway since every implementor of
/// [Text] represents a string-like data.
///
/// [Text] requires implementors to implement [Clone] because all intended use cases of [Text] will
/// require implementors to support cloning anyway. In addition to implementing [Clone],
/// implementors are expected to clone in O(1) constant-time.
///
/// # Example
///
/// ```rust
/// use notemaps_text::Text;
/// use notemaps_text::offsets::Grapheme;
///
/// fn take_five_graphemes(string: Text<Grapheme>) -> Text<Grapheme> {
///     string
///         .slice(Grapheme(0)..Grapheme(5))
///         .expect("string is at least 5 graphemes long")
///         .to_string()
/// }
/// ```
/// smallest indivi
/// `U`, where type `U` might be [Grapheme].
pub trait Text<U: Unit>: Clone+fmt::Display {
    type Slice: Text<U>;

    fn slice(&self, r: Range<U>) -> Result<Self::Slice, Self::Slice>;

    fn len(&self) -> U;
}

use std::borrow::Cow;

pub struct Split<'a,T:Text<U>+Clone,U:Unit, I:Iterator<Item=U>>(Cow<'a,T>, I );

pub fn atomize<'a,T:Text<U>,U:Unit>(text:&'a T)->Split<'a,T,U,_>{
    Split( Cow::from(text), U::from(0)..)
}


impl<'a,T:Text<U>,U:Unit, I:Iterator<Item=U>> Iterator for Split<'a,T,U,I>{
    type Item=T::Slice;
    fn next(&mut self)->Option<Self::Item>{
        self.1.next().map(|i| self.0.slice(i..i+1))
    }
}

#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub(crate) struct Slow<'a>(pub &'a str);

impl<'a, U: Unit> Text<U> for Slow<'a> {
    type Slice = Self;

    fn slice(&self, r: Range<U>) -> Result<Self::Slice, Self::Slice> {
        let (start, err) = U::nth_byte_offset(self.0, r.start)
            .map_or_else( |err| (err, true), |ok| (ok, false));
        let (end, err) = if err {
            (start, err)
        } else {
                U::nth_byte_offset(&self.0[start.0..], r.end - r.start)
            .map_or_else( |err| (start+err, true), |ok| (start+ok, false))
        };
        let slice = &self.0[start.0..end.0];
        if err {
            Err(Self(slice))
        } else {
            Ok(Self(slice))
        }
    }

    /*
    fn prefix(&self, end: U) -> Result<Self::Slice, Self::Slice> {
        U::nth_byte_offset(self.0, end)
            .map(|end| Self(&self.0[..end.0]))
            .map_err(|_| self.clone())
    }

    fn suffix(&self, start: U) -> Result<Self::Slice, Self::Slice> {
        U::nth_byte_offset(self.0, start)
            .map(|ok| Self(&self.0[ok.0..]))
            .map_err(|err| Self(&self.0[err.0..]))
    }
    */

    //fn locus<U:Unit>(&self, offset: U)->Result<Locus, Locus> where Locus:AsRef<U>{ U::nth_byte_offset(self.0, offset) .map(|ok| Locus::from_grapheme_byte(ok, offset, self.0)) .map_err(|_| Locus::from_len( self.0))?; }
    //fn len<U:Unit>(&self)->U where Locus:AsRef<U>{todo!("");}
    fn len(&self) -> U {
        U::offset_len(self.0)
    }
}

impl<'a> fmt::Display for Slow<'a> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.0.fmt(f)
    }
}

pub trait Cursor {
    type Item;
    type Index: Sized;
    fn move_next(&mut self);
    fn move_prev(&mut self);
    fn current(&self) -> Option<Self::Item>;
    fn index(&self) -> Self::Index;
}

pub struct IterCursor<I: Iterator + Clone> {
    current: usize,
    iter: I,
}

impl<I: Iterator + Clone> Cursor for IterCursor<I> {
    type Item = I::Item;
    type Index = usize;
    fn move_next(&mut self) {
        if self.current < usize::MAX - 1 && self.iter.clone().advance_by(self.current + 1).is_ok() {
            self.current += 1
        }
    }
    fn move_prev(&mut self) {
        if self.current > 0 && self.iter.clone().advance_by(self.current - 1).is_ok() {
            self.current -= 1
        }
    }
    fn current(&self) -> Option<Self::Item> {
        self.iter.clone().nth(self.current)
    }
    fn index(&self) -> Self::Index {
        self.current
    }
}

pub struct NestedCursor<I: Iterator<Item: Into<C>> + Clone, C: Cursor> {
    mine: IterCursor<I>,
    wrapped: Option<C>,
}

pub trait Slicer<U: Unit> {
    type Slice;
    fn slice_nth_next(&mut self, n: U) -> Result<Self::Slice, U>;
    fn slice_nth_prev(&mut self, n: U) -> Result<Self::Slice, U>;
    fn offset(&self) -> U;
}

pub struct StrByteSlicer<'a>(&'a str, Byte);
impl<'a> Slicer<Byte> for StrByteSlicer<'a> {
    type Slice = &'a str;
    fn slice_nth_next(&mut self, n: U) -> Result<Self::Slice, U>;
    fn slice_nth_prev(&mut self, n: U) -> Result<Self::Slice, U>;
    fn offset(&self) -> U;
}

pub struct StrGraphemeCursor<'a> {
    string: &'a str,
    wrapped: unicode_segmentation::GraphemeCursor,
    current: Grapheme,
}

impl<'a> StrGraphemeCursor<'a> {
    fn new(string: &'a str) -> Self {
        Self {
            string,
            wrapped: unicode_segmentation::GraphemeCursor::new(0, string.len(), true),
            current: Grapheme(0),
        }
    }
}

impl<'a> Slicer<Grapheme> for StrGraphemeCursor<'a> {
    type Slice = &'a str;

    fn slice_nth_next(&mut self, n: Grapheme) -> Result<Self::Slice, Grapheme> {
        let start = self.wrapped.cur_cursor();
        let available: Grapheme = (0..n.0)
            .map_while(|_| self.wrapped.next_boundary(self.string, 0).unwrap_or(None))
            .count()
            .into();
        if available < n {
            self.wrapped.set_cursor(start);
            Err(available.into())
        } else {
            self.current += available;
            Ok(&self.string[start..self.wrapped.cur_cursor()])
        }
    }

    fn slice_nth_prev(&mut self, n: Grapheme) -> Result<Self::Slice, Grapheme> {
        let start = self.wrapped.cur_cursor();
        let available: Grapheme = (0..n.0)
            .map_while(|_| self.wrapped.prev_boundary(self.string, 0).unwrap_or(None))
            .count()
            .into();
        if available < n {
            self.wrapped.set_cursor(start);
            Err(available.into())
        } else {
            self.current += available;
            Ok(&self.string[start..self.wrapped.cur_cursor()])
        }
    }

    fn offset(&self) -> Grapheme {
        self.current
    }
}

pub struct Splits<C: Slicer<I::Item>, I: Iterator<Item: Unit>> {
    cursor: C,
    iter: I,
}

impl<C: Slicer<I::Item>, I: Iterator<Item: Unit>> Splits<C, I> {
    pub fn new(cursor: C, iter: I) -> Self {
        Self { cursor, iter }
    }
}

impl<C: Slicer<I::Item>, I: Iterator<Item: Unit>> Iterator for Splits<C, I> {
    type Item = C::Slice;

    fn next(&mut self) -> Option<Self::Item> {
        self.iter
            .next()
            .and_then(|o| self.cursor.slice_nth_next(o - self.cursor.offset()).ok())
    }
}

struct StrTextCursor<'a>(&'a str, Locus);

impl<'a> TextCursor<Grapheme> for StrTextCursor<'a>{
    type Slice= iter::Once<&'a str>;
    fn slice<T:Into<Byte>>(&self, end: T)->Self::Slice{
        iter::once(&self.0[self.index().byte().0..end.into().0])
    }
    fn move_nth_next(&mut self, n: Grapheme)->Result<Locus, Locus>{
        self.1 = Unit::nth_byte_offset(&self.0[self.1.byte().0..], n)
            .map(|byte| Locus::from_grapheme_byte(byte, n, self.0))
            .map_err(|_| self.1)?;
        Ok(self.1)
    }
    fn index(&self)->Locus{ self.1 }
}

pub trait Text {
    type Slice: Text;
    type Split: Iterator<Item = Self::Slice>;

    fn slice(&self, r: Range<Grapheme>) -> Self::Slice;

    fn len<U>(&self) -> U
    where
        U: Clone,
        Locus: AsRef<U>;

    fn split<I: IntoIterator<Item = Grapheme>>(&self, at: I) -> Self::Split;

    fn graphemes(&self) -> Self::Split;
}

impl<S: Borrow<str>> Text for UiString<S> {
    type Slice = Self;
    type Split= Split<UiString<S>>;

    fn slice(&self, r: Range<Grapheme>) -> Self::Slice{todo!(""); }

    fn len<U>(&self) -> U
    where
        U: Clone,
        Locus: AsRef<U>{
        todo!("");
        }

    fn split<I: IntoIterator<Item = Grapheme>>(&self, at: I) -> Self::Split{
        todo!("");
    }

    fn graphemes(&self) -> Self::Split{
        todo!("");
    }
}


struct Split<T:Text, >{
    text: T,
          start: Grapheme,
          at: Box<dyn Iterator<Item= Grapheme>>,
}

impl<T:Text> Iterator for Split<T>{
type Item=T::Slice;
fn next(&mut self)->Option<Self::Item>{
    self.at.next() .map(|end| {
                let split = self.slice(self.start..end);
                self.start = end;
                Some(split)
            })
}
}
*/

/// An immutable [str] wrapper that re-uses its underlying buffer when taking slices of itself so
/// that cloning is cheap enough that, for most use cases where a `&str` would be preferred over a
/// `String`, this [UiString] can simply be copied instead.
///
/// Unlike [String] and [std::borrow::Cow], [UiString] does _not_ implement [core::ops::Deref]. It does,
/// however, implement [core::borrow::Borrow] and [AsRef] for the underlying [str].
#[derive(Clone, Debug)]
pub struct UiString<B: Borrow<str> = Rc<str>> {
    buffer: B,
    byte_range: Range<usize>,
    len_chars: Char,
    len_graphemes: Grapheme,
}

impl<B: Borrow<str>> UiString<B> {
    pub fn new(buffer: B) -> Self {
        use unicode_segmentation::UnicodeSegmentation;
        let byte_range = 0..buffer.borrow().len();
        let len_chars = buffer.borrow().chars().count().into();
        let len_graphemes = buffer.borrow().graphemes(true).count().into();
        Self {
            buffer,
            byte_range,
            len_chars,
            len_graphemes,
        }
    }

    #[must_use]
    pub fn slice(&self, r: Range<Grapheme>) -> Self
    where
        B: Clone,
    {
        use unicode_segmentation::UnicodeSegmentation;
        let mut graphemes = self
            .as_str()
            .grapheme_indices(true)
            .map(|t| t.0)
            .chain(iter::once(self.as_str().len()));
        let start = self.byte_range.start
            + graphemes
                .by_ref()
                .nth(*r.start.as_ref())
                .expect("range starts within bounds of this piece");
        let end = if r.is_empty() {
            start
        } else {
            self.byte_range.start
                + graphemes
                    .by_ref()
                    .nth(*r.end.as_ref() - 1 - *r.start.as_ref())
                    .expect("range ends within bounds of piece")
        };
        Self {
            buffer: self.buffer.clone(),
            byte_range: start..end,
            len_chars: (&self.buffer.borrow()[start..end]).chars().count().into(),
            len_graphemes: r.end - r.start,
        }
    }

    /// Returns the total length of the underlying text in `U` elements.
    pub fn len<U>(&self) -> U
    where
        U: Clone,
        Locus: AsRef<U>,
    {
        Locus(
            Byte(self.byte_range.len()),
            self.len_chars,
            self.len_graphemes,
        )
        .as_ref()
        .clone()
    }

    pub fn as_str(&self) -> &str {
        &self.buffer.borrow()[self.byte_range.clone()]
    }

    pub fn split<I: IntoIterator<Item = Grapheme>>(&self, at: I) -> impl Iterator<Item = Self>
    where
        B: Clone,
    {
        Splits::new(StrGraphemeCursor::new(self.as_str()), at.into_iter())
    }

    pub fn graphemes(&self) -> impl Iterator<Item = Self>
    where
        B: Clone,
    {
        self.split(Grapheme(1)..=self.len_graphemes)
    }

    /// Returns the location of `offset` in this [UiString] as a [Byte] offset into the string
    /// returned by [UiString::as_str].
    ///
    /// If `offset` is out of bounds, returns the bounds of this piece.
    pub fn locate(&self, offset: Grapheme) -> Result<Locus, Locus> {
        Unit::nth_byte_offset(self.as_str(), offset)
            .map(|byte| Locus::from_grapheme_byte(byte, offset, self.as_str()))
            .map_err(|_| self.len())
    }
}

impl<S: Borrow<str>> Default for UiString<S>
where
    S: Default,
{
    fn default() -> Self {
        Self::new(Default::default())
    }
}

impl<'a, S: Borrow<str>> From<&'a str> for UiString<S>
where
    S: From<&'a str>,
{
    fn from(s: &'a str) -> Self {
        Self::new(s.into())
    }
}

impl<S: Borrow<str>> Borrow<str> for UiString<S> {
    fn borrow(&self) -> &str {
        self.as_str()
    }
}

impl<S: Borrow<str>> AsRef<str> for UiString<S> {
    fn as_ref(&self) -> &str {
        self.as_str()
    }
}

impl<S: Borrow<str>> Hash for UiString<S> {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.as_str().hash(state)
    }
}

impl<S: Borrow<str>> PartialEq for UiString<S> {
    fn eq(&self, other: &Self) -> bool {
        self.as_str() == other.as_str()
    }
}

impl<S: Borrow<str>> Eq for UiString<S> {}

impl<S: Borrow<str>> PartialOrd for UiString<S> {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.as_str().partial_cmp(other.as_str())
    }
}

impl<S: Borrow<str>> Ord for UiString<S> {
    fn cmp(&self, other: &Self) -> Ordering {
        self.as_str().cmp(other.as_str())
    }
}
#[cfg(test)]
mod a_str {
    use crate::offsets::*;
    use crate::*;
    use std::rc::Rc;

    #[test]
    fn can_slice() {
        let piece: UiString<Rc<str>> = UiString::from("a̐éö̲\r\n");
        assert_eq!(piece.slice(Grapheme(1)..Grapheme(2)).as_str(), "é");
    }

    #[test]
    fn can_slice_of_slice() {
        let piece: UiString = "a̐éö̲\r\n".into();
        assert_eq!(
            piece
                .slice(Grapheme(1)..Grapheme(4))
                .slice(Grapheme(1)..Grapheme(2))
                .as_str(),
            "ö̲",
        );
    }

    #[test]
    fn can_split_into_graphemes() {
        let piece: UiString<Rc<str>> = UiString::from("a̐éö̲\r\n");
        assert_eq!(
            piece
                .graphemes()
                .map(|s| s.as_str().to_string())
                .collect::<Vec<_>>(),
            ["a̐", "é", "ö̲", "\r\n",]
        );
    }

    #[test]
    fn can_slice_and_split_into_graphemes() {
        let piece: UiString<Rc<str>> = UiString::from("a̐éö̲\r\n");
        let slice = piece.slice(Grapheme(1)..Grapheme(4));
        assert_eq!(
            slice
                .graphemes()
                .map(|s| s.as_str().to_string())
                .collect::<Vec<_>>(),
            ["é", "ö̲", "\r\n",]
        );
    }

    #[test]
    fn can_report_its_length_in_different_units() {
        let piece: UiString<Rc<str>> = UiString::from("a̐éö̲\r\n");
        assert_eq!(Byte(13), piece.len());
        assert_eq!(Char(9), piece.len());
        assert_eq!(Grapheme(4), piece.len());
    }
}
