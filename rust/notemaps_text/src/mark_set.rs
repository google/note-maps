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

use core::any::Any;
use core::any::TypeId;
use std::collections::HashMap;
use std::rc::Rc;

/// A set of reference-counted "mark" values, containing up to one value per value type.
///
/// # Example
///
/// ```rust
/// use notemaps_text::MarkSet;
/// use std::rc::Rc;
///
/// let mut marks = MarkSet::new();
/// let thing_one: Rc<String> = "thing one".to_string().into();
/// let thing_two: Rc<String> = "thing two".to_string().into();
///
/// marks.push(thing_one.clone());
/// assert!(marks.contains(thing_one.as_ref()));
/// assert_eq!(marks.get::<String>(), Some(thing_one.as_ref()));
///
/// marks.push(thing_two.clone());
/// assert_eq!(marks.get::<String>(), Some(thing_two.as_ref()));
/// ```
#[derive(Clone, Default, Debug)]
pub struct MarkSet {
    map: HashMap<TypeId, Rc<dyn Any>>,
}

impl MarkSet {
    /// Create a new, empty [MarkSet].
    pub fn new() -> Self {
        Default::default()
    }

    /// Create a new [MarkSet] containing one mark, `m`.
    pub fn new_with<T: Any>(m: Rc<T>) -> Self {
        let mut self_ = Self::new();
        self_.push(m);
        self_
    }

    /// Return `true` if and only if `m` was the last mark of type `T` pushed into this [MarkSet]
    /// and it has not yet been removed.
    pub fn contains<T: Any + PartialEq>(&self, m: &T) -> bool {
        self.get::<T>() == Some(m)
    }

    /// Return `true` if and only if a mark of type `T` was pushed into this [MarkSet] and has not
    /// yet been removed.
    pub fn contains_any<T: Any>(&self) -> bool {
        self.map.contains_key(&TypeId::of::<T>())
    }

    /// Return a reference to the mark of type `T` that was last pushed into this [MarkSet] if that
    /// value has not yet been removed.
    pub fn get<T: Any>(&self) -> Option<&T> {
        self.map
            .get(&TypeId::of::<T>())
            .map(|rc| rc.as_ref().downcast_ref().expect(""))
    }

    /// Add mark `m` of type `T` into this [MarkSet]. Return the mark of type `T` that was already
    /// present, if any.
    pub fn push<T: Any>(&mut self, m: Rc<T>) -> Option<Rc<T>> {
        self.map
            .insert((&*m).type_id(), m)
            .map(|v| v.downcast().expect(""))
    }

    /// Remove from this [MarkSet] the mark of type `T`, if any.
    pub fn take_any<T: Any>(&mut self) -> Option<Rc<T>> {
        self.map
            .remove(&TypeId::of::<T>())
            .map(|rc| rc.downcast().expect(""))
    }

    /// Add to this [MarkSet] all marks from `other`. Marks of the same type in `self` will be
    /// discarded.
    pub fn push_all(&mut self, other: &Self) {
        other.map.iter().for_each(|(type_id, rc)| {
            self.map.insert(type_id.clone(), rc.clone());
        });
    }
}

impl<M: Any> From<Rc<M>> for MarkSet {
    fn from(mark: Rc<M>) -> Self {
        MarkSet::new_with(mark)
    }
}

#[cfg(test)]
mod a_bag {
    use super::*;

    #[test]
    fn pushes_new_items() {
        let mut bag = MarkSet::new();
        let one = Rc::new(1i8);
        let three = Rc::new(3i64);
        assert_eq!(bag.push(one.clone()), None);
        assert_eq!(bag.push(three.clone()), None);
    }

    #[test]
    fn confirms_push_with_contains() {
        let mut bag = MarkSet::new();
        let one = Rc::new(1i8);
        let three = Rc::new(3i64);
        assert!(!bag.contains(&*one));
        assert!(!bag.contains(&*three));
        assert_eq!(bag.push(one.clone()), None);
        assert!(bag.contains(&*one));
        assert!(!bag.contains(&*three));
        assert_eq!(bag.push(three.clone()), None);
        assert!(bag.contains(&*one));
        assert!(bag.contains(&*three));
    }

    #[test]
    fn confirms_push_with_contains_any() {
        let mut bag = MarkSet::new();
        let one = Rc::new(1i8);
        let three = Rc::new(3i64);
        assert!(!bag.contains_any::<i8>());
        assert!(!bag.contains_any::<i64>());
        assert_eq!(bag.push(one.clone()), None);
        assert!(bag.contains_any::<i8>());
        assert!(!bag.contains_any::<i64>());
        assert_eq!(bag.push(three.clone()), None);
        assert!(bag.contains_any::<i8>());
        assert!(bag.contains_any::<i64>());
    }

    #[test]
    fn confirms_push_with_get() {
        let mut bag = MarkSet::new();
        let one = Rc::new(1i8);
        let three = Rc::new(3i64);
        assert_eq!(bag.get::<i8>(), None);
        assert_eq!(bag.get::<i64>(), None);
        assert_eq!(bag.push(one), None);
        assert_eq!(bag.get(), Some(&1i8));
        assert_eq!(bag.get::<i64>(), None);
        assert_eq!(bag.push(three), None);
        assert_eq!(bag.get(), Some(&1i8));
        assert_eq!(bag.get(), Some(&3i64));
    }

    #[test]
    fn pops_old_items_when_new_are_pushed() {
        let mut bag = MarkSet::new();
        let one = Rc::new(1i8);
        let two = Rc::new(2i8);
        let three = Rc::new(3i64);
        let four = Rc::new(4i64);
        assert_eq!(bag.push(one.clone()), None);
        assert_eq!(bag.push(two.clone()), Some(one));
        assert!(!bag.contains(&1i8));
        assert!(bag.contains(&2i8));
        assert_eq!(bag.push(three.clone()), None);
        assert_eq!(bag.push(four.clone()), Some(three));
        assert!(!bag.contains(&3i64));
        assert!(bag.contains(&4i64));
    }

    #[test]
    fn pushes_all_items() {
        let mut bag0 = MarkSet::new();
        bag0.push(1i8.into());
        let mut bag1 = MarkSet::new();
        bag1.push(2i8.into());
        bag1.push(3i64.into());
        bag0.push_all(&bag1);
        assert!(!bag0.contains(&1i8));
        assert!(bag0.contains(&2i8));
        assert!(bag0.contains(&3i64));
    }

    #[test]
    fn removes_items_by_type() {
        let mut bag = MarkSet::new();
        let one = Rc::new(1i8);
        let three = Rc::new(3i64);
        assert_eq!(bag.push(one.clone()), None);
        assert_eq!(bag.push(three.clone()), None);
        assert_eq!(bag.contains_any::<i8>(), true);
        assert_eq!(bag.contains_any::<i64>(), true);
        assert_eq!(bag.take_any(), Some(one));
        assert_eq!(bag.contains_any::<i8>(), false);
        assert_eq!(bag.contains_any::<i64>(), true);
        assert_eq!(bag.take_any(), Some(three));
        assert_eq!(bag.contains_any::<i8>(), false);
        assert_eq!(bag.contains_any::<i64>(), false);
    }
}
