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

use core::ops::Range;

use crate::offsets::*;

/// A representation of Unicode text that can be sliced to return pieces of itself.
///
/// The main feature of this generic interface to text is that it makes no assumptions about the
/// structure of the textual data. It can be implemented for [str] and [String], but it can also be
/// implemented for ropes and piece tables.
pub trait Slice<U>: Sized {
    /// Returns the length of this slice in `U` units. This is also the maximum valid offset in
    /// arguments to [Slice::slice], [Slice::split], and [Slice::locate].
    fn len(&self) -> U;

    /// Returns a slice of the same type limited to content within the given range.
    ///
    /// [Slice::slice] is intended by be very similar to [core::ops::Index::index] for
    /// implementations of `Index<Range>`.
    fn slice(&self, r: Range<U>) -> Self;

    /// Splits this slice at each offset in `offsets`, returning an iterator of the resulting
    /// slices.
    fn split<I>(&self, offsets: I) -> Split<'_, Self, U, I::IntoIter>
    where
        U: Unit,
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
        U: Unit,
        O: Unit,
        E: Unit,
    {
        if offset > self.len() {
            Err(self.len())
        } else {
            Ok(self.slice(U::from(0)..offset).len())
        }
    }
}

impl<'a> Slice<Byte> for &'a str {
    fn len(&self) -> Byte {
        Byte::offset_len(self)
    }
    fn slice(&self, r: Range<Byte>) -> Self {
        &(*self)[r.start.0..r.end.0]
    }
}

impl<'a> Slice<Char> for &'a str {
    fn len(&self) -> Char {
        Char::offset_len(self)
    }
    fn slice(&self, r: Range<Char>) -> Self {
        Char::get_slice(self, r)
    }
}

impl<'a> Slice<Grapheme> for &'a str {
    fn len(&self) -> Grapheme {
        Grapheme::offset_len(self)
    }
    fn slice(&self, r: Range<Grapheme>) -> Self {
        Grapheme::get_slice(self, r)
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
