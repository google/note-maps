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
use super::offsets::Grapheme;
use super::Note;
use core::ops::Range;
use std::rc::Rc;

/// Any type implementing [Mark] can be used to mark up text in a [MarkStr].
///
/// # Examples
///
/// ```rust
/// use notemaps_core::Mark;
///
/// #[derive(Clone)]
/// enum FontFamily { Serif, SansSerif }
///
/// impl Mark for FontFamily {}
///
/// use FontFamily::*;
///
/// let formatted_text = vec![
///     Serif.mark("Hello, "),
///     SansSerif.mark("World!"),
/// ];
/// ```
pub trait Mark {
    /// Creates a [MarkStr] that applies self to s.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use notemaps_core::Mark;
    ///
    /// #[derive(Clone)]
    /// struct PointSize (u8);
    ///
    /// impl Mark for PointSize {}
    ///
    /// PointSize(12).mark("Hello, World!");
    /// ```
    fn mark<S: AsRef<str>>(&self, s: S) -> MarkStr<Self, S>
    where
        Self: Clone,
    {
        MarkStr::new(self.clone(), s)
    }
}

/// A contiguous piece of marked up text that has the same mark from beginning to end.
///
/// With a sufficiently expressive implementation of [Mark], any rich text document can be
/// represented as a sequence of [MarkStr] values.
///
/// # Examples
///
/// ```rust
/// use notemaps_core::Mark;
/// use notemaps_core::MarkStr;
///
/// #[derive(Clone)]
/// enum Style { Regular, Italic }
///
/// impl Mark for Style {}
///
/// use Style::*;
///
/// let document: Vec<MarkStr<Style, &'static str>> = [
///     Regular.mark("Hello, "),
///     Italic.mark("World!"),
/// ].to_vec();
/// ```
#[derive(Debug)]
pub struct MarkStr<M: Mark, S: AsRef<str> = Rc<str>> {
    mark: M,
    string: S,
}

impl<M: Mark, S: AsRef<str>> MarkStr<M, S> {
    fn new(mark: M, string: S) -> Self {
        Self { mark, string }
    }
    pub fn as_str(&self) -> &str {
        self.string.as_ref()
    }
    pub fn mark(&self) -> &M {
        &self.mark
    }
    pub fn mark_mut(&mut self) -> &mut M {
        &mut self.mark
    }
    pub fn map_str<T: AsRef<str>, F: FnOnce(S) -> T>(self, f: F) -> MarkStr<M, T> {
        MarkStr {
            mark: self.mark,
            string: f(self.string),
        }
    }
    pub fn map_mark<N: Mark, F: FnOnce(M) -> N>(self, f: F) -> MarkStr<N, S> {
        MarkStr {
            mark: f(self.mark),
            string: self.string,
        }
    }
}

impl<M: Mark, S: AsRef<str>> Default for MarkStr<M, S>
where
    S: Default,
    M: Default,
{
    fn default() -> Self {
        Self::new(Default::default(), Default::default())
    }
}

impl<M: Mark, S: AsRef<str>> Clone for MarkStr<M, S>
where
    S: Clone,
    M: Clone,
{
    fn clone(&self) -> Self {
        Self::new(self.mark.clone(), self.string.clone())
    }
}

impl<'a, M: Mark, S: AsRef<str>> From<&'a str> for MarkStr<M, S>
where
    S: From<&'a str>,
    M: Default,
{
    fn from(src: &'a str) -> Self {
        Self::new(Default::default(), src.into())
    }
}

impl<'a, M: Mark, S: AsRef<str>> From<(M, S)> for MarkStr<M, S> {
    fn from(src: (M, S)) -> Self {
        Self::new(src.0, src.1)
    }
}

impl<M: Mark, S: AsRef<str>> AsRef<str> for MarkStr<M, S>
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

    fn into_input<M: Mark, S: AsRef<str>>(
        self,
        range: Range<Grapheme>,
        r: Replacement<M, S>,
    ) -> MarkStrInput<M, S>
    where
        Self: Sized,
        <Self as Iterator>::Item: std::borrow::Borrow<MarkStr<M, S>>,
        M: Clone,
        S: Clone,
    {
        MarkStrInput::new(self, range, r)
    }
}

impl<T: Iterator> IteratorExt for T {}

#[cfg(test)]
mod a_collection_of_mark_strs {
    use super::offsets::{Byte, Char, Grapheme};
    use super::IteratorExt;
    use super::Mark;
    use super::MarkStr;

    #[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
    enum Font {
        Serif,
        SansSerif,
    }

    impl Mark for Font {}
    impl Mark for std::rc::Rc<Font> {}

    impl Default for Font {
        fn default() -> Self {
            Font::Serif
        }
    }

    #[test]
    fn can_be_cheaply_converted_to_a_str_reference() {
        let mut text: Vec<MarkStr<Font>> = vec!["hello".into()];
        assert_eq!(text[0].as_str(), "hello");
        assert_eq!(text[0].as_ref(), "hello");
        assert_eq!(*text[0].mark(), Font::Serif);
        *text[0].mark_mut() = Font::SansSerif;
        assert_eq!(*text[0].mark(), Font::SansSerif);
        assert_eq!(
            vec![Font::Serif.mark("a̐éö̲"), Font::SansSerif.mark("\r\n")]
                .iter()
                .count_bytes(),
            Byte(13)
        );
        assert_eq!(
            vec![Font::Serif.mark("a̐éö̲"), Font::SansSerif.mark("\r\n")]
                .iter()
                .count_chars(),
            Char(9)
        );
        assert_eq!(
            vec![Font::Serif.mark("a̐éö̲"), Font::SansSerif.mark("\r\n")]
                .iter()
                .count_graphemes(),
            Grapheme(4)
        );
    }
}

#[derive(Clone)]
pub enum Replacement<M: Mark, S: AsRef<str>> {
    Mark(M),
    Str(S),
}

#[derive(Clone)]
pub struct MarkStrInput<M: Mark, S: AsRef<str>> {
    context: Vec<MarkStr<M, S>>,
    range: Range<Grapheme>,
    replacement: Replacement<M, S>,
}

impl<M: Mark, S: AsRef<str>> MarkStrInput<M, S> {
    fn new<I: Iterator>(
        context: I,
        range_graphemes: Range<Grapheme>,
        replacement: Replacement<M, S>,
    ) -> Self
    where
        <I as Iterator>::Item: std::borrow::Borrow<MarkStr<M, S>>,
        M: Clone,
        S: Clone,
    {
        use std::borrow::Borrow;
        Self {
            context: context.map(|m| m.borrow().clone()).collect(),
            range: range_graphemes,
            replacement,
        }
    }

    pub fn context(&self) -> &[MarkStr<M, S>] {
        self.context.as_ref()
    }

    pub fn range_graphemes(&self) -> Range<Grapheme> {
        self.range.clone()
    }

    pub fn text(&self) -> Option<S>
    where
        S: Clone,
    {
        match &self.replacement {
            Replacement::Str(text) => Some(text.clone()),
            _ => None,
        }
    }

    pub fn mark(&self) -> Option<M>
    where
        M: Clone,
    {
        match &self.replacement {
            Replacement::Mark(mark) => Some(mark.clone()),
            _ => None,
        }
    }
}

pub struct Command<'a, E> {
    commit_fn: Box<dyn 'a+FnOnce() -> Result<(), E>>,
}

impl<'a,E> Command<'a,E> {
    pub fn new<F:'a+FnOnce()->Result<(),E>>(commit_fn:F)->Self{Self{commit_fn:Box::new(commit_fn)}}
    pub fn into_result(self) -> Result<(), E> {
        let commit = self.commit_fn;
        commit()
    }
}

pub trait Interpreter<M: Mark> {
    type InterpreterError;
    type CommandError;
    fn interpret<S: AsRef<str>>(
        &mut self,
        input: MarkStrInput<M, S>,
    ) -> Result<Command<Self::CommandError>, Self::InterpreterError>;
}

#[derive(Clone)]
pub struct TopicMark {
    pub topic: Note,
}

#[derive(Clone, Default)]
pub struct OccurrenceMark {
    pub occurrence_offset: usize,
    pub occurrence_types: Vec<Note>,
}

impl OccurrenceMark {
    pub fn is_name(&self) -> bool {
        self.occurrence_types.contains(&Note::NAME)
    }
}

#[derive(Clone)]
pub enum StrType {
    /// Delimiter text should:
    /// - typically not be editable in the UI.
    /// - be edtitable in the UI only to _delete_ the delimiter text, and only if there is a
    ///   command that can be expressed by doing so.
    Delimiter,
    /// Value text should:
    /// - contain the value of the note identified in the associated [OccurrenceMark].
    Value,
    /// Hyper text should:
    /// - afford navigation to an associated note through optional user interaction.
    /// - contain the value of an occurrence of type Note::NAME, or else another readable
    ///   identifier.
    Hyper,
}

//#[derive(Clone)] struct Actionable { editable: bool, splittable: bool, }

#[derive(Clone)]
pub struct NoteMark {
    pub topic: Rc<TopicMark>,
    pub occurrence: Rc<OccurrenceMark>,
    pub str_type: StrType,
}

impl Mark for NoteMark {}

impl NoteMark {
    pub fn new(topic: Rc<TopicMark>) -> Self {
        Self {
            topic,
            occurrence: Rc::default(),
            str_type: StrType::Delimiter,
        }
    }
    pub fn with_occurrence(mut self, occurrence: Rc<OccurrenceMark>) -> Self {
        self.occurrence = occurrence;
        self
    }
    pub fn with_strtype(mut self, str_type: StrType) -> Self {
        self.str_type = str_type;
        self
    }
}

trait ExtendExt<S: AsRef<str>>: Extend<MarkStr<NoteMark, S>> {
    fn extend_name(&mut self, mut m: NoteMark, value: S)
    where
        S: From<&'static str>,
    {
        Rc::make_mut(&mut m.occurrence)
            .occurrence_types
            .push(Note::NAME);
        self.extend([
            (m.clone().with_strtype(StrType::Value), value).into(),
            (m.clone().with_strtype(StrType::Delimiter), "\n".into()).into(),
        ]);
    }
}

impl<C: Extend<MarkStr<NoteMark, S>>, S: AsRef<str>> ExtendExt<S> for C {}

#[cfg(test)]
mod example {
    use super::*;

    #[derive(Debug)]
    struct MyModel {
        name: String,
    }

    #[derive(Clone,Debug)]
    enum MyMark {
        Name,
        Delimiter,
    }

    impl Mark for MyMark {}

    struct View {}

    impl View {
        fn render(&self, model: &MyModel) -> Vec<MarkStr<MyMark>> {
            vec![
                MyMark::Delimiter.mark("Hello, ".into()),
                MyMark::Name.mark(model.name.as_str().into()),
                MyMark::Delimiter.mark("!".into()),
                MyMark::Delimiter.mark("\n".into()),
            ]
        }
    }

    use std::sync::{Arc, Mutex};
    struct MyInterpreter {
        _model: Arc<Mutex<MyModel>>,
    }

    impl Interpreter<MyMark> for MyInterpreter {
        type InterpreterError = &'static str;
        type CommandError = &'static str;
        fn interpret<S: AsRef<str>>(
            &mut self,
            input: MarkStrInput<MyMark, S>,
        ) -> Result<Command<Self::CommandError>, Self::InterpreterError> {
            if input.context().len()!=1{
                Err("can only act on one segment at a time for now")
            }else {
                let segment = &input.context()[0];
                match segment.mark(){
                    MyMark::Name=>{
                        Ok(Command::new(||{
                            Ok(())
                        }))
                    }
                    _=>Err("cannot interpret command from attempt to edit this segment"),
                }
            }
        }
    }

    #[test]
    fn documents_made_of_marked_strings() {
        let internet = Note::random();
        let mark_internet = NoteMark::new(Rc::new(TopicMark { topic: internet }));
        let mark_name0 = mark_internet
            .clone()
            .with_occurrence(Rc::new(OccurrenceMark {
                occurrence_offset: 0,
                occurrence_types: [Note::NAME].into(),
            }));
        let document: Vec<MarkStr<NoteMark>> = vec![
            mark_name0
                .clone()
                .with_strtype(StrType::Value)
                .mark("internet".into()),
            mark_name0
                .clone()
                .with_strtype(StrType::Delimiter)
                .mark("\n".into()),
        ];
        assert_eq!(
            document
                .iter()
                .map(|m| m.as_str().to_string())
                .fold(String::new(), |a, b| a + &b),
            "internet\n"
        );
    }

    #[test]
    fn interpret_input_to_command() {
        let model = Arc::new(Mutex::new(MyModel {
            name: "World".into(),
        }));
        let interpreter = MyInterpreter {
            _model: model.clone(),
        };
        let document = {
            let model = model.lock().unwrap();
            View {}.render(&*model)
        };
        let input = document
            .iter()
            .into_input(Grapheme(7)..Grapheme(12), Replacement::Str("Test".into()));
        println!("{:?}",input.context());
        println!("{:?}",interpreter._model  );
        //interpreter.interpret(input).expect("input should be interpretable");
    }
}
