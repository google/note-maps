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
use std::hash::{Hash, Hasher};
use std::ops;
use std::ops::Range;

/// The `offsets` module contains minimalist wrappers for numeric types that are helpful when
/// a function definition must do simple arithmetic with more than one unit of measurement.
///
/// Many bugs can be prevented by wrapping a measurement in a type that indicate the unit of the
/// measurement. Some such bugs were caught while implementing this crate!
///
/// How long is the string `a̐`? It looks like one character so it's just one grapheme. However,
/// it's expressed in _two_ Unicode code points. The UTF-8 encoded representation of these two code
/// points is _three_ bytes long.
///
/// # Examples
///
/// ```rust
/// use notemaps_core::offsets::{Byte, Char, Grapheme};
/// use notemaps_core::IndexStr;
///
/// let graphme_3 = Grapheme(1) + Grapheme(2);
/// assert_eq!(graphme_3.0, 3usize);
///
/// let char_4 = Char(7) - Char(3);
/// assert_eq!(char_4.0, 4usize);
/// ```
pub mod offsets {
    use std::borrow::Borrow;
    use std::fmt;
    use std::iter;
    use std::ops::*;

    macro_rules! numeric_singleton {
        ($(#[$outer:meta])* $pub:vis struct $tuple:ident ($type:ident)) => {
            $(#[$outer])*
            #[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Hash, Ord, PartialOrd)]
            $pub struct $tuple (pub $type);
            impl From<usize> for $tuple {
                fn from(src: usize) -> Self {
                    $tuple(src)
                }
            }
            impl Add for $tuple {
                type Output = Self;
                fn add(self, other: Self) -> Self {
                    Self(self.0 + other.0)
                }
            }
            impl Sub for $tuple {
                type Output = Self;
                fn sub(self, other: Self) -> Self {
                    Self(self.0 - other.0)
                }
            }
            impl Borrow<$type> for $tuple {
                fn borrow(&self) -> &$type { &self.0 }
            }
            impl iter::Step for $tuple {
                fn steps_between(start: &Self, end: &Self) -> Option<usize> {
                    iter::Step::steps_between(&start.0, &end.0)
                }
                fn forward_checked(x:Self, count: usize) -> Option<Self> {
                    Some($tuple(iter::Step::forward_checked(x.0, count)?))
                }
                fn backward_checked(x:Self, count: usize) -> Option<Self> {
                    Some($tuple(iter::Step::backward_checked(x.0, count)?))
                }
            }
        };
    }

    numeric_singleton! {
        /// Represents a number of [u8] bytes or octets, typically in the context of some UTF-8
        /// encoded text.
        ///
        /// Intended to help avoid bugs caused by unintentionally mixing measurements of different
        /// units in an arithmetic expression.
        ///
        /// # Example
        ///
        /// ```rust
        /// use notemaps_core::offsets::Byte;
        ///
        /// assert_eq!((Byte(1) + Byte(2)).0, 3);
        /// // let byte_3 = Byte(1) + Grapheme(2); // does not compile!
        /// ```
        pub struct Byte(usize)
    }

    numeric_singleton! {
        /// Represents a number of [char] characters, or Unicode code points.
        ///
        /// Intended to help avoid bugs caused by unintentionally mixing measurements of different
        /// units in an arithmetic expression.
        ///
        /// # Example
        ///
        /// ```rust
        /// use notemaps_core::offsets::Char;
        ///
        /// assert_eq!((Char(1) + Char(2)).0, 3);
        /// // let char_3 = Char(1) + Byte(2); // does not compile!
        /// ```
        pub struct Char(usize)
    }

    numeric_singleton! {
        /// Represents a number of graphemes, or user-perceived characters.
        ///
        /// Intended to help avoid bugs caused by unintentionally mixing measurements of different
        /// units in an arithmetic expression.
        ///
        /// # Example
        ///
        /// ```rust
        /// use notemaps_core::offsets::Grapheme;
        ///
        /// assert_eq!((Grapheme(1) + Grapheme(2)).0, 3);
        /// // let grapheme_3 = Graphme(1) + Byte(2); // does not compile!
        /// ```
        pub struct Grapheme(usize)
    }

    mod internal {
        pub trait Sealed {}
        impl Sealed for super::Byte {}
        impl Sealed for super::Char {}
        impl Sealed for super::Grapheme {}
    }

    /// A public trait implemented exclusively by the offset unit types in this module: [Byte],
    /// [Char], and [Grapheme].
    pub trait Offset:
        Copy
        + Eq
        + Ord
        + From<usize>
        + fmt::Debug
        + Add<Output = Self>
        + Sub<Output = Self>
        + Borrow<usize>
        + internal::Sealed
    {
        const ZERO: Self;
        fn offset_len(s: &str) -> Self;
        fn next_byte<'a>(s: &'a str) -> Option<Byte>;
        fn get_slice<'a>(s: &'a str, range: Range<Self>) -> &'a str;
    }

    impl Offset for Byte {
        const ZERO: Self = Self(0);

        fn offset_len(s: &str) -> Byte {
            Byte(str::len(s))
        }

        fn next_byte<'a>(s: &'a str) -> Option<Byte> {
            if s.is_empty() {
                None
            } else {
                Some(Byte(1))
            }
        }

        fn get_slice<'a>(s: &'a str, range: Range<Self>) -> &'a str {
            &s[range.start.0..range.end.0]
        }
    }

    impl Offset for Char {
        const ZERO: Self = Self(0);

        fn offset_len(s: &str) -> Char {
            Char(s.char_indices().count())
        }

        fn next_byte<'a>(s: &'a str) -> Option<Byte> {
            s.char_indices().next().map(|t| Byte(t.0))
        }

        fn get_slice<'a>(s: &'a str, range: Range<Self>) -> &'a str {
            Byte::get_slice(s, s.try_to_byte_offsets(range).unwrap())
        }
    }

    impl Offset for Grapheme {
        const ZERO: Self = Self(0);

        fn offset_len(s: &str) -> Grapheme {
            use unicode_segmentation::UnicodeSegmentation;
            Grapheme(s.grapheme_indices(/*extended=*/ true).count())
        }

        fn next_byte<'a>(s: &'a str) -> Option<Byte> {
            use unicode_segmentation::UnicodeSegmentation;
            s.grapheme_indices(/*extended=*/ true)
                .next()
                .map(|t| Byte(t.0))
        }

        fn get_slice<'a>(s: &'a str, range: Range<Self>) -> &'a str {
            Byte::get_slice(s, s.try_to_byte_offsets(range).unwrap())
        }
    }

    /// A type that describes the same offset in multiple measurements.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use notemaps_core::offsets::*;
    ///
    /// let length: Offsets = "a̐éö̲\r\n".into();
    /// assert_eq!(Grapheme(4), *length.as_ref());
    /// assert_eq!(Char(9), *length.as_ref());
    /// assert_eq!(Byte(13), *length.as_ref());
    /// ```
    #[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Hash)]
    pub struct Offsets(Byte, Char, Grapheme);

    impl<'a> From<&'a str> for Offsets {
        fn from(s: &'a str) -> Self {
            Self(
                Byte::offset_len(s),
                Char::offset_len(s),
                Grapheme::offset_len(s),
            )
        }
    }

    impl<'a> From<&'a super::MeasuredStr> for Offsets {
        fn from(s: &'a super::MeasuredStr) -> Self {
            Self(
                super::MeasuredStr::offset_len(s),
                super::MeasuredStr::offset_len(s),
                super::MeasuredStr::offset_len(s),
            )
        }
    }

    impl Add for Offsets {
        type Output = Self;

        fn add(self, other: Self) -> Self {
            Self(self.0 + other.0, self.1 + other.1, self.2 + other.2)
        }
    }

    impl AsRef<Byte> for Offsets {
        fn as_ref(&self) -> &Byte {
            &self.0
        }
    }

    impl AsRef<Char> for Offsets {
        fn as_ref(&self) -> &Char {
            &self.1
        }
    }

    impl AsRef<Grapheme> for Offsets {
        fn as_ref(&self) -> &Grapheme {
            &self.2
        }
    }

    /// An [std::error::Error] type that can be returned in [Result::Err] from methods that might
    /// receive an offset that is out of bounds.
    ///
    /// # Example
    ///
    /// ```rust
    /// use notemaps_core::offsets::*;
    ///
    /// fn get_byte_offset(s: &str, chars: Char) -> Result<usize, OffsetOutOfBoundsError<Char>> {
    ///     s.char_indices().nth(chars.0).map(|t|t.0).ok_or(chars.into())
    /// }
    /// ```
    #[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
    pub struct OffsetOutOfBoundsError<O: Copy + Eq + fmt::Debug> {
        max: Option<O>,
        arg: O,
    }

    impl<O: Copy + Eq + fmt::Debug> OffsetOutOfBoundsError<O> {
        #[must_use]
        pub fn with_max(mut self, max: O) -> Self {
            self.max = Some(max);
            self
        }
    }

    impl<O: Copy + Eq + fmt::Debug> From<O> for OffsetOutOfBoundsError<O> {
        fn from(arg: O) -> Self {
            Self { arg, max: None }
        }
    }

    impl<O: Copy + Eq + fmt::Debug> fmt::Display for OffsetOutOfBoundsError<O> {
        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> Result<(), fmt::Error> {
            match self.max {
                Some(max) => write!(
                    f,
                    "offset {:?} is out of bounds for a string of length {:?}",
                    self.arg, max
                ),
                None => write!(f, "offset {:?} is out of bounds", self.arg),
            }
        }
    }

    /// The [Iterator] type returned by [StrExt::byte_offsets] for `StrExt<Char>` and
    /// `StrExt<Grapheme>`.
    pub struct ByteOffsets<I: Iterator<Item = (usize, X)>, X>(I, iter::Once<usize>);

    impl<I: Iterator<Item = (usize, X)>, X> ByteOffsets<I, X> {
        fn new(iter: I, len: usize) -> Self {
            Self(iter, iter::once(len))
        }
    }

    impl<I: Iterator<Item = (usize, X)>, X> Iterator for ByteOffsets<I, X> {
        type Item = Byte;
        fn next(&mut self) -> Option<Byte> {
            self.0
                .next()
                .map(|t| t.0)
                .or_else(|| self.1.next())
                .map(Into::into)
        }
    }

    /// An associated types trait for [StrExt].
    pub trait StrExtTypes<'a, O: Offset> {
        type ByteOffsets: Iterator<Item = Byte>;
    }

    /// [StrExt] can be implemented for any type that represents UTF-8 encoded text.
    ///
    /// Implementations must be able to convert any [RangeBounds] type with offsets of type `O` to
    /// a simple [Range] value with offsets of type [Byte]. In the general case, and for `O` types
    /// other than [Byte], this must always be done within the context of the contents of the
    /// implementation.
    ///
    /// An implementation for [str] is provided for each of the [Offset] types: [Byte], [Char], and
    /// [Grapheme].
    ///
    /// # Panics
    ///
    /// [StrExt::try_to_byte_offsets] implementations _should_ safely return an error when
    /// given offsets beyond the length of the contained text. However, some implementations may
    /// panic.
    ///
    /// NOTE: The implementation provided for [str] may panic instead of returning an error for
    /// some arguments, but this is a bug to be fixed.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use notemaps_core::offsets::StrExt;
    /// use notemaps_core::offsets::*;
    ///
    /// let hello = "👋🏻";
    /// assert_eq!(hello.try_to_byte_offsets(..Char(1)), Ok(Byte(0)..Byte(4)));
    /// assert_eq!(hello.try_to_byte_offsets(..Grapheme(1)), Ok(Byte(0)..Byte(8)));
    /// ```
    pub trait StrExt<O: Offset>
    where
        for<'a> &'a Self: StrExtTypes<'a, O>,
    {
        /// Returns an iterator over all byte offsets that delimit `O` units within the [str]-like
        /// value `self`.
        ///
        /// Implementations must include:
        ///
        /// 1. The initial (zero) offset that marks the beginning of the first unit.
        /// 1. Each offset that separates one unit from the next.
        /// 1. The final offset that marks the end of the last unit, or zero if the string is empty.
        ///
        /// Following the above, for an empty string this method should return an iterator that
        /// finds only one (zero) value, indicating the byte offset of the end of the string.
        fn byte_offsets<'a>(&'a self) -> <&'a Self as StrExtTypes<'a, O>>::ByteOffsets;

        /// Returns the byte offset at the beginning of the `O` unit at `offset` in `self`.
        fn try_byte_offset_at(&self, offset: O) -> Result<Byte, OffsetOutOfBoundsError<O>> {
            self.byte_offsets()
                .nth(*offset.borrow())
                .ok_or(offset.into())
        }

        /// Returns the length of [str]-like value `self`, measured in `O` units.
        fn max_offset(&self) -> O {
            (self.byte_offsets().count() - 1).into()
        }

        fn try_to_byte_offsets<R: RangeBounds<O>>(
            &self,
            range: R,
        ) -> Result<Range<Byte>, OffsetOutOfBoundsError<O>> {
            use std::ops::Bound::*;
            let mut bytes = self.byte_offsets();
            let offset_0 = match range.start_bound() {
                Included(offset) => *offset,
                Excluded(offset) => *offset + 1.into(),
                Unbounded => O::ZERO,
            };
            let byte_0 = bytes.by_ref().nth(*offset_0.borrow()).unwrap();
            let byte_n = match range.end_bound() {
                Included(_offset) => todo!("range to inclusive end bound"),
                Excluded(offset) => {
                    let mut bytes = iter::once(byte_0).chain(bytes);
                    bytes.nth(*(*offset - offset_0).borrow()).unwrap()
                }
                Unbounded => bytes.last().unwrap_or(byte_0),
            };
            Ok(byte_0..byte_n)
        }
    }

    impl<'a> StrExtTypes<'a, Byte> for &'a str {
        type ByteOffsets = Range<Byte>;
    }

    impl StrExt<Byte> for str {
        fn byte_offsets<'a>(&'a self) -> <&'a Self as StrExtTypes<'a, Byte>>::ByteOffsets {
            Byte(0)..Byte(self.len() + 1)
        }

        fn max_offset(&self) -> Byte {
            Byte(self.len())
        }

        fn try_to_byte_offsets<R: RangeBounds<Byte>>(
            &self,
            range: R,
        ) -> Result<Range<Byte>, OffsetOutOfBoundsError<Byte>> {
            use std::ops::Bound::*;
            let start = match range.start_bound() {
                Included(offset) => *offset,
                Excluded(offset) => *offset + Byte(1),
                Unbounded => Byte(0),
            };
            let end = match range.end_bound() {
                Included(offset) => *offset + Byte(1),
                Excluded(offset) => *offset,
                Unbounded => Byte(self.len()),
            };
            Ok(start..end)
        }
    }

    impl<'a> StrExtTypes<'a, Char> for &'a str {
        type ByteOffsets = ByteOffsets<std::str::CharIndices<'a>, char>;
    }

    impl StrExt<Char> for str {
        fn byte_offsets<'a>(&'a self) -> <&'a Self as StrExtTypes<'a, Char>>::ByteOffsets {
            ByteOffsets::new(self.char_indices(), self.len())
        }
    }

    impl<'a> StrExtTypes<'a, Grapheme> for &'a str {
        type ByteOffsets = ByteOffsets<unicode_segmentation::GraphemeIndices<'a>, &'a str>;
    }

    impl StrExt<Grapheme> for str {
        fn byte_offsets<'a>(&'a self) -> <&'a Self as StrExtTypes<'a, Grapheme>>::ByteOffsets {
            use unicode_segmentation::UnicodeSegmentation;
            ByteOffsets::new(self.grapheme_indices(/*extended=*/ true), self.len())
        }
    }

    /// The [Iterator] type returned by [IntoGraphemeOffsetIterator::byte_offsets] as implemented
    /// for `&str`.
    #[derive(Clone)]
    pub struct GraphemeBoundaries<'a>(unicode_segmentation::GraphemeIndices<'a>, iter::Once<Byte>);

    impl<'a> GraphemeBoundaries<'a> {}

    impl<'a> Iterator for GraphemeBoundaries<'a> {
        type Item = Byte;
        fn next(&mut self) -> Option<Self::Item> {
            self.0.next().map(|t| Byte(t.0)).or(self.1.next())
        }
        fn advance_by(&mut self, n: usize) -> Result<(), usize> {
            self.0.advance_by(n)
        }
    }

    impl<'a> DoubleEndedIterator for GraphemeBoundaries<'a> {
        fn next_back(&mut self) -> Option<Self::Item> {
            self.1
                .next()
                .or_else(|| self.0.next_back().map(|t| Byte(t.0)))
        }
        fn advance_back_by(&mut self, n: usize) -> Result<(), usize> {
            match self.1.advance_by(n) {
                Ok(_) => Ok(()),
                Err(one) => self.0.advance_back_by(n - one),
            }
        }
    }

    pub trait IntoGraphemeOffsetIterator {
        type IntoGraphemeOffsets: Iterator<Item = Byte>;
        //+ DoubleEndedIterator
        //+ Clone
        //+ Into<Self>;

        fn into_grapheme_offsets(self) -> Self::IntoGraphemeOffsets;

        fn into_grapheme_len(self) -> Grapheme
        where
            Self: Sized, // TODO: remove this constraint (or find out why it can't be removed.)
            Self::IntoGraphemeOffsets: ExactSizeIterator,
        {
            self.into_grapheme_offsets().len().into()
        }

        fn into_grapheme_slice(self, range: Range<Grapheme>) -> Self::IntoGraphemeOffsets
        where
            Self: Sized, // TODO: remove this constraint (or find out why it can't be removed.)
            Self::IntoGraphemeOffsets: ExactSizeIterator + DoubleEndedIterator,
        {
            let (skip_front, len): (usize, usize) = (*range.start.borrow(), *range.end.borrow());
            let mut iter = self.into_grapheme_offsets();
            iter.advance_by(skip_front).unwrap();
            iter.advance_back_by(iter.len() - len).ok();
            iter
        }
    }

    impl<'a> IntoGraphemeOffsetIterator for &'a str {
        type IntoGraphemeOffsets = GraphemeBoundaries<'a>;

        fn into_grapheme_offsets(self) -> Self::IntoGraphemeOffsets {
            use unicode_segmentation::UnicodeSegmentation;
            GraphemeBoundaries(
                self.grapheme_indices(/*extended=*/ true),
                iter::once(Byte(self.len())),
            )
        }
    }

    impl<'a> From<GraphemeBoundaries<'a>> for &'a str {
        fn from(iter: GraphemeBoundaries<'a>) -> Self {
            iter.0.as_str()
        }
    }

    #[cfg(test)]
    mod any_str {
        use super::Byte;
        use super::IntoGraphemeOffsetIterator;

        #[test]
        fn can_be_converted_into_a_sequence_of_graphemes() {
            let text = "a̐éö̲\r\n";
            assert_eq!(text.into_grapheme_offsets().next(), Some(Byte(0)));
            assert_eq!(text.into_grapheme_offsets().nth(0), Some(Byte(0)));
            assert_eq!(text.into_grapheme_offsets().nth(1), Some(Byte(3)));
            assert_eq!(text.into_grapheme_offsets().nth(2), Some(Byte(6)));
            assert_eq!(text.into_grapheme_offsets().nth(3), Some(Byte(11)));
            assert_eq!(text.into_grapheme_offsets().nth(4), Some(Byte(13)));
            assert_eq!(text.into_grapheme_offsets().nth(5), None);
        }

        #[test]
        fn can_be_converted_into_a_double_ended_sequence_of_graphemes() {
            let text = "a̐éö̲\r\n";
            assert_eq!(text.into_grapheme_offsets().nth_back(0), Some(Byte(13)));
            assert_eq!(text.into_grapheme_offsets().nth_back(1), Some(Byte(11)));
            assert_eq!(text.into_grapheme_offsets().nth_back(2), Some(Byte(6)));
            assert_eq!(text.into_grapheme_offsets().nth_back(3), Some(Byte(3)));
            assert_eq!(text.into_grapheme_offsets().nth_back(4), Some(Byte(0)));
            assert_eq!(text.into_grapheme_offsets().nth_back(5), None);
        }

        #[test]
        fn can_be_reconstructed_from_a_sequence_of_graphemes() {
            let text = "a̐éö̲\r\n";
            let mut iter = text.into_grapheme_offsets();
            iter.by_ref().advance_by(1).unwrap();
            let slice: &str = iter.into();
            assert_eq!(slice, "éö̲\r\n");
        }
    }
}

use offsets::*;

/// Wraps [str] to implement [ops::Index] for [std::ops::RangeBounds] for the [Offset] types
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
/// use notemaps_core::offsets::{Byte, Char, Grapheme};
/// use notemaps_core::IndexStr;
///
/// let example = IndexStr::from("a̐a̐");
/// assert_eq!(&example[Grapheme(1)..Grapheme(2)], "a̐");
/// assert_eq!(&example[Char(2)..Char(4)], "a̐");
/// assert_eq!(&example[Byte(3)..Byte(6)], "a̐");
/// ```
#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub struct IndexStr<T: Borrow<str>>(T);

impl<T: Borrow<str>> IndexStr<T> {
    /// Returns the wrapped `T`, consuming self.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use notemaps_core::IndexStr;
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

impl<O: Offset, T: Borrow<str>> ops::Index<Range<O>> for IndexStr<T> {
    type Output = str;

    fn index(&self, range: Range<O>) -> &str {
        O::get_slice(self.0.borrow(), range)
    }
}

impl<T: Borrow<str>> From<T> for IndexStr<T> {
    fn from(src: T) -> Self {
        Self(src)
    }
}

impl<T: Borrow<str>> Copy for IndexStr<T> where T: Copy {}

impl<T: Borrow<str>> Hash for IndexStr<T> {
    fn hash<H>(&self, state: &mut H)
    where
        H: Hasher,
    {
        self.0.borrow().hash(state)
    }
}

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
    use super::offsets::*;
    use super::IndexStr;

    #[test]
    fn measures_its_own_length() {
        use super::offsets::StrExt;
        let s = "a̐éö̲\r\n";
        let (bytes, chars, graphemes): (Byte, Char, Grapheme) =
            (s.max_offset(), s.max_offset(), s.max_offset());
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

use std::sync::Arc;

/// Wraps a [str] and, upon construction, computes its total length in [Offsets].
///
/// Computing the length of a string in [Offsets] can be expensive: the time complexity is linear
/// to the length of the string. This cost is paid once in the construction of [MeasuredStr] so
/// that it does not need to paid again every time the length of the string is needed.
///
/// As a cheap way to keep the computed length up to date, the wrapped [str] is immutable. To
/// protect this invariant, [MeasuredStr] does not allow customizing the type used to represent a
/// string the way [IndexStr] does.
///
/// # Examples
///
/// ```rust
/// use notemaps_core::MeasuredStr;
/// use notemaps_core::offsets::{Char, Grapheme};
///
/// let s: MeasuredStr = "a̐éö̲\r\n".into();
/// assert_eq!(Char(9), s.offset_len());
/// assert_eq!(Grapheme(4), s.offset_len());
/// ```
#[derive(Clone, Debug)]
pub struct MeasuredStr {
    text: Arc<str>,
    len: Offsets,
}

impl MeasuredStr {
    fn inner_new(text: Arc<str>, len: Offsets) -> Self {
        Self { len, text }
    }

    /// Returns the length of the wrapped [str].
    ///
    /// The [str] is immutable so that the length does not need to be re-computed. It is wrapped in an
    /// [Arc] for cheap, thread-safe cloning.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use notemaps_core::MeasuredStr;
    /// use notemaps_core::offsets::{Char, Grapheme};
    ///
    /// let s: MeasuredStr = "a̐éö̲\r\n".into();
    /// assert_eq!(Char(9), s.offset_len());
    /// assert_eq!(Grapheme(4), s.offset_len());
    /// ```
    pub fn offset_len<O: Offset>(&self) -> O
    where
        Offsets: AsRef<O>,
    {
        *self.len.as_ref()
    }

    /// Wraps a [str] and computes its total length in [Offsets] on construction.
    ///
    /// The [str] is immutable so that the length does not need to be re-computed. It is wrapped in an
    /// [Arc] for cheap, thread-safe cloning.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use notemaps_core::MeasuredStr;
    /// use notemaps_core::offsets::{Char, Grapheme};
    ///
    /// let s: MeasuredStr = "a̐éö̲\r\n".into();
    /// assert_eq!(Char(9), s.offset_len());
    /// assert_eq!(Grapheme(4), s.offset_len());
    /// ```
    pub fn as_str(&self) -> &str {
        self.text.borrow()
    }

    pub fn to_index_str(&self) -> IndexStr<Arc<str>> {
        IndexStr(self.text.clone())
    }

    pub fn to_arc_str(self) -> Arc<str> {
        self.text.clone()
    }
}

impl From<&'a str> for MeasuredStr {
    fn from(text: &'a str) -> Self {
        Self::inner_new(Arc::from(text), Offsets::from(text))
    }
}

impl AsRef<str> for MeasuredStr {
    fn as_ref(&self) -> &str {
        self.as_str()
    }
}

impl Borrow<str> for MeasuredStr {
    fn borrow(&self) -> &str {
        self.as_str()
    }
}

#[cfg(test)]
mod a_measured_str {
    use super::*;

    #[test]
    fn reports_its_length_accurately() {
        let s: MeasuredStr = "a̐éö̲\r\n".into();
        assert_eq!(Byte(13), s.offset_len());
        assert_eq!(Char(9), s.offset_len());
        assert_eq!(Grapheme(4), s.offset_len());
    }
}
