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
use std::rc::Rc;

use crate::*;

/// A contiguous piece of marked up text that has the same set of marks from beginning to end.
///
/// # Examples
///
/// ```rust
/// use notemaps_text::MarkStr;
///
/// #[derive(Clone)]
/// enum Style { Regular, Italic }
///
/// use Style::*;
///
/// let document: Vec<MarkStr<&'static str>> = [
///     (Regular, "Hello, ").into(),
///     (Italic, "World!").into(),
/// ].to_vec();
/// ```
#[derive(Debug, Clone)]
pub struct MarkStr<S: AsRef<str> = Rc<str>> {
    marks: MarkSet,
    string: S,
}

impl<S: AsRef<str>> MarkStr<S> {
    pub fn new(marks: MarkSet, string: S) -> Self {
        Self { marks, string }
    }
    pub fn get(&self) -> &S {
        &self.string
    }
    pub fn as_str(&self) -> &str {
        self.string.as_ref()
    }
    pub fn marks(&self) -> &MarkSet {
        &self.marks
    }
    pub fn marks_mut(&mut self) -> &mut MarkSet {
        &mut self.marks
    }
    pub fn map_str<T: AsRef<str>, F: FnOnce(S) -> T>(self, f: F) -> MarkStr<T> {
        MarkStr {
            marks: self.marks,
            string: f(self.string),
        }
    }
    #[must_use]
    pub fn with_marks(mut self, marks: MarkSet) -> Self {
        self.marks_mut().push_all(marks);
        self
    }
}

impl<S: AsRef<str>> Default for MarkStr<S>
where
    S: Default,
{
    fn default() -> Self {
        Self::new(MarkSet::default(), Default::default())
    }
}

impl<'a, S: AsRef<str>> From<&'a str> for MarkStr<S>
where
    S: From<&'a str>,
{
    fn from(src: &'a str) -> Self {
        Self::new(MarkSet::default(), src.into())
    }
}

impl<'a, M: Any, S: AsRef<str>> From<(M, S)> for MarkStr<S> {
    fn from(src: (M, S)) -> Self {
        Self::new(MarkSet::new_with(Rc::new(src.0)), src.1)
    }
}

impl<S: AsRef<str>> AsRef<str> for MarkStr<S>
where
    S: AsRef<str>,
{
    fn as_ref(&self) -> &str {
        self.string.as_ref()
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
