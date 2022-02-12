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

use core::iter;

use crate::offsets::*;

/// A representation of Unicode text that can be sliced to return pieces of itself.
///
/// The main feature of this generic interface to text is that it makes no assumptions about the
/// structure of the textual data. It can be implemented for [str] and [String], but it can also be
/// implemented for ropes and piece tables.
pub trait Slice<U: Unit>: Sized {
    fn len(&self) -> U;

    fn slice(&self, r: core::ops::Range<U>) -> Self;

    fn split<I>(&self, offsets: I) -> Split<'_, Self, U, I::IntoIter>
    where
        I: IntoIterator<Item = U>,
        Self: Sized,
    {
        Split::new(self, offsets.into_iter())
    }

    /// Translates an `offset` into the underlying text from `U` units to a `O` units.
    ///
    /// The maximum value for `offset` is the total length of `self` in `U` units.
    ///
    /// Returns the location of `offset` in `O` units. If `offset` is out of bounds, returns the
    /// maximum allowable value of `offset` in `E` units as an error.
    ///
    /// # Implementation
    ///
    /// The default implementation of this trait method is inefficient.
    fn locate<O, E>(&self, offset: U) -> Result<O, E>
    where
        Self: Slice<O> + Slice<E>,
        O: Unit,
        E: Unit,
        Locus: AsRef<U>,
        Locus: AsRef<O>,
        Locus: AsRef<E>,
    {
        if offset > Slice::<U>::len(self) {
            Err(Slice::<E>::len(self))
        } else {
            Ok(self.slice(U::from(0)..offset).len())
        }
    }
}

impl<'a> Slice<Byte> for &'a str {
    fn len(&self) -> Byte {
        Byte::offset_len(self)
    }
    fn slice(&self, r: core::ops::Range<Byte>) -> Self {
        &(*self)[r.start.0..r.end.0]
    }
}

impl<'a> Slice<Char> for &'a str {
    fn len(&self) -> Char {
        Char::offset_len(self)
    }
    fn slice(&self, r: core::ops::Range<Char>) -> Self {
        let mut byte_offsets = str::char_indices(self)
            .map(|t| Byte(t.0))
            .chain(iter::once(self.len()));
        let start: Byte = byte_offsets
            .by_ref()
            .nth(*r.start.as_ref())
            .expect("range starts within bounds of this piece");
        let end: Byte = if r.is_empty() {
            start
        } else {
            byte_offsets
                .by_ref()
                .nth(*r.end.as_ref() - 1 - *r.start.as_ref())
                .expect("range ends within bounds of piece")
        };
        self.slice(start..end)
    }
}

impl<'a> Slice<Grapheme> for &'a str {
    fn len(&self) -> Grapheme {
        Grapheme::offset_len(self)
    }
    fn slice(&self, r: core::ops::Range<Grapheme>) -> Self {
        use unicode_segmentation::UnicodeSegmentation;
        let mut graphemes = self
            .grapheme_indices(true)
            .map(|t| Byte(t.0))
            .chain(iter::once(self.len()));
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
        self.slice(start..end)
    }
}

/// The iterator type returned by [Slice::split].
pub struct Split<'a, S: ?Sized + Slice<U>, U: Unit, I: Iterator> {
    slice: &'a S,
    offsets: I,
    start: U,
}

impl<'a, S, U, I> Split<'a, S, U, I>
where
    S: ?Sized + Slice<U>,
    U: Unit,
    I: Iterator<Item = U>,
{
    fn new(slice: &'a S, offsets: I) -> Self {
        Self {
            slice,
            offsets,
            start: U::from(0),
        }
    }
}

impl<'a, S, U, I> Iterator for Split<'a, S, U, I>
where
    S: Slice<U>,
    U: Unit,
    I: Iterator<Item = U>,
{
    type Item = S;

    fn next(&mut self) -> Option<Self::Item> {
        self.offsets.next().map(|end| {
            let split = self.slice.slice(self.start..end);
            self.start = end;
            split
        })
    }
}
