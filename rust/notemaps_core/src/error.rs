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

use automerge::InvalidChangeRequest;
use automerge::InvalidPatch;
use std::error;
use std::fmt;

/// Represents a misuse of the API.
#[derive(Debug)]
pub enum UserError {
    InvalidPatch(InvalidPatch),
    InvalidChangeRequest(InvalidChangeRequest),
    NoSuchTopic(String),
    Overflow { over: usize, max: usize },
    IndexOutOfBounds { index: usize, bound: usize },
    InvalidDocument(String),
    IncompatibleValueType,
    ConcurrencyError(String),
    DuplicateOccurrence(super::Note),
    InvalidNote(uuid::Error),
}

impl fmt::Display for UserError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        use UserError::*;
        match self {
            InvalidPatch(err) => fmt::Display::fmt(err, f),
            InvalidChangeRequest(err) => fmt::Display::fmt(err, f),
            NoSuchTopic(id) => f.write_fmt(format_args!("no such topic: {}", id)),
            Overflow { over, max } => write!(f, "{} is over the maximum of {}", over, max),
            IndexOutOfBounds { index, bound } => f.write_fmt(format_args!(
                "index out of bounds: index={}, bound={}",
                index, bound
            )),
            InvalidDocument(msg) => f.write_fmt(format_args!("invalid document: {}", msg)),
            IncompatibleValueType => f.write_str("incompatible value type"),
            ConcurrencyError(msg) => f.write_fmt(format_args!("concurrency error: {}", msg)),
            DuplicateOccurrence(id) => f.write_fmt(format_args!("duplicate occurrence: {}", id)),
            InvalidNote(err) => f.write_fmt(format_args!("invalid note: {}", err)),
        }
    }
}

impl From<InvalidPatch> for UserError {
    fn from(e: InvalidPatch) -> Self {
        Self::InvalidPatch(e)
    }
}

impl From<InvalidChangeRequest> for UserError {
    fn from(e: InvalidChangeRequest) -> Self {
        Self::InvalidChangeRequest(e)
    }
}

impl From<uuid::Error> for UserError {
    fn from(e: uuid::Error) -> Self {
        Self::InvalidNote(e)
    }
}

impl error::Error for UserError {}

/// Indicates that a read-only operation failed.
#[derive(Debug, Eq, PartialEq)]
pub enum ReadError {
    IOError(String),
}

impl fmt::Display for ReadError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        use ReadError::*;
        f.write_str("read error: ")?;
        match self {
            IOError(msg) => f.write_fmt(format_args!("I/O error: {}", msg)),
        }
    }
}

impl error::Error for ReadError {}

/// Represents a problem in the contents of a note map.
#[derive(Debug, Clone)]
pub enum Lint {
    UnrecognizedFormat(super::Field),
}
