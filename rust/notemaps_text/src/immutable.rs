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

#[derive(Clone, Debug)]
pub struct Immutable<B = Rc<str>> {
    buffer: B,
    byte_range: Range<Byte>,
}

impl<B> Immutable<B>
where
    B: Borrow<str>,
{
    pub fn new(buffer: B) -> Self {
        let byte_range = Byte(0)..Byte(buffer.borrow().len());
        Self { buffer, byte_range }
    }

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

impl<B> Slice<Byte> for Immutable<B>
where
    B: Borrow<str> + Clone,
{
    fn slice(&self, r: Range<Byte>) -> Self {
        Self {
            buffer: self.buffer.clone(),
            byte_range: self.byte_range.start + r.start..self.byte_range.start + r.end,
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
