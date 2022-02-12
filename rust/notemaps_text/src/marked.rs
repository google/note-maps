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

use super::offsets;
use core::any::Any;
use core::borrow::Borrow;
use core::ops::Range;
use std::rc::Rc;

use crate::offsets::*;
use crate::*;

/// A contiguous piece of marked up text that has the same set of marks from beginning to end.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::Marked;
///
/// #[derive(Clone)]
/// enum Style { Regular, Italic }
///
/// use Style::*;
///
/// let document: Vec<Marked<&'static str>> = [
///     (Regular, "Hello, ").into(),
///     (Italic, "World!").into(),
/// ].to_vec();
/// ```
#[derive(Debug, Clone)]
pub struct Marked<S = UiString> {
    marks: MarkSet,
    string: S,
}

impl<S> Marked<S>
where
    S: Borrow<str>,
{
    pub fn new(marks: MarkSet, string: S) -> Self {
        Self { marks, string }
    }

    pub fn as_str(&self) -> &str {
        self.string.borrow()
    }

    pub fn marks(&self) -> &MarkSet {
        &self.marks
    }

    pub fn marks_mut(&mut self) -> &mut MarkSet {
        &mut self.marks
    }

    pub fn map_str<T, F: FnOnce(S) -> T>(self, f: F) -> Marked<T> {
        Marked {
            marks: self.marks,
            string: f(self.string),
        }
    }

    pub fn map_marks<F: for<'a> FnOnce(&'a mut MarkSet)>(self, f: F) -> Marked<S> {
        let mut marks = self.marks.clone();
        f(&mut marks);
        Marked {
            marks,
            string: self.string,
        }
    }

    pub fn graphemes(&self) -> impl '_ + Iterator<Item = Self>
    where
        S: Clone + Len + Slice<Byte> + Slice<Grapheme>,
    {
        self.string
            .split(Grapheme(1)..=self.string.len::<Grapheme>())
            .map(|g| Self::new(self.marks.clone(), g))
    }

    #[must_use]
    pub fn with_mark<M: Any>(mut self, mark: Rc<M>) -> Self {
        self.marks_mut().push(mark);
        self
    }

    #[must_use]
    pub fn with_marks(mut self, marks: MarkSet) -> Self {
        self.marks_mut().push_all(&marks);
        self
    }
}

impl<S: Borrow<str>> Default for Marked<S>
where
    S: Default,
{
    fn default() -> Self {
        Self::new(MarkSet::default(), Default::default())
    }
}

impl<'a, S: Borrow<str>> From<&'a str> for Marked<S>
where
    S: From<&'a str>,
{
    fn from(src: &'a str) -> Self {
        Self::new(MarkSet::default(), src.into())
    }
}

impl<'a, M: Any, S: Borrow<str>, T: Into<S>> From<(M, T)> for Marked<S> {
    fn from(src: (M, T)) -> Self {
        Self::new(MarkSet::new_with(Rc::new(src.0)), src.1.into())
    }
}

impl<S> AsRef<S> for Marked<S> {
    fn as_ref(&self) -> &S {
        &self.string
    }
}

impl<S, U> Slice<U> for Marked<S>
where
    S: Slice<U>,
    U: Unit,
{
    fn len2(&self) -> U {
        self.string.len2()
    }
    fn slice(&self, r: Range<U>) -> Self {
        Self {
            string: self.string.slice(r),
            marks: self.marks.clone(),
        }
    }
}

use core::iter;
use core::ops;

impl<S> ops::Add<Table<S>> for Marked<S>
where
    S: Borrow<str> + Len,
{
    type Output = Table<S>;

    fn add(self, other: Table<S>) -> Self::Output {
        iter::once(self).chain(other.into_iter()).collect()
    }
}

impl<S> ops::Add<Marked<S>> for Marked<S>
where
    S: Borrow<str> + Len,
{
    type Output = Table<S>;

    fn add(self, other: Marked<S>) -> Self::Output {
        iter::once(self).chain(iter::once(other)).collect()
    }
}

/// Extensions for [Iterator] types.
pub trait IteratorExt: Iterator {
    fn count_bytes(&mut self) -> offsets::Byte
    where
        <Self as Iterator>::Item: AsRef<str>,
    {
        offsets::Byte(self.map(|s| s.as_ref().len()).sum())
    }

    fn count_chars(&mut self) -> offsets::Char
    where
        <Self as Iterator>::Item: AsRef<str>,
    {
        offsets::Char(self.map(|s| s.as_ref().char_indices().count()).sum())
    }

    fn count_graphemes(&mut self) -> offsets::Grapheme
    where
        <Self as Iterator>::Item: AsRef<str>,
    {
        use unicode_segmentation::UnicodeSegmentation;
        offsets::Grapheme(
            self.map(|s| s.as_ref().grapheme_indices(/*extended=*/ true).count())
                .sum(),
        )
    }
}
