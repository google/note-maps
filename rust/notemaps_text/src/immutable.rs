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
use std::fmt;
use std::rc::Rc;

use crate::offsets::*;
use crate::*;

/// A [String]-like type with `O(1)` [Clone::clone].
///
/// [Immutable] shares an underlying buffer across copies for `O(1)` [Clone::clone] operations. The
/// same tehnique is used in its implemetation of [Slice::slice].
///
/// ```
/// use notemaps_text::Immutable;
/// use notemaps_text::*;
/// use notemaps_text::offsets::Char;
///
/// let fizzbuzz: Immutable = "12Fizz4Buzz".into();
/// let fizz: Immutable = fizzbuzz.slice(Char(2)..Char(6));
/// assert_eq!(fizz.to_string(), "Fizz");
/// ```
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
    ///
    /// # Example
    ///
    /// ```
    /// use notemaps_text::Immutable;
    ///
    /// let s: Immutable = "example".into();
    /// assert_eq!(s.to_string(), "example");
    /// ```
    pub fn new(buffer: B) -> Self {
        let byte_range = Byte(0)..Byte(buffer.borrow().len());
        Self { buffer, byte_range }
    }

    /// Creates a new immutable string based on `byte_range` within `buffer`.
    ///
    /// Slices of the resulting value will share the same underlying buffer.
    ///
    /// # Example
    ///
    /// ```
    /// use notemaps_text::Immutable;
    ///
    /// let s: Immutable = "example".into();
    /// assert_eq!(s.to_string(), "example");
    /// ```
    pub fn new_with_range(buffer: B, byte_range: Range<Byte>) -> Self {
        assert!(byte_range.start <= byte_range.end && byte_range.end.0 <= buffer.borrow().len());
        Self { buffer, byte_range }
    }

    /// Returns a reference to the [str] representation of this immutable string.
    ///
    /// # Example
    ///
    /// ```
    /// use notemaps_text::Immutable;
    ///
    /// let s: Immutable = "example".into();
    /// assert_eq!(s.as_str(), "example");
    /// ```
    pub fn as_str(&self) -> &str {
        &self.buffer.borrow()[self.byte_range.start.0..self.byte_range.end.0]
    }
}

// Constructor traits:

impl<'a, B> From<&'a str> for Immutable<B>
where
    B: Borrow<str> + From<&'a str>,
{
    fn from(s: &'a str) -> Self {
        Self::new(B::from(s))
    }
}

// Accessor traits:

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

impl<B> fmt::Display for Immutable<B>
where
    B: Borrow<str>,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.as_str().fmt(f)
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

// Equality and comparison traits:
//
// These have to be implemented explicitly for [Immutable].
//
// Derived implementations of these traits would examine the entire shared buffer rather than just
// the portion selected by [Immutable::byte_range]. This would make [Immutable] a poor example of a
// [String]-like type: for example, the resulting equality/comparison results would be incompatible
// with the requirements of implementing `Borrow<str>`.

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
