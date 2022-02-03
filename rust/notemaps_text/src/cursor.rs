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

/*
pub trait Cursor {
    type Item:?Sized;
    fn move_next(&mut self);
    fn move_prev(&mut self);
    fn current(&self) -> Option<&Self::Item>;
    fn index(&self)->Option<usize>;
}

pub struct SliceCursor<'a, T> {
    slice: &'a [T],
    i: usize,
}

impl<'a, T> Cursor for SliceCursor<'a, T> {
    type Item = T;
    fn move_next(&mut self) {
        if self.i < self.slice.len() {
            self.i += 1;
        } else {
            self.i = 0;
        }
    }
    fn move_prev(&mut self) {
        if self.i > 0 {
            self.i -= 1;
        } else {
            self.i = self.slice.len();
        }
    }
    fn current(&self) -> Option<&T> {
        if self.i < self.slice.len() {
            Some(&self.slice[self.i])
        } else {
            None
        }
    }
    fn index(&self)->Option<usize>{
        if self.i<self.slice.len(){
            Some(self.i)
        }else{
            None
        }
    }
}

impl<'a, T> From<&'a [T]> for SliceCursor<'a, T> {
    fn from(slice: &'a [T]) -> Self {
        Self { slice, i: 0 }
    }
}

#[cfg(test)]
mod a_slice_cursor {
    use super::*;

    #[test]
    fn moves_forward_through_a_slice_as_ring() {
        let slice = vec!["red", "blue", "green"];
        let mut cursor = SliceCursor::from(slice.as_ref());
        assert_eq!(cursor.current().copied(), Some("red"));
        cursor.move_next();
        assert_eq!(cursor.current().copied(), Some("blue"));
        cursor.move_next();
        assert_eq!(cursor.current().copied(), Some("green"));
        cursor.move_next();
        assert_eq!(cursor.current(), None);
        cursor.move_next();
        assert_eq!(cursor.current().copied(), Some("red"));
    }

    #[test]
    fn moves_backward_through_a_slice_as_ring() {
        let slice = vec!["red", "blue", "green"];
        let mut cursor = SliceCursor::from(slice.as_ref());
        assert_eq!(cursor.current().copied(), Some("red"));
        cursor.move_prev();
        assert_eq!(cursor.current(), None);
        cursor.move_prev();
        assert_eq!(cursor.current().copied(), Some("green"));
        cursor.move_prev();
        assert_eq!(cursor.current().copied(), Some("blue"));
    }
}

use core::ops::Range;
use unicode_segmentation::GraphemeCursor as GraphemeBoundaryCursor;
use unicode_segmentation::GraphemeIncomplete;
//use std::borrow::Cow;

pub struct GraphemeCursor< T> {
    //'a, T:Cursor<'a,U >, U:AsRef<str>> {
    strings: T,
    absolute: Range<usize>,
    relative: Range<usize>,
    boundaries: GraphemeBoundaryCursor,
    broken: Option<GraphemeIncomplete>,
}

impl< T: Cursor> GraphemeCursor< T> {}

impl< T: Cursor> Cursor for GraphemeCursor< T>
where
    T::Item: AsRef<str>,
{
    type Item = str;

    fn move_next(&mut self) {
        //if self.strings.current().is_none() { self.strings.move_next(); self.start = 0; self.boundaries.set_cursor(0); self.broken = None; }
        while let Some(s) = self.strings.current().map(|s|s.as_ref()) {
            let start = self.boundaries.cur_cursor();
            match self.boundaries.next_boundary(s, 0) {
                Ok(Some(end)) => {
                    // This is the typical case: we have moved to the next grapheme within the
                    // current string.
                    self.relative = start..end;
                    self.absolute =
                    return;
                }
                Ok(None) => {
                    // We've reached the end of current string, so let's start anew at the
                    // beginning of the next one.
                    self.strings.move_next();
                    self.cur = 0..0;
                    self.boundaries.set_cursor(0);
                }
                Err(err) => {
                    self.broken = Some(err);
                    return;
                }
            }
        }
        // In case we break out of the loop without returning, we've reached the end of the
        // sequence of underlying strings.
    }

    fn move_prev(&mut self) {
        todo!("")
    }

    fn current(&self) -> Option<&str> {
        self.strings.current().map(|s|&s.as_ref()[self.cur.clone()])
    }

    fn index(&self)->Option<usize>{
        self.
    }
}

impl< T: Cursor> From<T> for GraphemeCursor< T>
where
    T::Item: AsRef<str>,
{
    fn from(strings: T) -> Self {
        let mut self_ = Self {
            strings,
            cur: 0..0,
            boundaries: GraphemeBoundaryCursor::new(0, usize::MAX, true),
            broken: None,
        };
        self_.move_next();
        self_
    }
}

#[cfg(test)]
mod a_grapheme_cursor {
    use super::*;

    #[test]
    fn moves_forward_through_slice_of_strings() {
        let slice = vec!["a̐éö̲", "", "\r\n"];
        let strs = SliceCursor::from(slice.as_ref());
        let mut graphemes = GraphemeCursor::from(strs);
        assert_eq!(graphemes.current(), Some("a̐"));
        graphemes.move_next();
        assert_eq!(graphemes.current(), Some("é"));
        graphemes.move_next();
        assert_eq!(graphemes.current(), Some("ö̲"));
        // graphemes.move_next();
        //assert_eq!(graphemes.current(),Some("\r\n"));
        // graphemes.move_next();
        //assert_eq!(graphemes.current(),None);
    }
}
*/
