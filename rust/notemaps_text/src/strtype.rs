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
        let mut start = Grapheme(0);
        at.into_iter()
            .map_while(|end| {
                let split = self.slice(start..end);
                start = end;
                Some(split)
            })
            .collect::<Vec<_>>()
            .into_iter()
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
