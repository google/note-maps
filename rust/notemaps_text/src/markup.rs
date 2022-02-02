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

//use super::offsets::Grapheme;
//use core::ops::Range;

//use crate::*;

/*
#[derive(Clone)]
pub enum Replacement<M: Mark, S: AsRef<str>> {
    Mark(Rc<M>),
    Str(S),
}

#[derive(Clone)]
pub struct MarkStrInput<M: Mark, S: AsRef<str>> {
    context: Vec<MarkStr< S>>,
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
        <I as Iterator>::Item: std::borrow::Borrow<MarkStr< S>>,
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

    pub fn context(&self) -> &[MarkStr< S>] {
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
    commit_fn: Box<dyn 'a + FnOnce() -> Result<(), E>>,
}

impl<'a, E> Command<'a, E> {
    pub fn new<F: 'a + FnOnce() -> Result<(), E>>(commit_fn: F) -> Self {
        Self {
            commit_fn: Box::new(commit_fn),
        }
    }
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

#[cfg(test)]
mod example {
    use super::*;

    #[derive(Debug)]
    struct MyModel {
        name: String,
    }

    #[derive(Clone, Debug)]
    enum MyMark {
        Name,
        Delimiter,
    }

    impl Mark for MyMark {}

    struct View {}

    impl View {
        fn render(&self, model: &MyModel) -> Vec<MarkStr<>> {
            vec![
                (MyMark::Delimiter,"Hello, ".into()).into(),
                (MyMark::Name,model.name.as_str().into()).into(),
                (MyMark::Delimiter,"!".into()).into(),
                (MyMark::Delimiter,"\n".into()).into(),
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
            if input.context().len() != 1 {
                Err("can only act on one segment at a time for now")
            } else {
                let segment = &input.context()[0];
                match segment.marks().get::<MyMark>() {
                    Some(&MyMark::Name) => Ok(Command::new(|| Ok(()))),
                    _ => Err("cannot interpret command from attempt to edit this segment"),
                }
            }
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
            _model: model.clone(),
        };
        let document = {
            let model = model.lock().unwrap();
            View {}.render(&*model)
        };
        let input = document
            .iter()
            .into_input(Grapheme(7)..Grapheme(12), Replacement::Str("Test".into()));
        println!("{:?}", input.context());
        println!("{:?}", interpreter._model);
        //interpreter.interpret(input).expect("input should be interpretable");
    }
}
*/
