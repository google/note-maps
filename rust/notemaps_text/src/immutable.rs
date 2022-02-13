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
use core::ops::Range;
use std::rc::Rc;

use crate::offsets::*;
use crate::*;

/// A [String]-like type with `O(1)` [Clone::clone].
///
/// [Immutable] shares an underlying buffer across copies for `O(1)` [Clone::clone] operations. The
/// same tehnique is used in its implemetation of [Slice::slice].
#[derive(Clone, Debug)]
pub struct Immutable<B = Rc<str>> {
    buffer: B,
    byte_range: Range<Byte>,
}

impl<B> Immutable<B>
where
    B: Borrow<str>,
{
    /// Creates a new immutable string based on the entire content of `buffer`.
    ///
    /// Slices of the resulting string will share the same underlying buffer.
    pub fn new(buffer: B) -> Self {
        let byte_range = Byte(0)..Byte(buffer.borrow().len());
        Self { buffer, byte_range }
    }

    /// Returns a reference to the [str] representation of this immutable string.
    pub fn as_str(&self) -> &str {
        &self.buffer.borrow()[self.byte_range.start.0..self.byte_range.end.0]
    }
}

impl<'a, B> From<&'a str> for Immutable<B>
where
    B: Borrow<str> + From<&'a str>,
{
    fn from(s: &'a str) -> Self {
        Self::new(B::from(s))
    }
}

impl<B> Borrow<str> for Immutable<B>
where
    B: Borrow<str>,
{
    fn borrow(&self) -> &str {
        self.as_str()
    }
}

impl<B> AsRef<str> for Immutable<B>
where
    B: Borrow<str>,
{
    fn as_ref(&self) -> &str {
        self.as_str()
    }
}

impl<B, U: Unit> Slice<U> for Immutable<B>
where
    B: Borrow<str> + Clone,
{
    fn len(&self) -> U {
        U::offset_len(self.as_str())
    }

    fn slice(&self, r: Range<U>) -> Self {
        // This implementation is necessarily disjoint from the implementation of Slice for str
        // because Self hides a shared buffer, and Slice::slice doesn't return Byte offsets.
        //
        // TODO: decide whether this makes Slice::slice a violation of C-INTERMEDIATE
        // https://rust-lang.github.io/api-guidelines/flexibility.html#c-intermediate
        let start: Byte = U::nth_byte_offset(self.as_str(), r.start).expect(
            format!(
                "start of range should be within bounds: {:?}[{:?}]",
                self.as_str(),
                r
            )
            .as_str(),
        );
        let end: Byte = U::nth_byte_offset(&self.as_str()[start.0..], r.end - r.start).expect(
            format!(
                "end of range should be within bounds: {:?}[{:?}]",
                self.as_str(),
                r
            )
            .as_str(),
        );
        Self {
            buffer: self.buffer.clone(),
            byte_range: (self.byte_range.start + start)..(self.byte_range.start + start + end),
        }
    }
}

impl<B> Hash for Immutable<B>
where
    B: Borrow<str>,
{
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.as_str().hash(state)
    }
}

impl<B> PartialEq for Immutable<B>
where
    B: Borrow<str>,
{
    fn eq(&self, other: &Self) -> bool {
        self.as_str() == other.as_str()
    }
}

impl<B> Eq for Immutable<B> where B: Borrow<str> {}

impl<B> PartialOrd for Immutable<B>
where
    B: Borrow<str>,
{
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.as_str().partial_cmp(other.as_str())
    }
}

impl<B> Ord for Immutable<B>
where
    B: Borrow<str>,
{
    fn cmp(&self, other: &Self) -> Ordering {
        self.as_str().cmp(other.as_str())
    }
}

#[cfg(test)]
mod an_immutable {}
