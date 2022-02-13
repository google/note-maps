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
//!
//! let graphme_3 = Grapheme(1) + Grapheme(2);
//! assert_eq!(graphme_3.0, 3usize);
//!
//! let char_4 = Char(7) - Char(3);
//! assert_eq!(char_4.0, 4usize);
//! ```

use core::borrow::Borrow;
use core::fmt;
use core::iter;
use core::ops::*;

/// In this context, a "natural unit" is a unit of measurement that uses only [natural numbers][].
///
/// This macro is meant to help define type-safe wrappers for natural units of measurement that
/// rerpesent offsets into a string. For example, Rust strings natively support byte offsets and
/// have good support for `char` offsets.
///
/// [natural numbers]: https://en.wikipedia.org/wiki/Natural_number
macro_rules! natural_unit {
    (
        $(#[$outer:meta])* $pub:vis struct $tuple:ident ($type:ident)
        $plural:literal singular $singular:literal test $test_mod:ident;
    ) => {
        $(#[$outer])*
        #[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Hash, Ord, PartialOrd)]
        $pub struct $tuple (pub $type);

        impl $tuple {
            /// The minimum allowable value for this type: no operation can produce a value smaller
            /// than [$tuple::MIN].
            pub const MIN: Self = Self($type::MIN);

            /// The maximum allowable value for this type: no operation can produce a value greater
            /// than [$tuple::MAX].
            pub const MAX: Self = Self($type::MAX);
        }

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

natural_unit! {
    /// Represents an index into a piece table, like [crate::Table].
    ///
    /// Intended to help avoid bugs caused by unintentionally mixing `usize` values that have very
    /// different meanings.
    ///
    /// # Example
    ///
    /// ```rust
    /// use notemaps_text::offsets::Piece;
    ///
    /// assert_eq!((Piece(1) + Piece(2)).0, 3);
    /// // let piece_2 = Piece(1) + Graphme(1); // does not compile!
    /// ```
    pub struct Piece(usize) " pieces" singular " piece" test a_piece;
}

mod internal {
    pub trait Sealed {}
    impl Sealed for super::Byte {}
    impl Sealed for super::Char {}
    impl Sealed for super::Grapheme {}
}

/// A public trait implemented exclusively by the measurement unit types defined in this module
/// ([Byte], [Char], and [Grapheme].)
///
/// Many traits are required so that type constraints intended to match only [Byte], [Char], or
/// [Grapheme] by requiring only [Unit] will allow Rust to infer all the other useful traits that
/// are implemented for each of these types.
pub trait Unit:
    'static
    + Copy
    + Eq
    + Ord
    + From<usize>
    + fmt::Debug
    + Add<Output = Self>
    + Add<usize, Output = Self>
    + AddAssign
    + AddAssign<usize>
    + Sub<Output = Self>
    + Sub<usize, Output = Self>
    + SubAssign
    + SubAssign<usize>
    + Borrow<usize>
    + internal::Sealed
    + iter::Step
{
    /// The minimum allowable value for this type: no operation can produce a value smaller than
    /// [Unit::ZERO].
    const ZERO: Self;

    /// The maximum allowable value for this type: no operation can produce a value greater than
    /// [Unit::MAX].
    const MAX: Self;

    /// Returns the maximum valid offset within the [str] `s`.
    fn offset_len(s: &str) -> Self;

    /// Returns the [Byte] offset of the first non-zero `Self` offset in `s`. This is also the
    /// [Byte] offset corresponding to `Self::from(1)`.
    fn next_byte(s: &str) -> Option<Byte> {
        Self::nth_byte_offset(s, 1usize.into()).ok()
    }

    /// For the `n`th valid offset of type `Self` in `s`, return the [Byte] value of that offset.
    ///
    /// If `n` is greater than the maximum valid offset within `s`, that is if it is greater than
    /// the value returned by [Unit::offset_len], then the maximum allowable offset will be
    /// returned as an error.
    fn nth_byte_offset(s: &str, n: Self) -> Result<Byte, Byte>;

    /// Returns a slice of a `str` from the given `range`, which is expressed in `Self` units.
    fn get_slice(s: &str, range: Range<Self>) -> &str {
        use std::convert::identity;
        let start = Self::nth_byte_offset(s, range.start).map_or_else(identity, identity);
        let end = start
            + Self::nth_byte_offset(&s[start.0..], range.end - range.start)
                .map_or_else(identity, identity);
        &s[start.0..end.0]
    }
}

impl Unit for Byte {
    const ZERO: Self = Self::MIN;
    const MAX: Self = Self::MAX;

    fn offset_len(s: &str) -> Byte {
        Byte(str::len(s))
    }

    fn nth_byte_offset(s: &str, n: Self) -> Result<Byte, Byte> {
        if n.0 <= s.len() {
            Ok(n)
        } else {
            Err(Byte(s.len()))
        }
    }
}

impl Unit for Char {
    const ZERO: Self = Self::MIN;
    const MAX: Self = Self::MAX;

    fn offset_len(s: &str) -> Char {
        Char(s.char_indices().count())
    }

    fn nth_byte_offset(s: &str, n: Self) -> Result<Byte, Byte> {
        s.char_indices()
            .map(|t| Byte(t.0))
            .chain(iter::once(Byte(s.len())))
            .nth(n.0)
            .ok_or(Byte(s.len()))
    }
}

impl Unit for Grapheme {
    const ZERO: Self = Self::MIN;
    const MAX: Self = Self::MAX;

    fn offset_len(s: &str) -> Grapheme {
        use unicode_segmentation::UnicodeSegmentation;
        Grapheme(s.grapheme_indices(/*extended=*/ true).count())
    }

    fn nth_byte_offset(s: &str, n: Self) -> Result<Byte, Byte> {
        use unicode_segmentation::UnicodeSegmentation;
        s.grapheme_indices(/*extended=*/ true)
            .map(|t| Byte(t.0))
            .chain(iter::once(Byte(s.len())))
            .nth(n.0)
            .ok_or(Byte(s.len()))
    }
}

/// Specifies an offset into a string using multiple [Unit] types: [Byte], [Char], and [Grapheme]
///
/// [Locus] is intended to support code that mediates between UI libraries, humane interface
/// requirements, and peer-to-peer conflict resolution strategies, each of which may have its own
/// preference for measuring offsets into strings.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::offsets::*;
///
/// let length: Locus = "a̐éö̲\r\n".into();
/// assert_eq!(Grapheme(4), *length.as_ref());
/// assert_eq!(Char(9), *length.as_ref());
/// assert_eq!(Byte(13), *length.as_ref());
/// ```
#[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub struct Locus(pub(crate) Byte, pub(crate) Char, pub(crate) Grapheme);

use crate::Slice;
impl Locus {
    pub const fn zero() -> Self {
        Self(Byte(0), Char(0), Grapheme(0))
    }

    pub const fn is_zero(&self) -> bool {
        self.0 .0 == 0 && self.1 .0 == 0 && self.2 .0 == 0
    }

    pub fn from_len<S>(s: &S) -> Self
    where
        S: Slice<Byte> + Slice<Char> + Slice<Grapheme>,
    {
        Self(s.len(), s.len(), s.len())
    }

    pub fn whatever<T>(&self) -> T
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

// Constructor traits:

impl<'a> From<&'a str> for Locus {
    fn from(s: &'a str) -> Self {
        Self(
            Byte::offset_len(s),
            Char::offset_len(s),
            Grapheme::offset_len(s),
        )
    }
}

impl<'a, S: Slice<Byte> + Slice<Char> + Slice<Grapheme>> From<(&'a S, Byte)> for Locus {
    fn from((s, byte): (&S, Byte)) -> Self {
        Self(
            byte,
            Slice::<Byte>::locate::<Char, Byte>(s, byte).expect("offset should be valid"),
            Slice::<Byte>::locate::<Grapheme, Byte>(s, byte).expect("offset should be valid"),
        )
    }
}

impl<'a, S: Slice<Byte> + Slice<Char> + Slice<Grapheme>> From<(&'a S, Char)> for Locus {
    fn from((s, chars): (&S, Char)) -> Self {
        let byte = Slice::<Char>::locate::<Byte, Byte>(s, chars).expect("offset should be valid");
        Self(
            byte,
            chars,
            Slice::<Byte>::locate::<Grapheme, Byte>(s, byte).expect("offset should be valid"),
        )
    }
}

impl<'a, S: Slice<Byte> + Slice<Char> + Slice<Grapheme>> From<(&'a S, Grapheme)> for Locus {
    fn from((s, grapheme): (&S, Grapheme)) -> Self {
        let byte =
            Slice::<Grapheme>::locate::<Byte, Byte>(s, grapheme).expect("offset should be valid");
        Self(
            byte,
            Slice::<Byte>::locate::<Char, Byte>(s, byte).expect("offset should be valid"),
            grapheme,
        )
    }
}

impl Add for Locus {
    type Output = Self;
    fn add(self, other: Self) -> Self {
        Self(self.0 + other.0, self.1 + other.1, self.2 + other.2)
    }
}

impl core::ops::AddAssign for Locus {
    fn add_assign(&mut self, other: Self) {
        self.0 += other.0;
        self.1 += other.1;
        self.2 += other.2;
    }
}

impl Sub for Locus {
    type Output = Self;
    fn sub(self, other: Self) -> Self {
        Self(self.0 - other.0, self.1 - other.1, self.2 - other.2)
    }
}

impl SubAssign for Locus {
    fn sub_assign(&mut self, other: Self) {
        self.0 -= other.0;
        self.1 -= other.1;
        self.2 -= other.2;
    }
}

impl iter::Sum for Locus {
    fn sum<I: Iterator<Item = Self>>(iter: I) -> Self {
        let mut acc = Locus::zero();
        for offset in iter {
            acc += offset;
        }
        acc
    }
}

// Accessor traits:

impl AsRef<Locus> for Locus {
    fn as_ref(&self) -> &Locus {
        self
    }
}

impl AsRef<Byte> for Locus {
    fn as_ref(&self) -> &Byte {
        &self.0
    }
}

impl AsRef<Char> for Locus {
    fn as_ref(&self) -> &Char {
        &self.1
    }
}

impl AsRef<Grapheme> for Locus {
    fn as_ref(&self) -> &Grapheme {
        &self.2
    }
}
