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

/// Some ideas about treating a note map as a graph. The API might be a lot more consistent this
/// way.
///
/// Any `IntoIterator<Item=Step>` values describes a set possible paths through a graph.
///
/// use notemaps_core::base::*;
///
/// let types: Tree = [Step::types(), Step::supertypes()].into();
///
///
/// A tree can be rooted in a specific note or sequence of notes.
///
/// use notemaps_core::base::*;
///
/// let types: Tree = [Step::types(), Step::supertypes()].into();
/// let rooted: RootedTree = Some(Note::random())
///     .into_rooted_tree()
///     .extend([Step::types(), Step::supertypes()]);
///
///
/// Any iterable of Note values can be treated as a "root":
///
/// TODO
use super::Note;

pub mod builders {

    use super::Note;
    use super::Predicate;
    use super::Step;

    #[derive(Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
    pub enum Component {
        Step(Step),
        Predicate(Box<Predicate>), // something magical?
    }
    impl From<Step> for Component {
        fn from(step: Step) -> Self {
            Self::Step(step)
        }
    }
    impl From<Predicate> for Component {
        fn from(predicate: Predicate) -> Self {
            Self::Predicate(Box::new(predicate))
        }
    }

    #[derive(Default)]
    pub struct Segment {
        steps: Vec<Component>,
    }
    impl Segment {
        pub fn builder() -> SegmentBuilder {
            SegmentBuilder::default()
        }
    }
    impl From<SegmentBuilder> for Segment {
        fn from(builder: SegmentBuilder) -> Self {
            Self {
                steps: builder.steps,
            }
        }
    }
    impl IntoIterator for Segment {
        type Item = Component;
        type IntoIter = std::vec::IntoIter<Component>;
        fn into_iter(self) -> Self::IntoIter {
            self.steps.into_iter()
        }
    }
    impl From<Step> for Segment {
        fn from(step: Step) -> Self {
            Self {
                steps: vec![step.into()],
            }
        }
    }
    impl From<Predicate> for Segment {
        fn from(p: Predicate) -> Self {
            Self {
                steps: vec![p.into()],
            }
        }
    }
    impl<const N: usize> From<[Step; N]> for Segment {
        fn from(steps: [Step; N]) -> Self {
            Self {
                steps: steps.into_iter().map(Into::into).collect(),
            }
        }
    }
    impl FromIterator<Step> for Segment {
        fn from_iter<I: IntoIterator<Item = Step>>(src: I) -> Self {
            Self {
                steps: src.into_iter().map(Into::into).collect(),
            }
        }
    }
    impl FromIterator<Component> for Segment {
        fn from_iter<I: IntoIterator<Item = Component>>(src: I) -> Self {
            Self {
                steps: src.into_iter().collect(),
            }
        }
    }
    impl FromIterator<Segment> for Segment {
        fn from_iter<I: IntoIterator<Item = Segment>>(src: I) -> Self {
            Self {
                steps: src.into_iter().flatten().collect(),
            }
        }
    }

    #[derive(Default)]
    pub struct SegmentBuilder {
        steps: Vec<Component>,
    }
    impl SegmentBuilder {
        fn into_segment(self) -> Segment {
            Segment::from(self)
        }
        fn push_step(&mut self, steps: Segment) {
            self.steps.extend(steps);
        }
        pub fn step<S: Into<Segment>>(mut self, step: S) -> Self {
            self.push_step(step.into());
            self
        }
        pub fn branch<T: Into<Tree>>(self, branch: T) -> TreeBuilder {
            TreeBuilder::from(self.into_segment()).branch(branch)
        }
    }
    impl Extend<Step> for SegmentBuilder {
        fn extend<T: IntoIterator<Item = Step>>(&mut self, iter: T) {
            self.steps.extend(iter.into_iter().map(Into::into))
        }
    }

    #[derive(Default)]
    pub struct Tree {
        trunk: Segment,
        branches: Vec<Tree>,
    }
    impl Tree {
        fn new_branchless<T: Into<Segment>>(trunk: T) -> Self {
            Self {
                trunk: trunk.into(),
                branches: Default::default(),
            }
        }
        pub fn builder() -> TreeBuilder {
            TreeBuilder::default()
        }
    }
    impl From<TreeBuilder> for Tree {
        fn from(trunk: TreeBuilder) -> Self {
            let builder: TreeBuilder = trunk.into();
            Self {
                trunk: builder.trunk,
                branches: builder.branches,
            }
        }
    }
    impl From<Segment> for Tree {
        fn from(trunk: Segment) -> Self {
            Self::new_branchless(trunk)
        }
    }
    impl From<SegmentBuilder> for Tree {
        fn from(trunk: SegmentBuilder) -> Self {
            Self::new_branchless(trunk)
        }
    }

    #[derive(Default)]
    pub struct TreeBuilder {
        trunk: Segment,
        branches: Vec<Tree>,
    }
    impl TreeBuilder {
        fn push_branch(&mut self, branch: Tree) {
            self.branches.push(branch);
        }
        pub fn branch<T: Into<Tree>>(mut self, branch: T) -> Self {
            self.push_branch(branch.into());
            self
        }
    }
    impl From<Segment> for TreeBuilder {
        fn from(trunk: Segment) -> Self {
            Self {
                trunk,
                branches: Default::default(),
            }
        }
    }
    impl From<Tree> for TreeBuilder {
        fn from(tree: Tree) -> Self {
            Self {
                trunk: tree.trunk,
                branches: tree.branches,
            }
        }
    }

    /// An inference rule made up of "antecedent" conditions and "consequent" facts.
    #[derive(Default)]
    pub struct Rule {}
    impl Rule {
        pub fn new(_consequent: ConsequentBuilder, _antecedent: AntecedentBuilder) -> Self {
            Self {}
        }
    }

    #[derive(Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
    pub enum Term {
        Constant(Note),
        Variable(String),
    }
    impl From<Note> for Term {
        fn from(note: Note) -> Self {
            Self::Constant(note)
        }
    }
    impl<'a> From<&'a str> for Term {
        fn from(name: &'a str) -> Self {
            Self::Variable(name.into())
        }
    }

    pub enum TermAxis {
        Types,
        Supertypes,
        Associations(Term),
        Roles,
        Traverse(Term, Term),
    }

    #[test]
    fn term_tests() {
        let _constant: Term = Note::random().into();
        let _variable: Term = "hat".into();
    }

    #[derive(Default)]
    pub struct AntecedentBuilder {}
    impl AntecedentBuilder {
        pub fn require<A: Into<Term>, B: Into<Tree>, C: Into<Term>>(
            self,
            _root: A,
            _tree: B,
            _leaf: C,
        ) -> Self {
            self
        }
    }

    #[derive(Default)]
    pub struct ConsequentBuilder {
        triples: Vec<(Term, TermAxis, Term)>,
    }
    impl ConsequentBuilder {
        fn push_triple(&mut self, src: Term, axis: TermAxis, dst: Term) {
            self.triples.push((src, axis, dst));
        }
        fn triple(mut self, src: Term, axis: TermAxis, dst: Term) -> Self {
            self.push_triple(src, axis, dst);
            self
        }
        pub fn instance_type(self, instance: Term, typ: Term) -> Self {
            self.triple(instance, TermAxis::Types, typ)
        }
        pub fn role_player<A: Into<Term>, B: Into<Term>, C: Into<Term>>(
            self,
            association: A,
            role_type: B,
            player: C,
        ) -> Self {
            // The 'Associations' axis is enough to capture this fact:
            self.triple(
                player.into(),
                TermAxis::Associations(role_type.into()),
                association.into(),
            )
            /*
            // Just as an example for now, this is how the rest of the association-related axes
            // could be inferred from what we know so far:
            self.push_triple(association, TermAxis::Roles, role_type);
            for (src, axis, other_player) in self.triples {
                if *src == association {
                    if let TermAxis::Associations(other_role_type) = axis {
                        // TODO: skip if adding loopback:
                        self.push_triple(
                            player,
                            TermAxis::Traverse(role_type, *other_role_type),
                            *other_player,
                        );
                    }
                }
            }
            */
        }
    }

    #[test]
    fn test_new_api() {
        // Build an arbitrary tree making use of various type conversions:
        SegmentBuilder::default()
            .step(Step::types())
            .step([Step::supertypes(), Step::supertypes_transitive()])
            .branch(Segment::from([Step::instances()]))
            .branch(Segment::from(Step::supertypes()));
        // Build a rule that maps Root to all of its types, both direct and indirect, along the
        // Traverse(INSTANCE, TYPE) axis.
        let _infer_direct_types_from_indirect_types = Rule::new(
            ConsequentBuilder::default()
                .role_player("hashed", Note::INSTANCE, "instance")
                .role_player("hashed", Note::TYPE, "type"),
            AntecedentBuilder::default().require(
                "instance",
                Segment::builder().step([Step::types(), Step::supertypes_transitive()]),
                "type",
            ),
        );
    }
}

pub mod primitives {
    use super::Note;

    #[derive(Clone, Debug, PartialEq, Eq, Hash, Ord, PartialOrd)]
    pub enum Value {
        Binary { data: Vec<u8>, data_type: Note },
        Text(String),
        Note(Note),
    }

    impl Value {
        pub fn date_type(&self) -> Note {
            match self {
                Value::Binary { data: _, data_type } => *data_type,
                Value::Text(_) => Note::DATA_TYPE_UTF8,
                Value::Note(_) => Note::DATA_TYPE_NOTE,
            }
        }
    }
}

mod navigation {
    use super::Note;
    use core::ops;
    use std::collections::HashSet;
    use std::iter;

    /// Describes an axis along which navigation might proceed.
    ///
    /// Every step of navigation can be described as movement along an [Axis].
    #[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, Ord, PartialOrd)]
    pub enum Axis {
        /// Leads from any note directly back to that note.
        Loopback,

        /// From a note to the types of that note (which are also notes).
        Types,

        /// From a type to the supertypes of which it is a subtype.
        Supertypes,

        /// From a topic to the associations it plays a role in, constrained by role type.
        Associations(Note),

        /// From an association to the types of the roles played in it.
        Roles,

        /// From a note to the notes it is associated with, constrained by local and remote role
        /// type.
        ///
        /// In principle, it should be possible to use this type of step to emulate the Types,
        /// Instances, Supertypes, and Subtypes steps above. However, in practice, it will be
        /// helpful to be able to use those more specific steps in the implementation of this more
        /// complex one.
        Traverse(Note, Note),
    }

    impl Axis {
        /// Creates a [Step] value that specifies moving forward along this [Axis].
        pub const fn forward(self) -> Step {
            Step::new(self, Direction::Forward)
        }

        /// Creates a [Step] value that specifies moving in reverse along this [Axis].
        pub const fn reverse(self) -> Step {
            Step::new(self, Direction::Reverse)
        }
    }

    /// Describes the direction of navigation along some [Axis].
    ///
    /// An [Axis] together with a [Direction] constitue a [Step].
    #[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]
    pub enum Direction {
        Forward,
        Reverse,
    }

    impl Direction {
        /// Equivalelnt to `self == Direction::Forward`.
        ///
        /// Intended to support inspecting a [Direction] without needing to import yet another name
        /// into a module's namespace.
        pub fn is_forward(self) -> bool {
            self == Self::Forward
        }

        /// Equivalelnt to `self == Direction::Reverse`.
        ///
        /// Intended to support inspecting a [Direction] without needing to import yet another name
        /// into a module's namespace.
        pub fn is_reverse(self) -> bool {
            self == Self::Reverse
        }
    }

    /// Negation is implemented to support flipping a direction: negating `Direction::Forward`
    /// produces `Direction::Reverse`, and vice versa.
    impl ops::Neg for Direction {
        type Output = Direction;

        fn neg(self) -> Self {
            match self {
                Self::Forward => Self::Reverse,
                Self::Reverse => Self::Forward,
            }
        }
    }

    /// Describes a step that might be taken from any node to a set of adjacent nodes in a graph
    /// representation of a note map.
    #[derive(Clone, Debug, PartialEq, Eq, Hash, Ord, PartialOrd)]
    pub struct Step {
        axis: Axis,
        direction: Direction,
        depth: Depth,
        predicates: Vec<Predicate>, // TODO: move this to a separate type
    }

    #[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, Ord, PartialOrd)]
    enum Depth {
        Direct,
        Transitive,
    }

    /// Originally part of each step, this probably belongs at a higher level in the overall query.
    /// TODO: use this enum in the right place.
    #[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, Ord, PartialOrd)]
    pub enum Ordering {
        /// Visit every occurrence of a Note when evaluating a given Step, maintaining the original
        /// ordering.
        Exhaustive,
        /// Visit only the first occurrence of a Note when evaluating a given Step, maintaining the
        /// original ordering.
        Unique,
        /// Visit only the first occurrence of a Note when evaluating a given Step, and visit the
        /// notes in any order, even changing the order from evaluation to evaluation.
        Unordered,
    }

    impl Step {
        /// Creates a new value that describes a step along the given axis in the given direction.
        ///
        /// The public API for creating a [Step] is the [Axis] methods [Axis::forward] and
        /// [Axis::backward].
        const fn new(axis: Axis, direction: Direction) -> Self {
            Self {
                axis,
                direction,
                depth: Depth::Direct,
                predicates: Vec::new(),
            }
        }

        /// Returns the axis of this step.
        pub fn axis(&self) -> Axis {
            self.axis
        }

        /// Returns the direction of this step.
        pub fn direction(&self) -> Direction {
            self.direction
        }

        /// Returns true if and only if this step is a transitive step.
        pub fn transitive(&self) -> bool {
            self.depth == Depth::Transitive
        }

        /// Returns true if and only if this step will navigate to no node more than once.
        pub fn unique(&self) -> bool {
            self.depth == Depth::Transitive
        }

        /// Transforms self into a transitive step.
        ///
        /// A transitive step is a sequence of steps that will stop only when there are no further
        /// steps to take.
        ///
        /// Transitive steps are always unique.
        pub const fn with_transitive(mut self) -> Self {
            self.depth = Depth::Transitive;
            self
        }

        /// Transorms self into a step that also filters destination steps to those that match the
        /// given predicate.
        pub fn with_predicate(mut self, predicate: Predicate) -> Self {
            self.predicates.push(predicate);
            self
        }

        /// Tries to create a [Step] that has the same meaning but that is easier to process,
        /// especially when boot-strapping a graph with built-in types.
        ///
        /// Returns [None] if no such simplification can be performed.
        pub fn try_simplify(&self) -> Option<Step> {
            let mut copy = self.clone();
            match self.axis {
                Axis::Traverse(Note::SUBTYPE, Note::SUPERTYPE) => {
                    copy.axis = Axis::Supertypes;
                    Some(copy)
                }
                Axis::Traverse(Note::SUPERTYPE, Note::SUBTYPE) => {
                    copy.axis = Axis::Supertypes;
                    copy.direction = -copy.direction;
                    Some(copy)
                }
                Axis::Traverse(Note::INSTANCE, Note::TYPE) => {
                    copy.axis = Axis::Types;
                    Some(copy)
                }
                Axis::Traverse(Note::TYPE, Note::INSTANCE) => {
                    copy.axis = Axis::Types;
                    copy.direction = -copy.direction;
                    Some(copy)
                }
                _ => None,
            }
        }

        pub fn loopback() -> Self {
            Axis::Loopback.forward()
        }
        pub fn supertypes() -> Self {
            Axis::Supertypes.forward()
        }
        pub fn supertypes_transitive() -> Self {
            Axis::Supertypes.forward().with_transitive()
        }
        pub fn subtypes() -> Self {
            Axis::Supertypes.reverse()
        }
        pub fn subtypes_transitive() -> Self {
            Axis::Supertypes.reverse().with_transitive()
        }
        pub fn types() -> Self {
            Axis::Types.forward()
        }
        pub fn instances() -> Self {
            Axis::Types.reverse()
        }
        pub fn traverse(from_role: Note, to_role: Note) -> Self {
            Axis::Traverse(from_role, to_role).forward()
        }
    }

    /// Adding any step to a path followed by the negation of that step should resemble a no-op.
    /// In practice, the result may include more duplicates of a note since some steps are
    /// one-to-many and there no steps that remove duplicates.
    impl ops::Neg for Step {
        type Output = Step;

        fn neg(self) -> Step {
            Self::new(self.axis, -self.direction)
        }
    }

    /// As a special case, adding two [Step] values produces a [Navigate] value based on embarking
    /// from an empty set of notes in an [Empty] graph.
    ///
    /// Intended for easy description of hypothetical navigations, especially in "filter"
    /// expressions.
    ///
    /// There's room for improvement here because it's a bit too surprising.
    impl ops::Add<Step> for Step {
        type Output = Path;

        fn add(self, other: Step) -> Self::Output {
            Path::from([self, other])
        }
    }

    /// Describes a path through a graph as an abstract sequence of [Step], not bound to
    /// any particular graph or starting notes.
    ///
    /// For example, we can build a [Path] that describes navigating to the type of a note and,
    /// from there, to all instances of that type:
    /// ```
    /// use notemaps_core::base::{Step, PathBuilder};
    /// Step::types().instances();
    /// ```
    #[derive(Clone, Debug, Default, PartialEq, Eq, Hash, Ord, PartialOrd)]
    pub struct Path {
        vec: Vec<Step>,
    }

    impl From<Vec<Step>> for Path {
        fn from(src: Vec<Step>) -> Self {
            Self {
                vec: src.into_iter().map(Into::into).collect(),
            }
        }
    }

    impl<const N: usize> From<[Step; N]> for Path {
        fn from(src: [Step; N]) -> Self {
            Self {
                vec: src.into_iter().collect(),
            }
        }
    }

    impl From<Step> for Path {
        fn from(src: Step) -> Self {
            Self { vec: vec![src] }
        }
    }
    impl FromIterator<Step> for Path {
        fn from_iter<I: IntoIterator<Item = Step>>(src: I) -> Self {
            Self {
                vec: src.into_iter().collect(),
            }
        }
    }

    impl Extend<Step> for Path {
        fn extend<T: IntoIterator<Item = Step>>(&mut self, iter: T) {
            self.vec.extend(iter)
        }
        fn extend_reserve(&mut self, additional: usize) {
            Extend::<Step>::extend_reserve(&mut self.vec, additional);
        }
    }

    impl IntoIterator for Path {
        type Item = Step;
        type IntoIter = std::vec::IntoIter<Step>;
        fn into_iter(self) -> Self::IntoIter {
            self.vec.into_iter()
        }
    }

    pub struct Triple(Note, Axis, Note);
    impl Triple {
        pub fn src(&self) -> Note {
            self.0
        }
        pub fn axis(&self) -> Axis {
            self.1
        }
        pub fn dst(&self) -> Note {
            self.2
        }
    }

    /// Describes a path through a graph as an abstract sequence of [Step] from a given set of
    /// starting notes, not bound to any particular graph.
    #[derive(Clone, Debug, PartialEq, Eq, Hash)]
    pub struct AnchoredStep {
        anchor: Vec<Note>,
        step: Step,
    }

    impl AnchoredStep {
        pub fn new<I: IntoIterator<Item = Note>>(anchor: I, step: Step) -> Self {
            Self {
                anchor: anchor.into_iter().collect(),
                step,
            }
        }

        pub fn all<N: IntoIterator<Item = Note>>(self, dsts: N) -> Vec<Triple> {
            let dsts: Vec<Note> = dsts.into_iter().collect();
            let note_pairs = self
                .anchor
                .iter()
                .flat_map(|src| iter::zip(iter::repeat(src), dsts.iter().copied()));
            match self.step.direction() {
                Direction::Forward => note_pairs
                    .map(|(src, dst)| Triple(*src, self.step.axis(), dst))
                    .collect(),
                Direction::Reverse => note_pairs
                    .map(|(dst, src)| Triple(src, self.step.axis(), *dst))
                    .collect(),
            }
        }
    }

    /// Describes a path through a graph as an abstract sequence of [Step] from a given set of
    /// starting notes, not bound to any particular graph.
    #[derive(Clone, Debug, Default, PartialEq, Eq, Hash)]
    pub struct AnchoredPath {
        anchor: Vec<Note>,
        path: Path,
    }

    impl AnchoredPath {
        pub fn new<N: IntoIterator<Item = Note>, S: IntoIterator<Item = Step>>(
            anchor: N,
            step: S,
        ) -> Self {
            Self {
                anchor: anchor.into_iter().collect(),
                path: step.into_iter().collect(),
            }
        }
    }

    impl From<Note> for AnchoredPath {
        fn from(note: Note) -> Self {
            Self {
                anchor: vec![note],
                path: Default::default(),
            }
        }
    }

    impl From<AnchoredStep> for AnchoredPath {
        fn from(src: AnchoredStep) -> Self {
            Self {
                anchor: src.anchor,
                path: src.step.into(),
            }
        }
    }

    impl Extend<Step> for AnchoredPath {
        fn extend<T: IntoIterator<Item = Step>>(&mut self, iter: T) {
            self.path.extend(iter);
        }

        fn extend_reserve(&mut self, additional: usize) {
            self.path.extend_reserve(additional);
        }
    }

    /*
        mod x {
            /*

            trait IntoPath {
                type Path: Extend<Step> + IntoIterator<Item = Step>;
                fn into_path(self) -> Self::Path;
            }

            impl<T: Extend<Step> + IntoIterator<Item = Step>> IntoPath for T {
                type Path = Self;
                fn into_path(self) -> Self::Path {
                    self.extend_one(step);
                }
            }

            pub trait IntoAnchor {
                type Anchor: IntoIterator<Item=Note>;
                fn into_anchor(self)->Self::Anchor;
            }

            impl<T:IntoIterator<Item=Note>> Anchor for T {
                type Anchor= <Self as IntoIterator>::IntoIter
                fn into_anchor(self)->Self::Anchor;
            }

            pub trait IntoPath {
                type Path:  IntoIterator<Item = Step>;
                fn into_path(self) -> Self::Path;
            }

            */

            use super::Step;

            pub trait Path: Extend<Step> + IntoIterator<Item = Step> {
                type Path: Extend<Step> + IntoIterator<Item = Step>;

                fn to_path(&self) -> Self::Path;

                fn to_path_with_step(&self, step: Step) -> Self::Path {
                    let mut path = self.to_path();
                    path.extend_one(step);
                    path
                }

                fn supertypes(self) -> Self::Path {
                    self.to_path_with_step(Step::supertypes())
                }

                fn supertypes_transitive(self) -> Self::Path {
                    self.to_path_with_step(Step::supertypes()).with_transitive()
                }
            }

            //impl<T> Path for T where T: Extend<Step>+IntoIterator<Item=Step> { type Path=Self; fn to_path(self)->Self::Path{self} }
        }
    */

    /// PathBuilder is automatically implemented for every type that implements [Extend] for
    /// [Step] (`Extend<Step>`). It is also implemented for [Note].
    pub trait PathBuilder: internal_steps::Sealed {
        type Steps: PathBuilder;
        fn supertypes(self) -> Self::Steps;
        fn supertypes_transitive(self) -> Self::Steps;
        fn subtypes(self) -> Self::Steps;
        fn subtypes_transitive(self) -> Self::Steps;
        fn types(self) -> Self::Steps;
        fn instances(self) -> Self::Steps;
        fn traverse(self, from_role: Note, to_role: Note) -> Self::Steps;
        fn filter<F>(self, f: F) -> Self::Steps
        where
            F: FnOnce(PredicateBuilder) -> Predicate;
    }

    mod internal_steps {
        use super::*;

        pub trait Sealed {}
        impl Sealed for Path {}
        impl Sealed for Step {}
        impl Sealed for AnchoredStep {}
        impl Sealed for AnchoredPath {}
        impl Sealed for PredicateBuilder {}

        pub trait Automatic: Extend<Step> {}
        impl Automatic for Path {}
        impl Automatic for AnchoredPath {}
        impl Automatic for PredicateBuilder {}
    }

    impl PathBuilder for Step {
        type Steps = Path;
        fn supertypes(self) -> Self::Steps {
            Path::from([self, Step::supertypes()])
        }
        fn supertypes_transitive(self) -> Self::Steps {
            Path::from([self, Step::supertypes_transitive()])
        }
        fn subtypes(self) -> Self::Steps {
            Path::from([self, Step::subtypes()])
        }
        fn subtypes_transitive(self) -> Self::Steps {
            Path::from([self, Step::subtypes_transitive()])
        }
        fn types(self) -> Self::Steps {
            Path::from([self, Step::types()])
        }
        fn instances(self) -> Self::Steps {
            Path::from([self, Step::instances()])
        }
        fn traverse(self, from_role: Note, to_role: Note) -> Self::Steps {
            Path::from([self, Step::traverse(from_role, to_role)])
        }
        fn filter<F>(mut self, f: F) -> Self::Steps
        where
            F: FnOnce(PredicateBuilder) -> Predicate,
        {
            self.predicates.push(f(PredicateBuilder::new()));
            Path::from([self])
        }
    }

    impl PathBuilder for AnchoredStep {
        type Steps = AnchoredPath;
        fn supertypes(self) -> Self::Steps {
            AnchoredPath::new(self.anchor, self.step.supertypes())
        }
        fn supertypes_transitive(self) -> Self::Steps {
            AnchoredPath::new(self.anchor, self.step.supertypes_transitive())
        }
        fn subtypes(self) -> Self::Steps {
            AnchoredPath::new(self.anchor, self.step.subtypes())
        }
        fn subtypes_transitive(self) -> Self::Steps {
            AnchoredPath::new(self.anchor, self.step.subtypes_transitive())
        }
        fn types(self) -> Self::Steps {
            AnchoredPath::new(self.anchor, self.step.types())
        }
        fn instances(self) -> Self::Steps {
            AnchoredPath::new(self.anchor, self.step.instances())
        }
        fn traverse(self, from_role: Note, to_role: Note) -> Self::Steps {
            AnchoredPath::new(self.anchor, self.step.traverse(from_role, to_role))
        }
        fn filter<F>(self, _f: F) -> Self::Steps
        where
            F: FnOnce(PredicateBuilder) -> Predicate,
        {
            todo!("");
            //AnchoredPath::new(self.anchor, self.step.filter(f))
        }
    }

    impl<T: internal_steps::Automatic + internal_steps::Sealed> PathBuilder for T {
        type Steps = T;

        fn supertypes(mut self) -> Self::Steps {
            self.extend_one(Step::supertypes());
            self
        }

        fn supertypes_transitive(mut self) -> Self::Steps {
            self.extend_one(Step::supertypes_transitive());
            self
        }

        fn subtypes(mut self) -> Self::Steps {
            self.extend_one(Step::subtypes());
            self
        }

        fn subtypes_transitive(mut self) -> Self::Steps {
            self.extend_one(Step::subtypes_transitive());
            self
        }

        fn types(mut self) -> Self::Steps {
            self.extend_one(Step::types());
            self
        }

        fn instances(mut self) -> Self::Steps {
            self.extend_one(Step::instances());
            self
        }

        fn traverse(mut self, from_role: Note, to_role: Note) -> Self::Steps {
            self.extend_one(Step::traverse(from_role, to_role));
            self
        }

        fn filter<F>(mut self, f: F) -> Self::Steps
        where
            F: FnOnce(PredicateBuilder) -> Predicate,
        {
            self.extend_one(
                Axis::Loopback
                    .forward()
                    .with_predicate(f(PredicateBuilder::new())),
            );
            self
        }
    }

    /// Expresses a claim about the membership or non-membership of one or more notes as a
    /// predicate that can be applied to test the claim against any set of notes.
    ///
    ///
    /// let (a, b, c) = (Note::random(), Note::random(), Note::random());
    /// assert!(Membership::Include(a).check([a, b, c]));
    #[derive(Clone, Debug, PartialEq, Eq, Hash, Ord, PartialOrd)]
    enum Membership {
        Include(Note),
    }
    impl Membership {
        fn check<N: IntoIterator<Item = Note>>(&self, notes: N) -> bool {
            match self {
                Membership::Include(needle) => notes.into_iter().any(|member| member == *needle),
            }
        }
    }
    #[cfg(test)]
    mod membership {
        use super::*;
        #[test]
        fn test_check() {
            let (a, b, c) = (Note::random(), Note::random(), Note::random());
            assert!(!Membership::Include(a).check([]));
            assert!(!Membership::Include(a).check([b]));
            assert!(!Membership::Include(a).check([b, c]));
            assert!(Membership::Include(a).check([a]));
            assert!(Membership::Include(a).check([a, b, c]));
            assert!(Membership::Include(a).check([b, a, c]));
            assert!(Membership::Include(a).check([b, c, a]));
        }
    }

    /// Describes an expression that can be used to include or exclude notes from a query.
    ///
    /// Use a [PredicateBuilder] to build a [Predicate].
    ///
    /// use notemaps_core::*;
    /// use notemaps_core::base::*;
    ///
    /// fn only_occurrences(p: PredicateBuilder) -> Predicate {
    ///   p.types().supertypes_transitive().contains(Note::OCCURRENCE)
    /// }
    #[derive(Clone, Debug, PartialEq, Eq, Hash, Ord, PartialOrd)]
    pub struct Predicate {
        path: Path,
        members: Membership,
    }

    impl Predicate {
        pub fn filter<G: IntoAdjacentNotes, N: IntoIterator<Item = Note>>(
            &self,
            graph: G,
            notes: N,
        ) -> Filter<G, <N as IntoIterator>::IntoIter> {
            Filter {
                graph,
                srcs: notes.into_iter(),
                path: self.path.clone(),
                wanted: self.members.clone(),
            }
        }
    }

    /// Filter is the type of value returned by [Predicate::filter].
    pub struct Filter<G: IntoAdjacentNotes, N: Iterator<Item = Note>> {
        graph: G,
        srcs: N,
        path: Path,
        wanted: Membership,
    }

    impl<G: IntoAdjacentNotes, N: Iterator<Item = Note>> Iterator for Filter<G, N> {
        type Item = Note;
        fn next(&mut self) -> Option<Note> {
            loop {
                match self.srcs.next() {
                    None => {
                        return None;
                    }
                    Some(src) => {
                        if self.wanted.check(IntoIter::new(
                            self.graph,
                            vec![src],
                            self.path.clone(),
                        )) {
                            return Some(src);
                        }
                    }
                }
            }
        }
    }

    // TODO: collapse this into the `Predicate` type.
    #[derive(Clone, Debug, PartialEq, Eq)]
    pub struct PredicateBuilder {
        path: Path,
    }

    impl PredicateBuilder {
        pub fn new() -> Self {
            Self {
                path: Default::default(),
            }
        }
        pub fn contains(self, note: Note) -> Predicate {
            Predicate {
                path: self.path,
                members: Membership::Include(note),
            }
        }
    }

    impl Extend<Step> for PredicateBuilder {
        fn extend<T: IntoIterator<Item = Step>>(&mut self, iter: T) {
            self.path.extend(iter)
        }
        fn extend_reserve(&mut self, additional: usize) {
            self.path.extend_reserve(additional)
        }
    }

    /// A graph query that can be evaluated through the [Graph::navigate] method.
    #[derive(Clone, Debug, PartialEq, Eq, Hash)]
    pub struct Query {
        anchored_path: AnchoredPath,
    }

    impl From<Note> for Query {
        fn from(x: Note) -> Query {
            Query {
                anchored_path: x.into(),
            }
        }
    }

    impl From<AnchoredStep> for Query {
        fn from(x: AnchoredStep) -> Query {
            Query {
                anchored_path: x.into(),
            }
        }
    }

    impl From<AnchoredPath> for Query {
        fn from(x: AnchoredPath) -> Query {
            Query { anchored_path: x }
        }
    }

    #[cfg(test)]
    mod test_query {
        use super::*;

        #[test]
        fn query_api_makes_sense() {
            let episode = Note::random();
            let character = Note::random();
            let child = Note::random();
            let parent = Note::random();
            let wields = Note::random();
            let tool = Note::random();
            let the_force = Note::random();

            let episodes = episode.instances();
            let people = episodes.traverse(Note::TOPIC, character);
            let jedi = people.filter(|person| person.traverse(wields, tool).contains(the_force));
            let graph = Empty::default();
            assert_eq!(
                graph
                    .navigate(jedi.traverse(child, parent))
                    .into_iter()
                    .next(),
                None
            );
        }
    }

    /// Navigate describes a sequence of [Step]s to navigate through from a starting set of notes
    /// within a graph.
    ///
    /// It represents the set of final destination notes reached by navigating through each [Step],
    /// in sequence, from the starting set of notes.
    #[derive(Clone, Debug)]
    pub struct Navigate<G: IntoAdjacentNotes> {
        graph: G,
        embark: Vec<Note>,
        steps: Vec<Step>,
    }

    impl<G: IntoAdjacentNotes> Navigate<G> {
        fn new<N: IntoIterator<Item = Note>, S: IntoIterator<Item = Step>>(
            graph: G,
            embark: N,
            steps: S,
        ) -> Self {
            Self {
                graph,
                embark: embark.into_iter().collect(),
                steps: steps.into_iter().collect(),
            }
        }

        pub fn navigate(mut self, step: Step) -> Self {
            // TODO: rename to "with_step"
            self.steps.push(step);
            self
        }

        pub fn into_leafs(self) -> IntoIter<G> {
            IntoIter::new(self.graph, self.embark, self.steps)
        }
    }

    impl<G: IntoAdjacentNotes> Extend<Step> for Navigate<G> {
        fn extend<T: IntoIterator<Item = Step>>(&mut self, iter: T) {
            self.steps.extend(iter)
        }
        fn extend_reserve(&mut self, additional: usize) {
            Extend::<Step>::extend_reserve(&mut self.steps, additional);
        }
    }

    impl<G: IntoAdjacentNotes> ops::Add<Step> for Navigate<G> {
        type Output = Navigate<G>;
        fn add(self, step: Step) -> Self::Output {
            self.navigate(step)
        }
    }

    impl<G: IntoAdjacentNotes> IntoIterator for Navigate<G> {
        type Item = Note;
        type IntoIter = IntoIter<G>;

        fn into_iter(self) -> Self::IntoIter {
            self.into_leafs()
        }
    }

    mod internal {
        use super::*;

        /// Intended to remain private to this crate.
        pub struct Frame<G: IntoAdjacentNotes> {
            graph: G,
            step: Step,
            transitive: Vec<<<G as IntoAdjacentNotes>::AdjacentNotes as IntoIterator>::IntoIter>,
            unique: HashSet<Note>,
        }

        impl<G: IntoAdjacentNotes> Frame<G> {
            pub fn new(graph: G, step: Step) -> Self {
                Frame {
                    graph,
                    step,
                    transitive: Default::default(),
                    unique: Default::default(),
                }
            }
            pub fn set_src(&mut self, src: Note) {
                self.transitive.push(
                    self.graph
                        .into_adjacent_notes(src, self.step.axis(), self.step.direction())
                        .into_iter(),
                );
            }
        }

        /// Iterates through the notes at the end of the step this Navigate was built with.
        impl<G: IntoAdjacentNotes> Iterator for Frame<G> {
            type Item = Note;

            fn next(&mut self) -> Option<Note> {
                loop {
                    if let Some(note) = match &mut self.transitive.last_mut() {
                        Some(iter) => iter.next(),
                        None => None,
                    } {
                        if self.step.unique() {
                            if self.unique.contains(&note) {
                                continue;
                            } else {
                                self.unique.insert(note);
                            }
                            if self.step.transitive() {
                                self.transitive.push(
                                    self.graph
                                        .into_adjacent_notes(
                                            note,
                                            self.step.axis(),
                                            self.step.direction(),
                                        )
                                        .into_iter(),
                                );
                            }
                        }
                        return Some(note);
                    } else {
                        return None;
                    }
                }
            }
        }

        /// Intended to remain private to this crate.
        pub struct FrameSlice<'a, G: IntoAdjacentNotes>(&'a mut [Frame<G>]);

        impl<'a, G: IntoAdjacentNotes> FrameSlice<'a, G> {
            pub fn new(slice: &'a mut [Frame<G>]) -> Self {
                Self(slice)
            }
            pub fn next_notes(&mut self, notes: &mut [Note]) -> bool {
                match self.0.len() {
                    0 => false,
                    1 => match self.0[0].next() {
                        Some(note) => {
                            notes[1] = note;
                            true
                        }
                        None => false,
                    },
                    _ => loop {
                        if FrameSlice(&mut self.0[1..]).next_notes(&mut notes[1..]) {
                            return true;
                        }
                        if let Some(src) = self.0[0].next() {
                            notes[1] = src;
                            self.0[1].set_src(src);
                        } else {
                            return false;
                        }
                    },
                }
            }
        }

        impl<'a, G: IntoAdjacentNotes> Iterator for FrameSlice<'a, G> {
            type Item = Note;
            fn next(&mut self) -> Option<Self::Item> {
                match self.0.len() {
                    0 => None,
                    1 => self.0[0].next(),
                    _ => FrameSlice(&mut self.0[1..]).next().or_else(|| {
                        self.0[0].next().and_then(|src: Note| {
                            self.0[1].set_src(src);
                            FrameSlice(&mut self.0[1..]).next()
                        })
                    }),
                }
            }
        }
    }

    /// IntoPaths is the type of the iterator returned by [Navigate::into_iter].
    ///
    /// TODO: follow guidance in std::iter::Iterator to make this this implementation is
    /// well-behaved in all the right ways.
    pub struct IntoIter<G: IntoAdjacentNotes> {
        embark: std::vec::IntoIter<Note>,
        frames: Vec<internal::Frame<G>>,
        path: Vec<Note>,
    }

    impl<G: IntoAdjacentNotes> IntoIter<G> {
        fn new<S: IntoIterator<Item = Step>>(graph: G, embark: Vec<Note>, steps: S) -> Self {
            use internal::Frame;
            let frames: Vec<internal::Frame<G>> = steps
                .into_iter()
                .map(|step| Frame::new(graph, step))
                .collect();
            let path = iter::repeat(Note::default())
                .take(1 + frames.len())
                .collect();
            Self {
                embark: embark.into_iter(),
                frames,
                path,
            }
        }
    }

    impl<G: IntoAdjacentNotes> Iterator for IntoIter<G> {
        type Item = Note;

        fn next(&mut self) -> Option<Note> {
            loop {
                // Continue from where we left off according to FrameSlice.
                if internal::FrameSlice::new(&mut self.frames[..]).next_notes(&mut self.path[..]) {
                    return self.path.last().copied();
                } else if let Some(src) = self.embark.next() {
                    self.path[0] = src;
                    if self.frames.is_empty() {
                        return Some(src);
                    } else {
                        // Start over with the next note this navigation embarked from.
                        self.frames[0].set_src(src);
                    }
                } else {
                    // We're done!
                    return None;
                }
            }
        }
    }

    /// Derefence an [IntoIter] to get the slice of [Note] for each step in the path to the last
    /// [Note] returned from [IntoIter::next].
    impl<G: IntoAdjacentNotes> std::borrow::Borrow<[Note]> for IntoIter<G> {
        fn borrow(&self) -> &[Note] {
            self.path.as_slice()
        }
    }

    /// A trait to be implemented by all Note Map graphs that support queries.
    ///
    /// All types that implement [IntoAdjacentNotes] for `&Self` automatically implement [Graph]
    /// for `Self`.
    pub trait IntoAdjacentNotes: Copy {
        type AdjacentNotes: IntoIterator<Item = Note>;

        fn into_adjacent_notes(
            self,
            src: Note,
            axis: Axis,
            direction: Direction,
        ) -> Self::AdjacentNotes;
    }

    /// An ergonomic trait that is automatically implmented for all compatible types.
    ///
    /// TODO: Remove the explicit sealing of this trait if it is already implicitly sealed by the
    /// broad `impl for T` below.
    pub trait Graph: graph_private::Sealed {
        /// Returns the notes matching the given query.
        fn navigate<Q: Into<Query>>(&self, query: Q) -> Navigate<&Self>
        where
            for<'a> &'a Self: IntoAdjacentNotes,
        {
            let query: Query = query.into();
            let anchored: AnchoredPath = query.anchored_path.into();
            Navigate::new(self, anchored.anchor, anchored.path)
        }

        /// Creates a new graph that, when queried, will return notes from `self` followed by
        /// notes from `other`.
        fn chain<'a, G: Graph>(&'a self, other: &'a G) -> Chain<&'a Self, &'a G>
        where
            &'a Self: IntoAdjacentNotes,
            &'a G: IntoAdjacentNotes,
        {
            Chain::new(self, other)
        }
    }

    /// Automatically implement [Graph] for all compatible types.
    impl<T> Graph for T
    where
        T: graph_private::Sealed,
        for<'a> &'a T: super::IntoAdjacentNotes,
    {
    }

    mod graph_private {
        pub trait Sealed {}
        /// Automatically implement [Graph] for all compatible types.
        impl<T> Sealed for T where for<'a> &'a T: super::IntoAdjacentNotes {}
    }

    /* TODO: Remove this if it really isn't needed. To find out, attempt to implement iteration
     * through query results in a way that visits all notes along each step of the path.
    pub struct Iter<'a> {
        boxed: Box<dyn Iterator<Item = Note> + 'a>,
    }
    impl<'a> Iter<'a> {
        pub fn new<T: Iterator<Item = Note> + 'a>(iter: T) -> Self {
            Self {
                boxed: Box::new(iter),
            }
        }
    }
    impl<'a> Iterator for Iter<'a> {
        type Item = Note;
        fn next(&mut self) -> Option<Self::Item> {
            self.boxed.next()
            //self.boxed.as_mut().next()
        }
    }
    */

    /// An empty [Graph].
    ///
    /// [Empty] is a minimal implementation of the [IntoAdjacentNotes] trait for use wherever a
    /// const empty graph would be helpful.
    pub struct Empty {}
    impl Empty {
        pub const fn new() -> Self {
            Self {}
        }
        const DEFAULT: Empty = Empty::new();
    }

    impl Default for Empty {
        fn default() -> Self {
            Self::new()
        }
    }

    impl<'a> Default for &'a Empty {
        fn default() -> Self {
            &Empty::DEFAULT
        }
    }

    impl<'a> IntoAdjacentNotes for &'a Empty {
        type AdjacentNotes = iter::Empty<Note>;
        fn into_adjacent_notes(self, _: Note, _: Axis, _: Direction) -> Self::AdjacentNotes {
            Default::default()
        }
    }

    /// Combines two graphs into one in which adjacent notes from the first graph a followed by
    /// adjacent notes from the second graph.
    pub struct Chain<A: IntoAdjacentNotes, B: IntoAdjacentNotes> {
        a: A,
        b: B,
    }

    impl<A: IntoAdjacentNotes, B: IntoAdjacentNotes> Chain<A, B> {
        fn new(a: A, b: B) -> Self {
            Self { a, b }
        }
    }

    impl<'a, A: IntoAdjacentNotes, B: IntoAdjacentNotes> IntoAdjacentNotes for &'a Chain<A, B> {
        type AdjacentNotes = std::iter::Chain<
            <<A as IntoAdjacentNotes>::AdjacentNotes as IntoIterator>::IntoIter,
            <<B as IntoAdjacentNotes>::AdjacentNotes as IntoIterator>::IntoIter,
        >;
        fn into_adjacent_notes(
            self,
            src: Note,
            axis: Axis,
            direction: Direction,
        ) -> Self::AdjacentNotes {
            self.a
                .into_adjacent_notes(src, axis, direction)
                .into_iter()
                .chain(self.b.into_adjacent_notes(src, axis, direction))
        }
    }

    /// Always implements any note adjacency rules that can be implemented once for all possible
    /// note maps.
    #[derive(Copy, Clone, Debug, Default, PartialEq, Eq, Hash, PartialOrd, Ord)]
    struct Always {}

    impl<'a> IntoAdjacentNotes for &'a Always {
        type AdjacentNotes = Option<Note>;

        fn into_adjacent_notes(self, note: Note, axis: Axis, _: Direction) -> Self::AdjacentNotes {
            if axis == Axis::Loopback {
                Some(note)
            } else {
                None
            }
        }
    }

    /// Provides all the built-in supertypes, subtypes, and instances.
    #[derive(Copy, Clone, Debug, Default, PartialEq, Eq, Hash, PartialOrd, Ord)]
    struct BuiltinTypes {}
    impl BuiltinTypes {}
    impl<'a> IntoAdjacentNotes for &'a BuiltinTypes {
        type AdjacentNotes = std::vec::IntoIter<Note>;
        fn into_adjacent_notes(
            self,
            note: Note,
            axis: Axis,
            direction: Direction,
        ) -> Self::AdjacentNotes {
            match (axis, direction) {
                (Axis::Traverse(Note::SUBTYPE, Note::SUPERTYPE), direction) => {
                    self.into_adjacent_notes(note, Axis::Supertypes, direction)
                }
                (Axis::Traverse(Note::SUPERTYPE, Note::SUBTYPE), direction) => {
                    self.into_adjacent_notes(note, Axis::Supertypes, -direction)
                }
                (Axis::Traverse(Note::INSTANCE, Note::TYPE), direction) => {
                    self.into_adjacent_notes(note, Axis::Types, direction)
                }
                (Axis::Traverse(Note::TYPE, Note::INSTANCE), direction) => {
                    self.into_adjacent_notes(note, Axis::Types, -direction)
                }
                _ => match (axis, direction) {
                    // Builtin supertypes and subtypes:
                    (Axis::Supertypes, Direction::Forward) => match note {
                        Note::ASSOCIATION => vec![Note::SUBJECT],
                        Note::CONTENT => vec![Note::SUBJECT],
                        Note::DATA_TYPE => vec![Note::SUBJECT],
                        Note::SUBJECT => vec![Note::SUBJECT],
                        Note::TOPIC => vec![Note::SUBJECT],
                        Note::NAME => vec![Note::CONTENT, Note::SUBJECT],
                        Note::OCCURRENCE => vec![Note::CONTENT, Note::SUBJECT],
                        _ => vec![],
                    },
                    (Axis::Supertypes, Direction::Reverse) => match note {
                        Note::CONTENT => vec![Note::NAME, Note::OCCURRENCE],
                        Note::SUBJECT => vec![
                            Note::ASSOCIATION,
                            Note::CONTENT,
                            Note::DATA_TYPE,
                            Note::NAME,
                            Note::OCCURRENCE,
                            Note::SUBJECT,
                            Note::TOPIC,
                        ],
                        _ => vec![],
                    },

                    // Builtin types and their instances:
                    (Axis::Types, Direction::Forward) => match note {
                        Note::DATA_TYPE_NOTE => Some(Note::DATA_TYPE),
                        Note::DATA_TYPE_UTF8 => Some(Note::DATA_TYPE),
                        Note::INSTANCE => Some(Note::ROLE_TYPE),
                        Note::SUBTYPE => Some(Note::ROLE_TYPE),
                        Note::SUPERTYPE => Some(Note::ROLE_TYPE),
                        Note::TYPE => Some(Note::ROLE_TYPE),
                        _ => None,
                    }
                    .into_iter()
                    .chain([Note::SUBJECT])
                    .collect(),
                    (Axis::Types, Direction::Reverse) => match note {
                        Note::SUBJECT => vec![
                            Note::ASSOCIATION,
                            Note::CONTENT,
                            Note::DATA_TYPE,
                            Note::DATA_TYPE_NOTE,
                            Note::DATA_TYPE_UTF8,
                            Note::NAME,
                            Note::OCCURRENCE,
                            Note::SUBJECT,
                            Note::TOPIC,
                        ],
                        Note::ROLE_TYPE => {
                            vec![Note::INSTANCE, Note::SUBTYPE, Note::SUPERTYPE, Note::TYPE]
                        }
                        Note::DATA_TYPE => vec![Note::DATA_TYPE_UTF8],
                        _ => vec![],
                    },
                    _ => vec![],
                }
                .into_iter(),
            }
        }
    }
}

mod mutate {
    use super::*;

    pub trait GraphMut {
        fn push_adjacent_notes<T: IntoIterator<Item = Note>, U: IntoIterator<Item = Note>>(
            &mut self,
            srcs: T,
            step: Step,
            dsts: U,
        );

        fn new_with_builtins() -> Self
        where
            Self: Default,
        {
            let mut graph = Self::default();
            // Every note that is a NAME or OCCURRENCE is also a CONTENT:
            graph.push_adjacent_notes(
                vec![Note::NAME, Note::OCCURRENCE],
                Axis::Supertypes.forward(),
                vec![Note::CONTENT],
            );
            graph.push_adjacent_notes(
                vec![Note::CONTENT, Note::ASSOCIATION, Note::TOPIC],
                Axis::Supertypes.forward(),
                vec![Note::TOPIC],
            );
            // All the built-in notes are instances of the TOPIC type:
            graph.push_adjacent_notes(
                vec![
                    Note::ASSOCIATION,
                    Note::CONTENT,
                    Note::DATA_TYPE,
                    Note::DATA_TYPE_NOTE,
                    Note::DATA_TYPE_UTF8,
                    Note::NAME,
                    Note::OCCURRENCE,
                    Note::TOPIC,
                ],
                Axis::Types.forward(),
                vec![Note::TOPIC],
            );
            // Each concrete data type is an instance of the DATA_TYPE note:
            graph.push_adjacent_notes(
                vec![Note::DATA_TYPE_UTF8, Note::DATA_TYPE_NOTE],
                Axis::Types.forward(),
                vec![Note::DATA_TYPE],
            );
            graph
        }
    }

    pub trait Vertex {
        fn note(&self) -> Note;
        fn text(&self) -> String;
        //fn contents(&self) where Self: Sized->Vector<Self>;
        //fn roles(&self) -> Vector<(Note, Note)>;
    }
}

pub use mutate::*;
pub use navigation::*;

mod memory {
    use super::*;
    use petgraph_types::*;
    use std::iter;

    /// Use some aliases to refer to petgraph types so that it's a little easier to swap out the
    /// petgraph implementation being used here.
    mod petgraph_types {
        use petgraph::graphmap::DiGraphMap as DiGraph;
        pub use petgraph::visit::IntoNeighborsDirected;
        pub type NoteGraph = DiGraph<super::Note, ()>;
    }

    /// Implements IntoAdjacentNotes
    pub struct MemoryGraph {
        types: NoteGraph,
        supertypes: NoteGraph,
        associations: NoteGraph,
        roles: NoteGraph,
    }

    impl MemoryGraph {
        pub fn new() -> Self {
            Self {
                types: NoteGraph::new(),
                supertypes: NoteGraph::new(),
                associations: NoteGraph::new(),
                roles: NoteGraph::new(),
            }
        }

        pub fn extend<I: IntoIterator<Item = Triple>>(&mut self, triples: I) {
            for triple in triples {
                match triple.axis() {
                    Axis::Loopback => {}
                    Axis::Types => self.types.extend_one((triple.src(), triple.dst())),
                    Axis::Supertypes => self.supertypes.extend_one((triple.src(), triple.dst())),
                    Axis::Associations(Note::TOPIC) => {
                        self.associations.extend_one((triple.src(), triple.dst()))
                    }
                    Axis::Roles => self.roles.extend_one((triple.src(), triple.dst())),
                    //Axis::Traverse(Note::TOPIC,Note::TOPIC)=>
                    _ => todo!(""),
                }
            }
        }

        pub fn extend_axis<T: IntoIterator<Item = (Note, Note)>>(&mut self, axis: Axis, edges: T) {
            match axis {
                Axis::Types => self.types.extend(edges),
                Axis::Supertypes => self.supertypes.extend(edges),
                Axis::Associations(Note::TOPIC) => self.associations.extend(edges),
                Axis::Roles => self.roles.extend(edges),
                _ => todo!(""),
            }
        }

        pub fn extend_step<T: IntoIterator<Item = Note>, U: IntoIterator<Item = Note>>(
            &mut self,
            srcs: T,
            step: Step,
            dsts: U,
        ) {
            let dsts: Vec<Note> = dsts.into_iter().collect();
            match step.direction() {
                Direction::Forward => self.extend_axis(
                    step.axis(),
                    srcs.into_iter()
                        .flat_map(|src| iter::zip(iter::repeat(src), dsts.iter().copied())),
                ),
                Direction::Reverse => self.extend_axis(
                    step.axis(),
                    srcs.into_iter()
                        .flat_map(|src| iter::zip(dsts.iter().copied(), iter::repeat(src))),
                ),
            }
        }
    }

    /// This trait implementation causes [MemoryGraph] to automatically implement the [Graph]
    /// trait, providing a fluent interface for navigation.
    impl<'a> IntoAdjacentNotes for &'a MemoryGraph {
        type AdjacentNotes = <&'a NoteGraph as IntoNeighborsDirected>::NeighborsDirected;

        fn into_adjacent_notes(
            self,
            src: Note,
            axis: Axis,
            direction: Direction,
        ) -> Self::AdjacentNotes {
            use petgraph::Direction::{Incoming, Outgoing};
            use Direction::{Forward, Reverse};
            match axis {
                Axis::Types => &self.types,
                Axis::Supertypes => &self.supertypes,
                Axis::Associations(Note::TOPIC) => &self.associations,
                Axis::Roles => &self.roles,
                _ => todo!(""),
            }
            .neighbors_directed(
                src.to_owned(),
                match direction {
                    Forward => Outgoing,
                    Reverse => Incoming,
                },
            )
        }
    }

    impl GraphMut for MemoryGraph {
        fn push_adjacent_notes<T: IntoIterator<Item = Note>, U: IntoIterator<Item = Note>>(
            &mut self,
            srcs: T,
            step: Step,
            dsts: U,
        ) {
            MemoryGraph::extend_step(self, srcs, step, dsts);
        }
    }

    impl Default for MemoryGraph {
        fn default() -> Self {
            MemoryGraph::new()
        }
    }

    #[cfg(test)]
    mod test_memory_graph {
        use super::*;

        #[test]
        fn builtin_types() {
            let graph = MemoryGraph::new_with_builtins();
            assert_eq!(
                graph
                    .navigate(Note::NAME.supertypes())
                    .into_iter()
                    .collect::<Vec<Note>>(),
                [Note::CONTENT]
            );
            assert_eq!(
                graph
                    .navigate(Note::CONTENT.subtypes())
                    .into_iter()
                    .collect::<Vec<Note>>(),
                [Note::NAME, Note::OCCURRENCE]
            );
        }

        #[test]
        fn types() {
            let mut graph = MemoryGraph::new_with_builtins();
            let some_topic = Note::random();
            assert_eq!(graph.navigate(some_topic.types()).into_iter().next(), None);
            graph.extend_step(vec![some_topic], Axis::Types.forward(), vec![Note::TOPIC]);
            assert_eq!(
                graph
                    .navigate(some_topic.types())
                    .into_iter()
                    .collect::<Vec<Note>>(),
                [Note::TOPIC]
            );
        }

        #[test]
        fn recursive_terminating_better() {
            let mut graph = MemoryGraph::new();
            let (a, b, c, d) = (
                Note::random(),
                Note::random(),
                Note::random(),
                Note::random(),
            );
            // Insert a cycle of supertype relationships: a -> b -> c -> d -> b.
            graph.push_adjacent_notes(Some(a), Axis::Supertypes.forward(), Some(b));
            graph.push_adjacent_notes(Some(b), Axis::Supertypes.forward(), Some(c));
            graph.push_adjacent_notes(Some(c), Axis::Supertypes.forward(), Some(d));
            graph.push_adjacent_notes(Some(d), Axis::Supertypes.forward(), Some(b));
            // Search for all supertypes of 'a' without getting stuck in an infinite loop:
            let found = graph
                .navigate(a.supertypes_transitive())
                .into_iter()
                .collect::<Vec<Note>>();
            assert_eq!(found, [b, c, d]); // ...almost? or better?
        }

        #[test]
        fn transitive_query_through_chained_graphs() {
            let mut graph0 = MemoryGraph::new();
            let mut graph1 = MemoryGraph::new();
            let (a, b, c, d) = (
                Note::random(),
                Note::random(),
                Note::random(),
                Note::random(),
            );
            graph0.push_adjacent_notes(Some(a), Axis::Supertypes.forward(), Some(b));
            graph1.push_adjacent_notes(Some(b), Axis::Supertypes.forward(), Some(c));
            graph0.push_adjacent_notes(Some(c), Axis::Supertypes.forward(), Some(d));
            graph1.push_adjacent_notes(Some(d), Axis::Supertypes.forward(), Some(b));
            assert_eq!(
                graph0
                    .chain(&graph1)
                    .navigate(a.supertypes_transitive())
                    .into_iter()
                    .collect::<Vec<Note>>(),
                [b, c, d]
            );
        }

        #[test]
        fn select_whole_paths() {
            let mut graph0 = MemoryGraph::new();
            let mut graph1 = MemoryGraph::new();
            let (a, b, c, d) = (
                Note::random(),
                Note::random(),
                Note::random(),
                Note::random(),
            );
            graph0.push_adjacent_notes(Some(a), Axis::Supertypes.forward(), Some(b));
            graph1.push_adjacent_notes(Some(b), Axis::Supertypes.forward(), Some(c));
            graph0.push_adjacent_notes(Some(c), Axis::Supertypes.forward(), Some(d));
            graph1.push_adjacent_notes(Some(d), Axis::Supertypes.forward(), Some(b));
            let graph = graph0.chain(&graph1);
            let mut iter = graph.navigate(a.supertypes().supertypes()).into_iter();
            use std::borrow::Borrow;
            assert_eq!(iter.next(), Some(c));
            assert_eq!(
                Borrow::<[Note]>::borrow(&iter)
                    .into_iter()
                    .copied()
                    .collect::<Vec<Note>>(),
                [a, b, c]
            );
        }

        #[test]
        fn predicate() {
            /*
            let mut graph = MemoryGraph::new_with_builtins();
            let a_new_hope = Note::random();
            let episode = Note::random();
            let only_episodes: Predicate = PredicateBuilder::new().types().contains(episode);
            assert_eq!(
                graph
                    .navigate(a_new_hope)
                    .into_iter()
                    .collect::<Vec<Note>>(),
                [a_new_hope]
            );
            assert_eq!(
                only_episodes
                    .filter(&graph, graph.navigate(a_new_hope))
                    .collect::<Vec<Note>>(),
                []
            );
            assert_eq!(
                graph
                    .navigate(
                        a_new_hope
                            .loopback()
                            .filter(|x| x.types().contains(episode))
                    )
                    .into_iter()
                    .collect::<Vec<Note>>(),
                []
            );
            graph.extend_step([a_new_hope], Axis::Types.forward(), [episode]);
            assert_eq!(
                only_episodes
                    .filter(&graph, graph.navigate(a_new_hope))
                    .collect::<Vec<Note>>(),
                [a_new_hope]
            );
            assert_eq!(
                graph
                    .navigate(
                        a_new_hope
                            .loopback()
                            .filter(|x| x.types().contains(episode))
                    )
                    .into_iter()
                    .collect::<Vec<Note>>(),
                [a_new_hope]
            );
            */
        }
    }
}
