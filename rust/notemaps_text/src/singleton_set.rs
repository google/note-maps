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

#[derive(Clone, Default, Debug)]
pub(crate) struct SingletonnRcSet {
    map: HashMap<TypeId, Rc<dyn Any>>,
}

impl SingletonnRcSet {
    pub fn new() -> Self {
        Self {
            map: HashMap::new(),
        }
    }
    pub fn push<T: Any>(&mut self, item: Rc<T>) -> Option<Rc<T>> {
        self.map
            .insert((&*item).type_id(), item)
            .map(|v| v.downcast().expect(""))
    }
    pub fn contains<T: Any + PartialEq>(&self, item: &T) -> bool {
        self.get::<T>().map_or(false, |x| x == item)
    }
    pub fn contains_any<T: Any>(&self) -> bool {
        self.map.contains_key(&TypeId::of::<T>())
    }
    pub fn get<T: Any>(&self) -> Option<&T> {
        self.map
            .get(&TypeId::of::<T>())
            .map(|rc| rc.as_ref().downcast_ref().expect(""))
    }
    pub fn remove_any<T: Any>(&mut self) -> Option<Rc<T>> {
        self.map
            .remove(&TypeId::of::<T>())
            .map(|rc| rc.downcast().expect(""))
    }
}

#[cfg(test)]
mod a_bag {
    use super::*;

    #[test]
    fn pushes_new_items() {
        let mut bag = SingletonnRcSet::new();
        let one = Rc::new(1i8);
        let three = Rc::new(3i64);
        assert_eq!(bag.push(one.clone()), None);
        assert_eq!(bag.push(three.clone()), None);
    }

    #[test]
    fn confirms_push_with_contains() {
        let mut bag = SingletonnRcSet::new();
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
        let mut bag = SingletonnRcSet::new();
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
        let mut bag = SingletonnRcSet::new();
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
        let mut bag = SingletonnRcSet::new();
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
    fn removes_items_by_type() {
        let mut bag = SingletonnRcSet::new();
        let one = Rc::new(1i8);
        let three = Rc::new(3i64);
        assert_eq!(bag.push(one.clone()), None);
        assert_eq!(bag.push(three.clone()), None);
        assert_eq!(bag.contains_any::<i8>(), true);
        assert_eq!(bag.contains_any::<i64>(), true);
        assert_eq!(bag.remove_any(), Some(one));
        assert_eq!(bag.contains_any::<i8>(), false);
        assert_eq!(bag.contains_any::<i64>(), true);
        assert_eq!(bag.remove_any(), Some(three));
        assert_eq!(bag.contains_any::<i8>(), false);
        assert_eq!(bag.contains_any::<i64>(), false);
    }
}
