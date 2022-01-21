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

//use std::sync::Arc;
//use super::MeasuredStr;

/// A [str] that can be marked up with a single value of type `M`.
#[derive(Debug)]
pub struct MarkedStr<S, M>(S, M);

impl<S, M> MarkedStr<S, M> {
    pub fn text(&self) -> &S {
        &self.0
    }
    pub fn as_str(&self) -> &str
    where
        S: AsRef<str>,
    {
        self.0.as_ref()
    }
    pub fn mark(&self) -> &M {
        &self.1
    }
    pub fn mark_mut(&mut self) -> &mut M {
        &mut self.1
    }
    /*
    pub fn split<O: Offset>(&self, split_at: O) -> (Self, Self)
    where
        M: Clone,
    {
        //use super::offsets::StrExt;
        //let split_at_byte = split_at.
        //self.0.split(
    }
    */
}

impl<S, M> Default for MarkedStr<S, M>
where
    S: From<&'static str>,
    M: Default,
{
    fn default() -> Self {
        "".into()
    }
}

impl<S, M> Clone for MarkedStr<S, M>
where
    S: Clone,
    M: Clone,
{
    fn clone(&self) -> Self {
        Self(self.0.clone(), self.1.clone())
    }
}

impl<'a, S, M> From<&'a str> for MarkedStr<S, M>
where
    S: From<&'a str>,
    M: Default,
{
    fn from(src: &'a str) -> Self {
        Self(src.into(), Default::default())
    }
}

impl<S, M> AsRef<str> for MarkedStr<S, M>
where
    S: AsRef<str>,
{
    fn as_ref(&self) -> &str {
        self.0.as_ref()
    }
}

//pub trait MarkedSlice<M>: AsRef<[MarkedStr<M>]> {}

//pub type MarkupSlice<M> = [Arc<MarkedStr<M>>];
//pub type MarkupVec = Vec<Arc<MarkedStr<M>>>;

//use std::iter;
//use std::slice;
pub trait Markup<S, M = ()>: AsRef<[MarkedStr<S, M>]> {
    //fn bytes(&self) -> Bytes<'_> { self.as_ref() .iter() .map(MarkedStr::as_str) .flat_map(str::as_bytes) }
    //fn chars(&self) -> Chars<'_> { todo!(""); }
    //fn graphemes(&self) -> Graphemes<'_> { todo!(""); }
    //fn words(&self) -> Words<'_> { todo!(""); }
    //fn lines(&self) -> Lines<'_> { todo!(""); }
    fn len(&self) -> usize
    where
        S: AsRef<str>,
    {
        self.as_ref()
            .iter()
            .fold(0, |acc, seg| acc + seg.as_str().len())
    }
}

impl<T, S, M> Markup<S, M> for T where T: AsRef<[MarkedStr<S, M>]> {}

pub type Segments<'a, S, M> = std::slice::Iter<'a, MarkedStr<S, M>>;

//pub type Bytes<'a, M> (iter::Peekable<Segments<'a, M>>); impl<'a,M> Iterator for Bytes<'a,M>{ }

//iter::FlatMap<iter::Map<slice::Iter<'a, MarkedStr<M>>, for<'r> fn(&'r MarkedStr<M >) -> &'r str {MarkedStr::<M>::as_str}>, &[u8], for<'r> fn(&'r str) -> &'r [u8] {core::str::<impl str>::as_bytes}>;
//pub struct Chars<'a> {}
//pub struct Graphemes<'a> {}
//pub struct Words<'a> {}
//pub struct Lines<'a> {}

#[cfg(test)]
mod a_char_vec {
    #[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
    enum Font {
        Serif,
        SansSerif,
    }
    impl Default for Font {
        fn default() -> Self {
            Font::Serif
        }
    }

    #[test]
    fn is_empty_by_default() {
        //use super::Markup;
        use super::MarkedStr;
        let mut text: Vec<MarkedStr<String, Font>> = vec!["hello".into()];
        assert_eq!(text[0].as_str(), "hello");
        assert_eq!(*text[0].mark(), Font::Serif);
        *text[0].mark_mut() = Font::SansSerif;
        assert_eq!(*text[0].mark(), Font::SansSerif);
    }
}
