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

//! Some ideas about how to represent semantic text.

#![feature(associated_type_bounds)]
#![feature(extend_one)]
#![feature(generic_associated_types)]
#![feature(in_band_lifetimes)]
#![feature(iter_advance_by)]
#![feature(step_trait)]
#![feature(toowned_clone_into)]

mod cursor;
mod immutable;
mod mark_set;
mod marked;
mod markup;
mod measured;
mod slice;
mod strtype;
mod table;
mod text;

pub use cursor::*;
pub use immutable::*;
pub use mark_set::*;
pub use marked::*;
pub use markup::*;
pub use measured::*;
pub use slice::{Slice, Split};
pub use table::*;
pub use text::*;

pub mod offsets;

pub type Str = Measured<Immutable<std::rc::Rc<str>>>;
//pub type Piece = Marked<Str>;
//pub type LocalPiece = offsets::Local<Piece>;
//pub type Document = Table<Piece>;
