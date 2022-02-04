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

//! The `offsets` module contains measurement unit types defined as singleton tuple wrappers around
//! primitive numeric types.
//!
//! Measurement unit types are helpful when one function definition or code block must do
//! arithmetic with two or more units of measurement, as when computing the length of a `str` in
//! graphemes, chars, or bytes.  Many bugs can be prevented by wrapping a measurement in a type
//! that indicate the unit of the measurement. Some were even caught while implementing this crate!
//!
//! How long is the string `a̐`? It looks like one character so it's just one grapheme. However,
//! it's expressed in _two_ Unicode code points. The UTF-8 encoded representation of these two code
//! points is _three_ bytes long.
//!
//! # Examples
//!
//! ```rust
//! use notemaps_text::offsets::{Byte, Char, Grapheme};
//! use notemaps_text::IndexStr;
//!
//! let graphme_3 = Grapheme(1) + Grapheme(2);
//! assert_eq!(graphme_3.0, 3usize);
//!
//! let char_4 = Char(7) - Char(3);
//! assert_eq!(char_4.0, 4usize);
//! ```

use std::borrow::Borrow;
use std::fmt;
use std::iter;
use std::ops::*;

macro_rules! natural_unit {
    (
        $(#[$outer:meta])* $pub:vis struct $tuple:ident ($type:ident)
        $plural:literal singular $singular:literal test $test_mod:ident;
    )  => {
        $(#[$outer])*
        #[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Hash, Ord, PartialOrd)]
        $pub struct $tuple (pub $type);

        impl From<usize> for $tuple {
            fn from(src: usize) -> Self {
                $tuple(src)
            }
        }

        impl core::ops::Add for $tuple {
            type Output = Self;
            fn add(self, other: Self) -> Self {
                Self(self.0 + other.0)
            }
        }

        impl core::ops::Add<$type> for $tuple {
            type Output = Self;
            fn add(self, other: $type) -> Self {
                Self(self.0 + other)
            }
        }

        impl core::ops::AddAssign for $tuple {
            fn add_assign(&mut self, other: Self) {
                self.0 += other.0
            }
        }

        impl core::ops::AddAssign<$type> for $tuple {
            fn add_assign(&mut self, other: $type) {
                self.0 += other
            }
        }
        impl core::ops::Sub for $tuple {
            type Output = Self;
            fn sub(self, other: Self) -> Self {
                Self(self.0 - other.0)
            }
        }
        impl core::ops::Sub<$type> for $tuple {
            type Output = Self;
            fn sub(self, other: $type) -> Self {
                Self(self.0 - other)
            }
        }
        impl core::ops::SubAssign for $tuple {
            fn sub_assign(&mut self, other: Self) {
                self.0 -= other.0
            }
        }

        impl core::ops::SubAssign<$type> for $tuple {
            fn sub_assign(&mut self, other: $type) {
                self.0 -= other
            }
        }

        impl core::ops::Mul<$type> for $tuple {
            type Output = Self;
            fn mul(self, other: $type) -> Self {
                Self(self.0 * other)
            }
        }

        impl core::ops::MulAssign<$type> for $tuple {
            fn mul_assign(&mut self, other: $type) {
                self.0 *= other
            }
        }

        impl std::iter::Sum<$tuple> for $tuple {
            fn sum<I>(iter: I) -> Self
            where I: Iterator<Item = $tuple>
            {
                Self(iter.map(|t|t.0).sum())
            }
        }

        impl AsRef<$type> for $tuple {
            fn as_ref(&self) -> &$type { &self.0 }
        }

        impl Borrow<$type> for $tuple {
            fn borrow(&self) -> &$type { &self.0 }
        }

        impl std::iter::Step for $tuple {
            fn steps_between(start: &Self, end: &Self) -> Option<usize> {
                std::iter::Step::steps_between(&start.0, &end.0)
            }
            fn forward_checked(x:Self, count: usize) -> Option<Self> {
                Some($tuple(std::iter::Step::forward_checked(x.0, count)?))
            }
            fn backward_checked(x:Self, count: usize) -> Option<Self> {
                Some($tuple(std::iter::Step::backward_checked(x.0, count)?))
            }
        }

        impl std::fmt::Display for $tuple {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> Result<(), fmt::Error> {
                self.0.fmt(f)?;
                if self.0 == 1 {
                    $singular.fmt(f)
                } else {
                    $plural.fmt(f)
                }
            }
        }

        #[cfg(test)]
        mod $test_mod {
            use super::$tuple;

            #[test]
            fn supports_addition_with_self(){
                assert_eq!($tuple(0)+$tuple(0), $tuple(0));
                assert_eq!($tuple(0)+$tuple(1), $tuple(1));
                assert_eq!($tuple(1)+$tuple(0), $tuple(1));
                assert_eq!($tuple($type::MAX-1)+$tuple(1), $tuple($type::MAX));
                assert_eq!($tuple(1)+$tuple($type::MAX-1), $tuple($type::MAX));
            }

            #[test]
            fn supports_addition_with_primitive_numeric(){
                assert_eq!($tuple(0)+0, $tuple(0));
                assert_eq!($tuple(0)+1, $tuple(1));
                assert_eq!($tuple(1)+0, $tuple(1));
                assert_eq!($tuple($type::MAX-1)+1, $tuple($type::MAX));
                assert_eq!($tuple(1)+($type::MAX-1), $tuple($type::MAX));
            }

            #[test]
            fn supports_addition_in_place(){
                let mut x=$tuple(0);
                x+=$tuple(1);
                assert_eq!(x, $tuple(1));
                x+=1;
                assert_eq!(x, $tuple(2));
                x+=$tuple($type::MAX-3);
                assert_eq!(x, $tuple($type::MAX-1));
                x+=1;
                assert_eq!(x, $tuple($type::MAX));
            }

            #[test]
            fn supports_subtraction_with_self(){
                assert_eq!($tuple(0)-$tuple(0), $tuple(0));
                assert_eq!($tuple(1)-$tuple(0), $tuple(1));
                assert_eq!($tuple($type::MAX)-$tuple(1), $tuple($type::MAX-1));
                assert_eq!($tuple($type::MAX)-$tuple($type::MAX-1), $tuple(1));
            }

            #[test]
            fn supports_subtraction_with_primitive_numeric(){
                assert_eq!($tuple(0)-0, $tuple(0));
                assert_eq!($tuple(1)-0, $tuple(1));
                assert_eq!($tuple($type::MAX)-1, $tuple($type::MAX-1));
                assert_eq!($tuple($type::MAX)-($type::MAX-1), $tuple(1));
            }

            #[test]
            fn supports_subtraction_in_place(){
                let mut x=$tuple($type::MAX);
                x -= $type::MAX-3;
                assert_eq!(x, $tuple(3));
                x -= $tuple(1);
                assert_eq!(x, $tuple(2));
            }

            #[test]
            fn supports_multiplication_with_primtive_numeric(){
                assert_eq!($tuple(0)*0, $tuple(0));
                assert_eq!($tuple(1)*0, $tuple(0));
                assert_eq!($tuple(1)*1, $tuple(1));
                assert_eq!($tuple(2)*($type::MAX/2), $tuple(2*($type::MAX/2)));
            }

            #[test]
            fn supports_multiplication_in_place(){
                let mut x = $tuple($type::MAX);
                x*=0;
                assert_eq!(x, $tuple(0));
                let mut x = $tuple(1);
                x *= 1;
                assert_eq!(x, $tuple(1));
                x *= $type::MAX;
                assert_eq!(x, $tuple($type::MAX));
            }

            #[test]
            fn can_be_used_in_a_range(){
                assert_eq!(
                    vec![$tuple(1), $tuple(2)],
                    ($tuple(1)..$tuple(3)).collect::<Vec<_>>());
                assert_eq!(
                    vec![$tuple(1), $tuple(2)],
                    ($tuple(1)..).take(2).collect::<Vec<_>>());
            }

            #[test]
            fn can_be_summed_across_a_sequence(){
                assert_eq!( $tuple(3), [$tuple(1), $tuple(2)].into_iter().sum() );
                assert_eq!( ($tuple(1)..).take(2).collect::<Vec<_>>(), vec![$tuple(1), $tuple(2)]);
            }
        }
    };
}

natural_unit! {
    /// Represents a number of [u8] bytes or octets, typically in the context of some UTF-8
    /// encoded text.
    ///
    /// Intended to help avoid bugs caused by unintentionally mixing measurements of different
    /// units in an arithmetic expression.
    ///
    /// # Example
    ///
    /// ```rust
    /// use notemaps_text::offsets::Byte;
    ///
    /// assert_eq!((Byte(1) + Byte(2)).0, 3);
    /// // let byte_3 = Byte(1) + Grapheme(2); // does not compile!
    /// ```
    pub struct Byte(usize) " bytes" singular " byte" test a_byte;
}

natural_unit! {
    /// Represents a number of [char] characters, or Unicode code points.
    ///
    /// Intended to help avoid bugs caused by unintentionally mixing measurements of different
    /// units in an arithmetic expression.
    ///
    /// # Example
    ///
    /// ```rust
    /// use notemaps_text::offsets::Char;
    ///
    /// assert_eq!((Char(1) + Char(2)).0, 3);
    /// // let char_3 = Char(1) + Byte(2); // does not compile!
    /// ```
    pub struct Char(usize)  " chars" singular " char" test a_char;
}

natural_unit! {
    /// Represents a number of graphemes, or user-perceived characters.
    ///
    /// Intended to help avoid bugs caused by unintentionally mixing measurements of different
    /// units in an arithmetic expression.
    ///
    /// # Example
    ///
    /// ```rust
    /// use notemaps_text::offsets::Grapheme;
    ///
    /// assert_eq!((Grapheme(1) + Grapheme(2)).0, 3);
    /// // let grapheme_3 = Graphme(1) + Byte(2); // does not compile!
    /// ```
    pub struct Grapheme(usize) " graphemes" singular " grapheme" test a_grapheme;
}

mod internal {
    pub trait Sealed {}
    impl Sealed for super::Byte {}
    impl Sealed for super::Char {}
    impl Sealed for super::Grapheme {}
}

/// A public trait implemented exclusively by the measurement unit types defined in this module
/// ([Byte], [Char], and [Grapheme].)
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
    fn next_byte(s: &str) -> Option<Byte>;
    fn get_slice(s: &str, range: Range<Self>) -> &str;
}

impl Offset for Byte {
    const ZERO: Self = Self(0);

    fn offset_len(s: &str) -> Byte {
        Byte(str::len(s))
    }

    fn next_byte(s: &str) -> Option<Byte> {
        if s.is_empty() {
            None
        } else {
            Some(Byte(1))
        }
    }

    fn get_slice(s: &str, range: Range<Self>) -> &str {
        &s[range.start.0..range.end.0]
    }
}

impl Offset for Char {
    const ZERO: Self = Self(0);

    fn offset_len(s: &str) -> Char {
        Char(s.char_indices().count())
    }

    fn next_byte(s: &str) -> Option<Byte> {
        s.char_indices().next().map(|t| Byte(t.0))
    }

    fn get_slice(s: &str, range: Range<Self>) -> &str {
        Byte::get_slice(s, s.try_to_byte_offsets(range).unwrap())
    }
}

impl Offset for Grapheme {
    const ZERO: Self = Self(0);

    fn offset_len(s: &str) -> Grapheme {
        use unicode_segmentation::UnicodeSegmentation;
        Grapheme(s.grapheme_indices(/*extended=*/ true).count())
    }

    fn next_byte(s: &str) -> Option<Byte> {
        use unicode_segmentation::UnicodeSegmentation;
        s.grapheme_indices(/*extended=*/ true)
            .next()
            .map(|t| Byte(t.0))
    }

    fn get_slice(s: &str, range: Range<Self>) -> &str {
        Byte::get_slice(s, s.try_to_byte_offsets(range).unwrap())
    }
}

/// A type that describes the same offset in multiple measurements.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::offsets::*;
///
/// let length: Offsets = "a̐éö̲\r\n".into();
/// assert_eq!(Grapheme(4), *length.as_ref());
/// assert_eq!(Char(9), *length.as_ref());
/// assert_eq!(Byte(13), *length.as_ref());
/// ```
#[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Hash)]
pub struct Offsets(pub(crate) Byte, pub(crate) Char, pub(crate) Grapheme);

impl Offsets {
    pub const fn new_zero() -> Self {
        Self(Byte(0), Char(0), Grapheme(0))
    }
    pub fn from_grapheme_byte(b: Byte, g: Grapheme, s: &str) -> Self {
        Self(b, Char(s[0..b.0].chars().count()), g)
    }
    pub fn to<T>(&self) -> T
    where
        T: Clone,
        Self: AsRef<T>,
    {
        self.as_ref().clone()
    }
    pub fn byte(&self) -> Byte {
        self.0
    }
    pub fn char(&self) -> Char {
        self.1
    }
    pub fn grapheme(&self) -> Grapheme {
        self.2
    }
}

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

impl core::ops::AddAssign for Offsets {
    fn add_assign(&mut self, other: Self) {
        self.0 += other.0;
        self.1 += other.1;
        self.2 += other.2;
    }
}

impl Sub for Offsets {
    type Output = Self;
    fn sub(self, other: Self) -> Self {
        Self(self.0 - other.0, self.1 - other.1, self.2 - other.2)
    }
}

impl iter::Sum for Offsets {
    fn sum<I: Iterator<Item = Self>>(iter: I) -> Self {
        let mut acc = Offsets::new_zero();
        for offset in iter {
            acc += offset;
        }
        acc
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
/// use notemaps_text::offsets::*;
///
/// fn get_byte_offset(s: &str, chars: Char) -> Result<usize, OffsetOutOfBoundsError<Char>> {
///     s.char_indices().nth(chars.0).map(|t|t.0).ok_or(chars.into())
/// }
/// ```
#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
pub struct OffsetOutOfBoundsError<O> {
    max: Option<O>,
    arg: O,
}

impl<O> OffsetOutOfBoundsError<O> {
    #[must_use]
    pub fn with_max(mut self, max: O) -> Self {
        self.max = Some(max);
        self
    }
}

impl<O> From<O> for OffsetOutOfBoundsError<O> {
    fn from(arg: O) -> Self {
        Self { arg, max: None }
    }
}

impl<O: fmt::Debug> fmt::Display for OffsetOutOfBoundsError<O> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> Result<(), fmt::Error> {
        match &self.max {
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
/// use notemaps_text::offsets::StrExt;
/// use notemaps_text::offsets::*;
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
    fn byte_offsets(&self) -> <&Self as StrExtTypes<'_, O>>::ByteOffsets;

    /// Returns the byte offset at the beginning of the `O` unit at `offset` in `self`.
    fn try_byte_offset_at(&self, offset: O) -> Result<Byte, OffsetOutOfBoundsError<O>> {
        self.byte_offsets()
            .nth(*offset.borrow())
            .ok_or_else(|| offset.into())
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
    fn byte_offsets(&self) -> <&Self as StrExtTypes<'_, Byte>>::ByteOffsets {
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
    fn byte_offsets(&self) -> <&Self as StrExtTypes<'_, Char>>::ByteOffsets {
        ByteOffsets::new(self.char_indices(), self.len())
    }
}

impl<'a> StrExtTypes<'a, Grapheme> for &'a str {
    type ByteOffsets = ByteOffsets<unicode_segmentation::GraphemeIndices<'a>, &'a str>;
}

impl StrExt<Grapheme> for str {
    fn byte_offsets(&self) -> <&Self as StrExtTypes<'_, Grapheme>>::ByteOffsets {
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
        self.0.next().map(|t| Byte(t.0)).or_else(|| self.1.next())
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
