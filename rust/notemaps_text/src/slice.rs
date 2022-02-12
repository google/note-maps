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

use crate::offsets::*;
use crate::*;

/// A representation of Unicode text that can be sliced to return pieces of itself.
///
/// The main feature of this generic interface to text is that it makes no assumptions about the
/// structure of the textual data. It can be implemented for [str] and [String], but it can also be
/// implemented for ropes and piece tables.
pub trait Slice<U: Unit>: Sized {
    fn len2(&self) -> U;

    fn slice(&self, r: core::ops::Range<U>) -> Self;

    fn split<I>(&self, offsets: I) -> Split<'_, Self, U, I::IntoIter>
    where
        I: IntoIterator<Item = U>,
        Self: Sized,
    {
        Split::new(self, offsets.into_iter())
    }

    /// Translates an `offset` in self to a [Byte] offset into the underlying text.
    ///
    /// The maximum value for `offset` is the length of `self`.
    ///
    /// Returns the location of `offset` in [Byte] units. If `offset` is out of bounds, returns the
    /// maximum allowable value of `offset` as an error.
    ///
    /// # Implementation
    ///
    /// The default implementation of this trait method is inefficient.
    fn locate<O, E>(&self, offset: U) -> Result<O, E>
    where
        Self: Len,
        E: Clone,
        O: Clone,
        Locus: AsRef<U>,
        Locus: AsRef<O>,
        Locus: AsRef<E>,
    {
        if offset > self.len::<U>() {
            Err(self.len::<E>())
        } else {
            Ok(self.slice(U::from(0)..offset).len())
        }
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
