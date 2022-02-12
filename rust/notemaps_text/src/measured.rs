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

use std::borrow::Borrow;
use std::ops::Range;

use crate::offsets::*;
use crate::*;

/// Wraps a [str] and, upon construction, computes its total length in [Locus].
///
/// Computing the length of a string in [Locus] can be expensive: the time complexity is linear
/// to the length of the string. This cost is paid once in the construction of [Measured] so
/// that it does not need to paid again every time the length of the string is needed.
///
/// As a cheap way to keep the computed length up to date, the wrapped [str] is immutable. To
/// protect this invariant, [Measured] does not allow customizing the type used to represent a
/// string the way [IndexStr] does.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::Measured;
/// use notemaps_text::offsets::{Char, Grapheme};
///
/// let s: Measured = "a̐éö̲\r\n".into();
/// assert_eq!(Char(9), s.len());
/// assert_eq!(Grapheme(4), s.len());
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub struct Measured<S = Immutable> {
    text: S,
    len: Locus,
}

impl<S: Borrow<str>> Measured<S> {
    pub fn new(text: S) -> Self
    where
        S: Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    {
        let len = Locus::from_len(&text.borrow());
        Self { text, len }
    }

    /// Returns the length of the wrapped [str].
    ///
    /// The [str] is immutable so that the length does not need to be re-computed. It is wrapped in an
    /// [Arc] for cheap, thread-safe cloning.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use notemaps_text::Measured;
    /// use notemaps_text::offsets::{Char, Grapheme};
    ///
    /// let s: Measured = "a̐éö̲\r\n".into();
    /// assert_eq!(Char(9), s.len());
    /// assert_eq!(Grapheme(4), s.len());
    /// ```
    pub fn len<U>(&self) -> U
    where
        U: Clone,
        Locus: AsRef<U>,
    {
        self.len.as_ref().clone()
    }

    /// Wraps a [str] and computes its total length in [Locus] on construction.
    ///
    /// The [str] is immutable so that the length does not need to be re-computed. It is wrapped in an
    /// [Arc] for cheap, thread-safe cloning.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use notemaps_text::Measured;
    /// use notemaps_text::offsets::{Char, Grapheme};
    ///
    /// let s: Measured = "a̐éö̲\r\n".into();
    /// assert_eq!(Char(9), s.len());
    /// assert_eq!(Grapheme(4), s.len());
    /// ```
    pub fn as_str(&self) -> &str {
        self.text.borrow()
    }
}

impl<'a, S> From<&'a str> for Measured<S>
where
    S: Borrow<str> + From<&'a str> + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
{
    fn from(s: &'a str) -> Self {
        Self::new(S::from(s))
    }
}

impl<S> AsRef<S> for Measured<S> {
    fn as_ref(&self) -> &S {
        &self.text
    }
}

impl<S> Borrow<str> for Measured<S>
where
    S: Borrow<str>,
{
    fn borrow(&self) -> &str {
        self.text.borrow()
    }
}

impl<S, U> Slice<U> for Measured<S>
where
    S: Borrow<str> + Slice<U> + Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    U: Unit,
{
    fn len(&self) -> U {
        self.text.len()
    }
    fn slice(&self, r: Range<U>) -> Self {
        // TODO: avoid re-computing the length of the slice
        Self::new(self.text.slice(r))
    }
}

#[cfg(test)]
mod a_measured_str {
    use super::*;
    use std::rc::Rc;

    #[test]
    fn reports_its_length_accurately() {
        let s = Measured::new(Immutable::new(Rc::from("a̐éö̲\r\n")));
        assert_eq!(Byte(13), s.len());
        assert_eq!(Char(9), s.len());
        assert_eq!(Grapheme(4), s.len());
    }
}
