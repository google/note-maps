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
use std::ops;
use std::ops::Range;

use crate::offsets::*;

/// Wraps [str] to implement [ops::Index] for [std::ops::RangeBounds] for the [Unit] types
/// [Byte], [Char], and [Grapheme].
///
/// NOTE: [IndexStr] is less than ideal for large strings as the time complexity of
/// [ops::Index::index] is linear to the length of the string. See other types in this crate for
/// ideas about how large strings can be split into pieces, and how this can improve performance.
///
/// # Panics
///
/// Like most implementations of [ops::Index], [IndexStr] will panic if given out-of-bounds offsets.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::offsets::{Byte, Char, Grapheme};
/// use notemaps_text::IndexStr;
///
/// let example = IndexStr::from("a̐a̐");
/// assert_eq!(&example[Grapheme(1)..Grapheme(2)], "a̐");
/// assert_eq!(&example[Char(2)..Char(4)], "a̐");
/// assert_eq!(&example[Byte(3)..Byte(6)], "a̐");
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub struct IndexStr<T: Borrow<str>>(T);

impl<T: Borrow<str>> IndexStr<T> {
    /// Returns the wrapped `T`, consuming self.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use notemaps_text::IndexStr;
    ///
    /// let input: String = "some string".into();
    /// let text: IndexStr<_> = input.into();
    /// assert_eq!(text.as_ref().as_str(), "some string");
    /// // Do some work that benefits from IndexStr's implementation of ops::Index...
    /// let input: String = text.unwrap();
    /// assert_eq!(input.as_str(), "some string");
    /// ```
    pub fn unwrap(self) -> T {
        self.0
    }
}

impl<U: Unit, T: Borrow<str>> ops::Index<Range<U>> for IndexStr<T> {
    type Output = str;

    fn index(&self, range: Range<U>) -> &str {
        U::get_slice(self.0.borrow(), range)
    }
}

impl<T: Borrow<str>> From<T> for IndexStr<T> {
    fn from(src: T) -> Self {
        Self(src)
    }
}

impl<T: Borrow<str>> Copy for IndexStr<T> where T: Copy {}

impl<T: Borrow<str>> PartialEq<str> for IndexStr<T> {
    fn eq(&self, other: &str) -> bool {
        self.0.borrow() == other
    }
}

impl<T: Borrow<str>> Borrow<T> for IndexStr<T> {
    fn borrow(&self) -> &T {
        &self.0
    }
}

impl<T: Borrow<str>> AsRef<T> for IndexStr<T> {
    fn as_ref(&self) -> &T {
        &self.0
    }
}

#[cfg(test)]
mod a_str {
    use super::IndexStr;
    use crate::offsets::*;

    #[test]
    fn measures_its_own_length() {
        use crate::offsets::Unit;
        let s = "a̐éö̲\r\n";
        let (bytes, chars, graphemes): (Byte, Char, Grapheme) = (
            Unit::offset_len(s),
            Unit::offset_len(s),
            Unit::offset_len(s),
        );
        assert_eq!(bytes, Byte(13));
        assert_eq!(chars, Char(9));
        assert_eq!(graphemes, Grapheme(4));
    }

    #[test]
    fn can_be_indexed_by_bytes() {
        let s = IndexStr("a̐éö̲\r\n");
        assert_eq!(&s[Byte(0)..Byte(0)], "");
        assert_eq!(&s[Byte(0)..Byte(1)], "a");
        assert_eq!(&s[Byte(0)..Byte(3)], "a̐");
        assert_eq!(&s[Byte(0)..Byte(4)], "a̐e");
        assert_eq!(&s[Byte(0)..Byte(6)], "a̐é");
        assert_eq!(&s[Byte(0)..Byte(7)], "a̐éo");
        assert_eq!(&s[Byte(0)..Byte(11)], "a̐éö̲");
        assert_eq!(&s[Byte(0)..Byte(12)], "a̐éö̲\r");
        assert_eq!(&s[Byte(0)..Byte(13)], "a̐éö̲\r\n");
        assert_eq!(&s[Byte(3)..Byte(13)], "éö̲\r\n");
        assert_eq!(&s[Byte(6)..Byte(13)], "ö̲\r\n");
        assert_eq!(&s[Byte(11)..Byte(13)], "\r\n");
        assert_eq!(&s[Byte(12)..Byte(13)], "\n");
        assert_eq!(&s[Byte(13)..Byte(13)], "");
    }

    #[test]
    fn can_be_indexed_by_chars() {
        let s = IndexStr("a̐éö̲\r\n");
        assert_eq!(&s[Char(0)..Char(0)], "");
        assert_eq!(&s[Char(0)..Char(2)], "a̐");
        assert_eq!(&s[Char(0)..Char(4)], "a̐é");
        assert_eq!(&s[Char(0)..Char(7)], "a̐éö̲");
        assert_eq!(&s[Char(0)..Char(8)], "a̐éö̲\r");
        assert_eq!(&s[Char(0)..Char(9)], "a̐éö̲\r\n");
        assert_eq!(&s[Char(2)..Char(9)], "éö̲\r\n");
        assert_eq!(&s[Char(4)..Char(9)], "ö̲\r\n");
        assert_eq!(&s[Char(7)..Char(9)], "\r\n");
        assert_eq!(&s[Char(8)..Char(9)], "\n");
        assert_eq!(&s[Char(9)..Char(9)], "");
    }

    #[test]
    fn can_be_indexed_by_graphemes() {
        let s = IndexStr("a̐éö̲\r\n");
        assert_eq!(&s[Grapheme(0)..Grapheme(0)], "");
        assert_eq!(&s[Grapheme(0)..Grapheme(1)], "a̐");
        assert_eq!(&s[Grapheme(0)..Grapheme(2)], "a̐é");
        assert_eq!(&s[Grapheme(0)..Grapheme(3)], "a̐éö̲");
        assert_eq!(&s[Grapheme(0)..Grapheme(4)], "a̐éö̲\r\n");
        assert_eq!(&s[Grapheme(1)..Grapheme(4)], "éö̲\r\n");
        assert_eq!(&s[Grapheme(2)..Grapheme(4)], "ö̲\r\n");
        assert_eq!(&s[Grapheme(3)..Grapheme(4)], "\r\n");
        assert_eq!(&s[Grapheme(4)..Grapheme(4)], "");
    }
}

#[cfg(test)]
mod a_measured_str {
    use crate::offsets::*;
    use crate::*;
    use std::rc::Rc;

    #[test]
    fn reports_its_length_accurately() {
        let s = Measured::new(Immutable::new(Rc::from("a̐éö̲\r\n")));
        assert_eq!(Byte(13), s.len());
        assert_eq!(Char(9), s.len());
        assert_eq!(Grapheme(4), s.len());
    }
}
