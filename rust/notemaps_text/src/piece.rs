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

use core::any::Any;
use core::ops;
use core::ops::Range;
use std::iter;
use std::rc::Rc;

use crate::offsets::*;
use crate::*;

/// [Piece] is a `str`-like type that also:
/// - is immutable,
/// - shares a backing buffer for cheap clones and slices,
/// - and measure offsets in user-perceived graphemes instead of bytes or chars.
///
/// [Piece] is intended to be used within a [Text].
///
/// # Examples
///
/// ```
/// use notemaps_text::Piece;
/// use notemaps_text::offsets::Grapheme;
///
/// let piece: Piece = "this is a test".into();
/// let slice: Piece = piece.slice(Grapheme(10)..Grapheme(14));
/// assert_eq!(slice.as_str(), "test");
/// ```
#[derive(Clone, Debug)]
pub struct Piece {
    buffer: Rc<str>,
    byte_range: Range<usize>,
    len_chars: Char,
    len_graphemes: Grapheme,
    marks: MarkSet,
}

impl Piece {
    pub fn new(buffer: Rc<str>) -> Self {
        use unicode_segmentation::UnicodeSegmentation;
        let byte_range = 0..buffer.len();
        let len_chars = buffer.chars().count().into();
        let len_graphemes = buffer.graphemes(true).count().into();
        Self {
            buffer,
            byte_range,
            len_chars,
            len_graphemes,
            marks: MarkSet::new(),
        }
    }

    #[must_use]
    pub fn slice(&self, r: Range<Grapheme>) -> Self {
        use unicode_segmentation::UnicodeSegmentation;
        let mut graphemes = self
            .as_str()
            .grapheme_indices(true)
            .map(|t| t.0)
            .chain(iter::once(self.as_str().len()));
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
        Self {
            buffer: self.buffer.clone(),
            byte_range: start..end,
            len_chars: (&self.buffer[start..end]).chars().count().into(),
            len_graphemes: r.end - r.start,
            marks: self.marks.clone(),
        }
    }

    pub fn len_offsets(&self) -> Offsets {
        Offsets(
            Byte(self.byte_range.len()),
            self.len_chars,
            self.len_graphemes,
        )
    }
    pub fn len(&self) -> Grapheme {
        self.len_graphemes
    }

    pub fn len_bytes(&self) -> Byte {
        Byte(self.byte_range.end - self.byte_range.start)
    }

    pub fn as_str(&self) -> &str {
        &self.buffer[self.byte_range.clone()]
    }

    pub fn marks(&self) -> &MarkSet {
        &self.marks
    }

    pub fn marks_mut(&mut self) -> &mut MarkSet {
        &mut self.marks
    }

    #[must_use]
    pub fn with_mark<M: Any>(mut self, m: Rc<M>) -> Self {
        self.marks.push(m);
        self
    }

    /// Returns the location of `offset` in this [Piece] as a [Byte] offset into the string
    /// returned by [Piece::as_str].
    ///
    /// If `offset` is out of bounds, returns the bounds of this piece.
    pub fn locate(&self, offset: Grapheme) -> Result<Offsets, Offsets> {
        self.as_str()
            .try_byte_offset_at(offset)
            .map(|byte| Offsets::from_grapheme_byte(byte, offset, self.as_str()))
            .map_err(|_| self.len_offsets())
    }
}

impl AsRef<str> for Piece {
    fn as_ref(&self) -> &str {
        self.as_str()
    }
}

impl<'a> From<&'a str> for Piece {
    fn from(s: &'a str) -> Self {
        Self::new(s.into())
    }
}

impl ops::Add<Piece> for Piece {
    type Output = Text;
    fn add(self, other: Piece) -> Self::Output {
        Text::from_iter([self, other])
    }
}

impl ops::Add<Text> for Piece {
    type Output = Text;
    fn add(self, other: Text) -> Self::Output {
        Text::from_iter(iter::once(self).chain(other.pieces().cloned()))
    }
}
