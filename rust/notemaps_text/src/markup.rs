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

//! Input to a document amounts to:
//! - Changing to the current selection or position of the cursor.
//! - Inserting text that replaces the current selection (or is inserted at the cursor).
//! - Removing selected text.
//!
//! These inputs will be translated to commands representing the intent to make changes to the
//! underlying data model. For example:
//! - Changing the content of a single contiguous block. The block is a contiguous sequence of
//!   graphemes that all have the a mark of the same type, and that type indicates that the content
//!   can be edited. The result will feel like regular text editing.
//! - Inserting a note-breaking sequence, for example a line-breaking grapheme. The result may be
//!   that text prior to the line break remains associated with the data model as it was, but the
//!   text following it becomes part of a new note instead. If there was no text following it, the
//!   result is a new note that is empty. An empty note in the document doesn't necessarily imply
//!   the creation of an empty note in the underlying data model.
//! - Inputs that would remove half of a delimiter, say, could be rejected. Some text should not be
//!   edited, but could be removed to indicate something more interesting.
//!
//! There are more detailed ideas about this written down in a few other places.
//!
//! Anyway, it ends up looking something like this:
//! - [Table] is a snapshot of a document.
//! - Inputs can be effected by mutating a [Table], but this doesn't make it easy to see the input
//!   itself. Rather, we need a way to mutate a [Table] that _generates_ an [Input] event.
//! - A [Rule], or sequence of rules, that can be applied to any given [Input] and [Table] to
//!   turn it into a [Command] which can be applied to the data model or to generate additional
//!   [Input] events that can be applied to bring the [Table] up to date after the original [Input]
//!   event has gone through.

use crate::offsets::*;
use crate::*;
use core::ops;
use core::ops::Range;
use std::iter;
use std::rc::Rc;

#[derive(Clone)]
pub struct State {
    document: Table,
    sel_range: Range<Grapheme>,
    sel_content: Table,
    rules: Rc<[Rule]>,
}

impl State {
    pub fn new<I: IntoIterator<Item = Rule>>(document: Table, rules: I) -> Self {
        let rules: Vec<Rule> = rules.into_iter().collect();
        Self {
            document,
            sel_range: Grapheme(0)..Grapheme(0),
            sel_content: Table::new(),
            rules: rules.into(),
        }
    }
    pub fn document(&self) -> &Table {
        &self.document
    }
    pub fn selected_range(&self) -> Range<Grapheme> {
        self.sel_range.clone()
    }
    pub fn selected_content(&self) -> &Table {
        &self.sel_content
    }
    pub fn with(self, input: Input) -> Change {
        let after_input = match &input {
            Input::Select(r) => self.select(self.document.clone(), r.clone()),
            Input::Insert(s) => self.select(
                self.document
                    .slice(Grapheme(0)..self.sel_range.start)
                    .into_iter()
                    .chain(iter::once(MarkStr::new(MarkSet::new(), s.clone())))
                    .chain(
                        self.document
                            .slice(self.sel_range.end..self.document.len())
                            .into_iter(),
                    )
                    .collect(),
                self.sel_range.start..self.sel_range.start,
            ),
            Input::Delete => self.select(
                self.document.slice(Grapheme(0)..self.sel_range.start)
                    + self.document.slice(self.sel_range.end..self.document.len()),
                self.sel_range.start..self.sel_range.start,
            ),
        };
        let mut change = Change {
            before: self,
            input,
            after_input: after_input.clone(),
            output: Vec::new(),
            after_output: after_input,
        };
        for r in &*change.before.rules {
            let execute = &*r;
            for o in execute(&change) {
                change.output.push(o.clone());
                use Output::*;
                match o {
                    AdjustSelection(range) => {
                        change.after_output = change
                            .after_output
                            .select(change.after_output.document.clone(), range);
                    }
                    Replace(range, string) => {
                        change.after_output.document = change
                            .after_output
                            .document
                            .with_replace(range, Some(string));
                    }
                    Mark(range, marker) => {
                        change.after_output.document = change
                            .after_output
                            .document
                            .map_marks(range, |marks| (&*marker)(marks));
                    }
                }
            }
        }
        change
    }
    fn select(&self, document: Table, r: Range<Grapheme>) -> Self {
        Self {
            document,
            sel_range: r.start..r.end,
            sel_content: self.document.slice(r),
            rules: self.rules.clone(),
        }
    }
}

impl Default for State {
    fn default() -> Self {
        Self::new(Table::new(), None)
    }
}

impl ops::Add<Input> for State {
    type Output = Change;
    fn add(self, input: Input) -> Change {
        self.with(input)
    }
}

#[derive(Clone, Debug)]
pub enum Input {
    Select(Range<Grapheme>),
    Insert(UiString),
    Delete,
}

type Marker = Rc<dyn for<'a> Fn(&'a mut MarkSet)>;

#[derive(Clone)]
pub enum Output {
    AdjustSelection(Range<Grapheme>),
    Replace(Range<Grapheme>, MarkStr),
    Mark(Range<Grapheme>, Marker),
}

#[derive(Clone)]
pub struct Change {
    before: State,
    input: Input,
    after_input: State,
    output: Vec<Output>,
    after_output: State,
}

impl<'a> Change {
    pub fn before(&self) -> &State {
        &self.before
    }
    pub fn input(&self) -> &Input {
        &self.input
    }
    pub fn after_input(&self) -> &State {
        &self.after_input
    }
    pub fn output(&self) -> &[Output] {
        self.output.as_slice()
    }
    pub fn after_output(&self) -> &State {
        &self.after_output
    }
}

type Rule = Box<dyn Fn(&Change) -> Vec<Output>>;

#[cfg(test)]
mod example {
    use super::*;

    #[derive(Debug)]
    struct MyModel {
        name: Rc<str>,
    }

    #[derive(Clone, Debug, Eq, PartialEq, Hash)]
    enum MyMark {
        Name,
        Delimiter,
    }

    struct View {}

    impl View {
        fn render(&self, model: &MyModel) -> Table {
            Table::from_iter([
                MarkStr::new(
                    MarkSet::new_with(MyMark::Delimiter.into()),
                    "Hello, ".into(),
                ),
                MarkStr::new(
                    MarkSet::new_with(MyMark::Name.into()),
                    UiString::new(model.name.clone()),
                ),
                MarkStr::new(MarkSet::new_with(MyMark::Delimiter.into()), "!".into()),
            ])
        }
    }

    use std::sync::{Arc, Mutex};
    struct MyInterpreter {
        model: Arc<Mutex<MyModel>>,
    }

    impl MyInterpreter {
        fn rules(&self) -> impl IntoIterator<Item = Rule> {
            let model = self.model.clone();
            let f = Box::new(move |change: &Change| {
                let output = Vec::new();
                match change.input() {
                    Input::Select(_range) => {}
                    Input::Insert(string) => {
                        if change
                            .before()
                            .selected_content()
                            .pieces()
                            .all(|p| p.marks().contains(&MyMark::Name))
                        {
                            // TODO: this needs to be much more correct... and the API has to be
                            // there to support it.
                            model
                                .lock()
                                .expect("model can be locked while processing input")
                                .name = string.as_str().into();
                        } else {
                            panic!(
                                "cannot edit this part of the document: {:?}",
                                change.before().selected_range()
                            );
                        }
                    }
                    Input::Delete => {}
                }
                output
            });
            vec![Rule::from(f)]
        }
    }

    #[test]
    fn documents_made_of_marked_strings() {}

    #[test]
    fn interpret_input_to_command() {
        let model = Arc::new(Mutex::new(MyModel {
            name: "World".into(),
        }));
        let interpreter = MyInterpreter {
            model: model.clone(),
        };
        let view = View {};
        let document = view.render(&*model.lock().unwrap());
        let state = State::new(document, interpreter.rules());
        assert_eq!(state.document().to_string(), "Hello, World!");
        assert_eq!(state.selected_content().to_string(), "");
        assert_eq!(state.selected_range(), Grapheme(0)..Grapheme(0));
        let state = state
            .with(Input::Select(Grapheme(7)..Grapheme(12)))
            .after_input;
        assert_eq!(state.document().to_string(), "Hello, World!");
        assert_eq!(state.selected_range(), Grapheme(7)..Grapheme(12));
        assert_eq!(state.selected_content().to_string(), "World");
        let state = state.with(Input::Insert("Test".into())).after_output;
        assert_eq!(state.document().to_string(), "Hello, Test!");
        assert_eq!(
            model.lock().expect("model can be locked").name.as_ref(),
            "Test"
        );
    }
}
