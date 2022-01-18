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

use super::AtomicNoteMap;
use super::Field;
use super::Lint;
use super::Note;
use super::NoteMap;
use super::NotesOp;
use super::Op;
use super::OpTarget;
use super::Properties;
use super::PropertiesMut;
use super::PropertiesSnapshot;
use super::StrOp;
use super::UserError;
use super::Value;
use automerge as am;
use automerge_persistent as am_persistent;
use automerge_persistent::PersistentBackend;
use automerge_persistent_sled::SledPersister;
use automerge_protocol as amp;
use core::result;
use std::borrow::Borrow;
use std::borrow::Cow;
use std::collections::HashMap;
use std::collections::VecDeque;
use std::convert::TryFrom;
use std::io;
use std::ops::Deref;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::Mutex;
use unicode_segmentation::UnicodeSegmentation;

/// The automerge document key whose value in the root node is a map or table containing all of the
/// notes in the note map.
const ALL_NOTES: &str = "t";

/// The automerge document key whose value in a note is the text of that note's value.
const VALUE_TEXT: &str = "vt";

/// The automerge document key whose value in a note is the datatype of that note's value.
const VALUE_DATATYPE: &str = "vdt";

/// The automerge document key whose value in a note is the list of the types of that note.
const ISA: &str = "isa";

/// The automerge document key whose value in a note is the list of occurrences of that note.
const OCCURRENCES: &str = "o";

/// Wraps a note identifier for convenient automerge-specific operations.
#[derive(Clone)]
struct IdPath(am::Path);

impl<T> From<T> for IdPath
where
    T: Borrow<Note>,
{
    /// Constructs an IdPath that can locate the note corresponding to id in any automerge document
    /// that represents a note map.
    fn from(id: T) -> IdPath {
        IdPath(am::Path::root().key(ALL_NOTES).key(id.borrow().to_string()))
    }
}

impl IdPath {
    fn path(self) -> am::Path {
        self.0
    }
    fn path_ref(&self) -> &am::Path {
        &self.0
    }
    fn field_value(self, field: Field) -> am::Path {
        match field {
            Field::ValueText => self.value_text_path(),
            Field::ValueDatatype => self.value_datatype_path(),
            Field::IsA => self.isa_path(),
            Field::Occurrences => self.occurrences_path(),
            Field::Note => self.0,
        }
    }
    fn value_text_path(self) -> am::Path {
        self.path().key(VALUE_TEXT)
    }
    fn value_datatype_path(self) -> am::Path {
        self.path().key(VALUE_DATATYPE)
    }
    fn isa_path(self) -> am::Path {
        self.path().key(ISA)
    }
    fn occurrences_path(self) -> am::Path {
        self.path().key(OCCURRENCES)
    }
}

struct AutomergeProperties(PropertiesSnapshot);
impl From<am::Value> for AutomergeProperties {
    fn from(properties: am::Value) -> Self {
        AutomergeProperties(
            Format::default()
                .read_properties(properties)
                .unwrap_or_default(),
        )
    }
}

/// An internal-only struct for operating on the path identified by a ([Note], [Field]) tuple.
#[derive(Debug, Clone, Eq, PartialEq)]
struct FieldPath(am::Path);
impl From<(Note, Field)> for FieldPath {
    fn from((note, field): (Note, Field)) -> Self {
        FieldPath::from((IdPath::from(note), field))
    }
}
impl From<(IdPath, Field)> for FieldPath {
    fn from((idpath, field): (IdPath, Field)) -> Self {
        FieldPath(idpath.field_value(field))
    }
}
impl Deref for FieldPath {
    type Target = am::Path;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<'a> OpTarget<Cow<'a, str>> for FieldPath {
    type Result = result::Result<Vec<am::LocalChange>, UserError>;
    fn apply_ops<I: Iterator<Item = Op<Cow<'a, str>>>>(&self, ops: I) -> Self::Result {
        self.apply_ops(ops.map(|op| {
            op.map(|text| {
                text.graphemes(true)
                    .map(|grapheme| grapheme.into())
                    .collect::<Vec<automerge::Value>>()
            })
        }))
    }
}

impl OpTarget<Vec<Note>> for FieldPath {
    type Result = result::Result<Vec<am::LocalChange>, UserError>;
    fn apply_ops<I: Iterator<Item = Op<Vec<Note>>>>(&self, ops: I) -> Self::Result {
        self.apply_ops(ops.map(|op| {
            op.map(|notes| {
                notes
                    .iter()
                    .map(|note| AutomergeNote(*note).into())
                    .collect::<Vec<automerge::Value>>()
            })
        }))
    }
}

impl OpTarget<Vec<am::Value>> for FieldPath {
    type Result = result::Result<Vec<am::LocalChange>, UserError>;
    fn apply_ops<I: Iterator<Item = Op<Vec<am::Value>>>>(&self, ops: I) -> Self::Result {
        let mut result = Vec::new();
        use am::LocalChange;
        let mut offset: usize = 0;
        for op in ops {
            use Op::*;
            match op {
                Retain(len) => {
                    offset += len;
                }
                Insert(values) => {
                    result.push(LocalChange::insert_many(
                        self.0.clone().index(cast_to_u32(offset)?),
                        values.clone(),
                    ));
                    offset += values.len();
                }
                Delete(len) => {
                    for _ in 0..len {
                        result.push(LocalChange::delete(
                            self.0.clone().index(cast_to_u32(offset)?),
                        ));
                    }
                }
            }
        }
        Ok(result)
    }
}

struct AutomergeNote(Note);

impl Deref for AutomergeNote {
    type Target = Note;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl TryFrom<am::Value> for AutomergeNote {
    type Error = Lint;
    fn try_from(v: am::Value) -> result::Result<Self, Self::Error> {
        match v.primitive() {
            Some(am::Primitive::Str(s)) => Note::try_from(s.as_str()).ok(),
            _ => None,
        }
        .ok_or(Lint::UnrecognizedFormat(Field::Note))
        .map(AutomergeNote)
    }
}

struct Text(String);

impl TryFrom<am::Value> for Text {
    type Error = Lint;
    fn try_from(v: am::Value) -> result::Result<Self, Self::Error> {
        match v {
            am::Value::Text(text) => Ok(Text(text.iter().map(|s| s.as_str()).collect::<String>())),
            _ => Err(Lint::UnrecognizedFormat(Field::ValueText)),
        }
    }
}

#[derive(Default)]
struct NoteList(Vec<Note>, Vec<Lint>);

impl NoteList {
    pub fn try_from(v: am::Value, scope: Field) -> result::Result<Self, Lint> {
        match v {
            am::Value::List(list) => {
                let mut result: NoteList = Default::default();
                list.into_iter()
                    .map(AutomergeNote::try_from)
                    .for_each(|n| match n {
                        Ok(n) => result.0.push(n.0),
                        Err(e) => result.1.push(e),
                    });
                Ok(result)
            }
            _ => Err(Lint::UnrecognizedFormat(scope)),
        }
    }
}

/// Responsible for translating between automerge document formats and in-memory representations of
/// note maps.
#[derive(Default)]
struct Format {}

impl Format {
    /// Constructs a note Value from an am::Value.
    fn read_value_text(&self, v: am::Value) -> result::Result<String, Lint> {
        Text::try_from(v).map(|t| t.0)
    }

    /// Constructs a notemaps_core::Note from an am::Value.
    fn read_id(&self, v: am::Value) -> result::Result<Note, Lint> {
        AutomergeNote::try_from(v).map(|note| note.0)
    }

    /// Constructs a Properties from an am::ValueRef.
    fn read_properties(&self, v: am::Value) -> result::Result<PropertiesSnapshot, Lint> {
        let mut result = PropertiesSnapshot::default();
        if let am::Value::Map(m) = v {
            if let Some(text) = m.get(VALUE_TEXT) {
                match self.read_value_text(text.to_owned()) {
                    Ok(text) => {
                        result
                            .update_value_text(&[Op::Insert(text.as_str().into())])
                            .map_err(|_| Lint::UnrecognizedFormat(Field::ValueText))?;
                    }
                    Err(_lint) => {
                        //result.lints.push(lint);
                    }
                }
            }
            if let Some(datatype) = m.get(VALUE_DATATYPE) {
                match self.read_id(datatype.to_owned()) {
                    Ok(datatype) => {
                        result
                            .update_value_datatype(datatype)
                            .map_err(|_| Lint::UnrecognizedFormat(Field::ValueDatatype))?;
                    }
                    Err(_lint) => {
                        //result.lints.push(lint);
                    }
                }
            }
            if let Some(isa) = m.get(ISA) {
                match NoteList::try_from(isa.to_owned(), Field::IsA) {
                    Ok(isa) => {
                        result
                            .update_isa(&[Op::Insert(isa.0)])
                            .map_err(|_| Lint::UnrecognizedFormat(Field::IsA))?;
                        //result.lints.extend(isa.1);
                    }
                    Err(_lint) => {
                        //result.lints.push(lint);
                    }
                }
            }
            if let Some(occurrences) = m.get(OCCURRENCES) {
                match NoteList::try_from(occurrences.to_owned(), Field::Occurrences) {
                    Ok(occurrences) => {
                        result
                            .update_occurrences(&[Op::Insert(occurrences.0)])
                            .map_err(|_| Lint::UnrecognizedFormat(Field::Occurrences))?;
                        //result.lints.extend(occurrences.1);
                    }
                    Err(_lint) => {
                        //result.lints.push(e);
                    }
                }
            }
        }
        Ok(result)
    }
}

pub enum Location {
    Memory,
    SledName(String),
    SledPath(Box<std::path::Path>),
    //SnapshotName(String),
    //SnapshotPath(Box<std::path::Path>),
}

use std::sync::mpsc;

enum Command {
    Change(amp::Change),
}

#[derive(Clone, Debug, Default)]
pub struct Config {
    actor_id: Option<Vec<u8>>,
}

pub struct Automerge {
    frontend: am::Frontend,
    commands: mpsc::Sender<Command>,
    patches: mpsc::Receiver<amp::Patch>,
    broken: bool,
    _worker: std::thread::JoinHandle<()>,
}

impl Automerge {
    pub fn new_with_backend<P, B>(
        _config: Config,
        backend: Arc<Mutex<am_persistent::PersistentBackend<P, B>>>,
    ) -> Self
    where
        P: am_persistent::Persister + std::marker::Send + 'static,
        B: am_persistent::Backend + std::marker::Send + 'static,
    {
        let (commands, command_receiver) = mpsc::channel::<Command>();
        let (patch_sender, patches) = mpsc::channel::<amp::Patch>();
        Self {
            frontend: if let Some(actor_id) = _config.actor_id {
                am::Frontend::new_with_actor_id(actor_id.as_slice())
            } else {
                am::Frontend::new()
            },
            commands,
            patches,
            broken: false,
            _worker: std::thread::spawn(move || {
                for command in command_receiver {
                    use am_persistent::Error::*;
                    if let Err(err) = match command {
                        Command::Change(change) => backend
                            .lock()
                            .unwrap()
                            .apply_local_change(change)
                            .map_err(|err| match err {
                                BackendError(err) => {
                                    DurabilityError::AutomergeBackend(Box::new(err))
                                }
                                AutomergeError(err) => DurabilityError::from(err),
                                PersisterError(err) => DurabilityError::Persister(Box::new(err)),
                            })
                            .and_then(|patch| {
                                patch_sender.send(patch).map_err(DurabilityError::from)
                            }),
                    } {
                        log::debug!("terminating backend: {}", err);
                        break;
                    }
                }
            }),
        }
    }

    pub fn change<F, O>(&mut self, message: Option<String>, change_closure: F) -> Result<O>
    where
        F: FnOnce(&mut dyn am::MutableDocument) -> Result<O>,
    {
        self.result()?;
        let (o, change) = self.frontend.change(message, change_closure)?;
        if let Some(change) = change {
            if let Err(err) = self
                .commands
                .send(Command::Change(change))
                .map_err(DurabilityError::from)
            {
                self.broken = true;
                return Err(err);
            }
        }
        Ok(o)
    }

    pub fn pull(&mut self) -> result::Result<(), DurabilityError> {
        self.result()?;
        for patch in self.patches.try_iter() {
            self.frontend.apply_patch(patch)?;
        }
        Ok(())
    }

    fn result(&self) -> result::Result<(), DurabilityError> {
        if self.broken {
            Err(DurabilityError::EngineUnusable)
        } else {
            Ok(())
        }
    }
}

#[cfg(test)]
mod test_frontend {
    use super::*;

    #[test]
    fn new_frontend() {
        let persister = am_persistent::MemoryPersister::default();
        let backend: PersistentBackend<am_persistent::MemoryPersister, am::Backend> =
            PersistentBackend::load(persister).expect("load persister");
        let mut frontend =
            Automerge::new_with_backend(Config::default(), Arc::new(Mutex::new(backend)));
        frontend
            .change(Some("test".to_string()), |doc| {
                Ok(doc
                    .add_change(am::LocalChange::set(am::Path::root().key("key"), 1))
                    .map_err(UserError::from))
            })
            .expect("durability")
            .expect("user");
    }

    #[test]
    fn something_something() {
        let persister = am_persistent::MemoryPersister::default();
        let backend: PersistentBackend<am_persistent::MemoryPersister, am::Backend> =
            PersistentBackend::load(persister).expect("load persister");
        let mut frontend =
            Automerge::new_with_backend(Config::default(), Arc::new(Mutex::new(backend)));
        frontend
            .change(Some("test".to_string()), |doc| {
                Ok(doc
                    .add_change(am::LocalChange::set(am::Path::root().key("key"), 1))
                    .map_err(UserError::from))
            })
            .expect("durability")
            .expect("user");
    }
}

/// Merges edits into a note map by using a single Automerge document to represent the entire note
/// map.
#[derive(Clone)]
pub struct AutomergeNoteMap {
    frontend: Arc<Mutex<am::Frontend>>,
    backend: Arc<Mutex<PersistentBackend<SledPersister, am::Backend>>>,
    from_frontend: VecDeque<amp::Change>,
}

impl AutomergeNoteMap {
    fn apply_to_backend(
        &mut self,
        change: amp::Change,
    ) -> result::Result<amp::Patch, DurabilityError> {
        match self.backend.lock().unwrap().apply_local_change(change) {
            Ok(patch) => Ok(patch),
            Err(am_persistent::Error::BackendError(err)) => Err(err.into()),
            Err(am_persistent::Error::AutomergeError(err)) => Err(err.into()),
            Err(am_persistent::Error::PersisterError(err)) => {
                Err(DurabilityError::Persister(err.into()))
            }
        }
    }
}

impl Drop for AutomergeNoteMap {
    fn drop(&mut self) {
        self.sync().unwrap().unwrap();
        self.backend.lock().unwrap().flush().unwrap();
    }
}

use thiserror::Error;

/// Represents data loss, data corruption, or other IO error.
///
/// Applications SHOULD consider the associated note map unsafe for further queries or mutations,
/// MAY attempt to rescue the note map (e.g. by flushing it to an alternative or temporary backup
/// location and/or reloading it from disk), and MAY die with a fatal error.
#[derive(Error, Debug)]
pub enum DurabilityError {
    // TODO: conflate IO into something more specific below:
    #[error("general I/O failre: {0}")]
    IO(#[from] io::Error),
    #[error("automerge sled storage failre: {0}")]
    Sled(#[from] sled::Error),
    #[error("automerge backend storage failure: {0}")]
    SledPersister(#[from] automerge_persistent_sled::SledPersisterError),
    #[error("automerge backend storage failure: {0}")]
    Persister(Box<dyn std::error::Error>),
    #[error("automerge frontend failure: {0}")]
    AutomergeFrontend(#[from] am::FrontendError),
    #[error("automerge backend failure (custom): {0}")]
    AutomergeBackend(Box<dyn std::error::Error>),
    #[error("automerge failure: {0}")]
    Automerge(#[from] am::AutomergeError),
    #[error("automerge backend failure (TODO): {0}")]
    AutomergeTODO(#[from] am::BackendError),
    #[error("automerge document has become inconsistent with the backend")]
    EngineUnusable,
    #[error("automerge document has become inconsistent with the backend: {0}")]
    InvalidPatch(#[from] am::InvalidPatch),
}

impl<T> From<std::sync::mpsc::SendError<T>> for DurabilityError {
    fn from(_: std::sync::mpsc::SendError<T>) -> Self {
        Self::EngineUnusable
    }
}

impl From<std::sync::mpsc::RecvError> for DurabilityError {
    fn from(_: std::sync::mpsc::RecvError) -> Self {
        Self::EngineUnusable
    }
}

impl From<am_persistent::Error<automerge_persistent_sled::SledPersisterError, am::BackendError>>
    for DurabilityError
{
    fn from(
        err: am_persistent::Error<automerge_persistent_sled::SledPersisterError, am::BackendError>,
    ) -> Self {
        Self::Persister(err.into())
    }
}

pub type Result<T> = result::Result<result::Result<T, UserError>, DurabilityError>;

fn default_directory() -> PathBuf {
    directories::ProjectDirs::from("com.github", "Google", "Note Maps")
        .map(|dirs| dirs.data_local_dir().to_path_buf())
        .unwrap_or_else(|| std::env::current_dir().unwrap())
}

impl AutomergeNoteMap {
    pub fn open(location: Location) -> Result<Self> {
        let db = match location {
            Location::Memory => sled::Config::default().temporary(true),
            Location::SledName(name) => {
                let mut path = default_directory();
                path.push("automerge-sled");
                path.push(name);
                sled::Config::default().path(path.into_boxed_path())
            }
            Location::SledPath(path) => sled::Config::default().path(path),
        }
        .open()?;
        let persister = SledPersister::new(
            db.open_tree("changes")?,
            db.open_tree("document")?,
            db.open_tree("sync_states")?,
            /*prefix=*/ "".to_owned(),
        )?;
        let self_ = Self {
            frontend: Default::default(),
            backend: Arc::new(Mutex::new(
                PersistentBackend::load(persister).expect("error handling..."),
            )),
            from_frontend: Default::default(),
        };
        {
            if let Err(err) = self_
                .frontend
                .lock()
                .unwrap()
                .apply_patch(self_.backend.lock().unwrap().get_patch()?)
            {
                return Ok(Err(err.into()));
            }
        }
        Ok(Ok(self_))
    }

    /// Flush pending changes to the backend and apply any resulting patches to the frontend.
    pub fn sync(&mut self) -> Result<()> {
        while let Some(change) = self.from_frontend.pop_front() {
            let patch = self.apply_to_backend(change)?;
            if let Err(err) = self.frontend.lock().unwrap().apply_patch(patch) {
                return Ok(Err(err.into()));
            };
        }
        Ok(Ok(()))
    }
}

impl Default for AutomergeNoteMap {
    fn default() -> Self {
        Self::open(Location::Memory)
            .expect("memory should be coherent")
            .expect("should not be a user error")
    }
}

use super::Component;

impl NoteMap for AutomergeNoteMap {
    type Properties = PropertiesSnapshot;

    /// Reads the identified note from the current state of the backing automerge document.
    ///
    /// This implementation is able to read the entire note immediately.  All notes exist
    /// implicitly, and the backing automerge document is entirely in memory: the only way this can
    /// fail is with a lint error, and lint errors are included within the returned value for
    /// partial reads.
    fn get(&self, index: &Note) -> Self::Properties {
        use am::value_ref::ValueRef;
        if let Some(ValueRef::Map(all_notes)) =
            self.frontend.lock().unwrap().value_ref().get(ALL_NOTES)
        {
            if let Some(note) = all_notes.get(index.to_string().as_str()) {
                return Format::default()
                    .read_properties(note.value())
                    .unwrap_or_default();
            }
        }
        PropertiesSnapshot::default()
    }

    fn gett<T: Component>(&self, note: &Note) -> T {
        let path = IdPath::from(note);
        use super::AnyComponent;
        use super::*;
        match AnyComponent::from(T::default()) {
            AnyComponent::ValueText(_) => AnyComponent::ValueText(
                self.frontend
                    .lock()
                    .unwrap()
                    .get_value(&path.value_text_path())
                    .and_then(|v| Format::default().read_value_text(v).ok())
                    .map(|s| s.into())
                    .unwrap_or_default(),
            ),
            AnyComponent::ValueDatatype(_) => AnyComponent::ValueDatatype(
                self.frontend
                    .lock()
                    .unwrap()
                    .get_value(&path.value_datatype_path())
                    .and_then(|v| Format::default().read_id(v).ok())
                    .map(|n| n.into())
                    .unwrap_or_default(),
            ),
            AnyComponent::IsA(_) => AnyComponent::IsA(
                self.frontend
                    .lock()
                    .unwrap()
                    .get_value(&path.isa_path())
                    .and_then(|v| NoteList::try_from(v, Field::IsA).ok())
                    .unwrap_or_default()
                    .0
                    .into(),
            ),
            AnyComponent::Occurrences(_) => AnyComponent::Occurrences(
                self.frontend
                    .lock()
                    .unwrap()
                    .get_value(&path.occurrences_path())
                    .and_then(|v| NoteList::try_from(v, Field::Occurrences).ok())
                    .unwrap_or_default()
                    .0
                    .into(),
            ),
        }
        .into()
    }
}

impl AtomicNoteMap for AutomergeNoteMap {
    type PropertiesMut<'a> = MutableAutomergeNote<'a>;
    type NoteMapMut<'a> = MutableAutomergeNoteMap<'a>;
    fn merge_local<F, O>(&mut self, msg: &'static str, edit: F) -> result::Result<O, UserError>
    where
        F: for<'a> FnOnce(Self::NoteMapMut<'a>) -> result::Result<O, UserError>,
    {
        let (output, change) = self
            .frontend /*.lock().map_err(UserError::from)?*/
            .lock()
            .unwrap()
            .change(Some(msg.to_string()), |doc| {
                edit(MutableAutomergeNoteMap::new(doc)?)
            })?;
        if let Some(change) = change {
            self.from_frontend.push_back(change);
        }
        Ok(output)
    }
}

/// A NoteMap backed by an am::MutableDocument.
#[derive(Clone)]
pub struct MutableAutomergeNoteMap<'a> {
    document: Arc<Mutex<&'a mut dyn am::MutableDocument>>,
}

impl<'a> MutableAutomergeNoteMap<'a> {
    /// Construct a new AutoMergeEditor that will use the given am::MutableDocument as the
    /// note map to be mutated.
    pub fn new(
        doc: &mut dyn am::MutableDocument,
    ) -> result::Result<MutableAutomergeNoteMap, UserError> {
        use am::{LocalChange, Value::Map};
        let notes_root = am::Path::root().key(ALL_NOTES);
        match doc.value_at_path(&notes_root) {
            None => {
                doc.add_change(LocalChange::set(notes_root.clone(), Map(HashMap::new())))
                    .map_err(invalid_change_request)?;
            }
            Some(notes) => match notes {
                Map(_) => {}
                _ => {
                    return Err(UserError::InvalidDocument(
                        "has top-level notes key but it is not a map".into(),
                    ));
                }
            },
        }
        Ok(MutableAutomergeNoteMap {
            document: Arc::new(Mutex::new(doc)),
        })
    }

    fn value_at_path(&self, path: &am::Path) -> Option<am::Value> {
        match self.document.as_ref().lock() {
            Ok(document) => document.value_at_path(path),
            Err(_) => None,
        }
    }

    fn add_change(&mut self, change: am::LocalChange) -> result::Result<(), UserError> {
        match self.document.as_ref().lock() {
            Ok(mut document) => document.add_change(change).map_err(invalid_change_request),
            Err(e) => Err(UserError::ConcurrencyError(e.to_string())),
        }
    }
}

impl<'a> NoteMap for MutableAutomergeNoteMap<'a> {
    type Properties = MutableAutomergeNote<'a>;

    /// Returns an IdPath to the identified note, creating it if it doesn't exist.
    fn get(&self, id: &Note) -> Self::Properties {
        Self::Properties {
            map: self.clone(),
            path: IdPath::from(id),
        }
    }
}

/// A [PropertiesMut] backed by an [am::MutableDocument].
#[derive(Clone)]
pub struct MutableAutomergeNote<'a> {
    map: MutableAutomergeNoteMap<'a>,
    path: IdPath,
}

impl<'a> MutableAutomergeNote<'a> {
    fn create_if_not_exists(&mut self) -> result::Result<(), UserError> {
        match self.map.value_at_path(self.path.path_ref()) {
            Some(_) => Ok(()),
            None => self.map.add_change(am::LocalChange::set(
                self.path.clone().path(),
                am::Value::Map(
                    [("notes".into(), am::Value::List(Vec::new()))]
                        .iter()
                        .cloned()
                        .collect(),
                ),
            )),
        }
    }
    fn to_properties(&self) -> PropertiesSnapshot {
        self.map
            .value_at_path(self.path.path_ref())
            .map(|v| AutomergeProperties::from(v).0)
            .unwrap_or_default()
    }
}

impl<'a> Properties for MutableAutomergeNote<'a> {
    fn value(&self) -> Value {
        self.to_properties().value()
    }
    fn isa(&self) -> Vec<Note> {
        self.to_properties().isa()
    }
    fn occurrences(&self) -> Vec<Note> {
        self.to_properties().occurrences()
    }
}

impl From<AutomergeNote> for am::Value {
    fn from(n: AutomergeNote) -> Self {
        am::Value::Primitive(am::Primitive::Str(n.to_smol_str()))
    }
}

impl<'a> PropertiesMut for MutableAutomergeNote<'a> {
    fn update_value_text(&mut self, delta: &[StrOp<'_>]) -> result::Result<&mut Self, UserError> {
        let path: FieldPath = (self.path.clone(), Field::ValueText).into();
        self.create_if_not_exists()?;
        if self.map.value_at_path(&path).is_none() {
            self.map.add_change(am::LocalChange::set(
                path.0.clone(),
                am::Value::Text([].into()),
            ))?;
        }
        for change in path.apply_ops(Vec::from(delta).into_iter())? {
            self.map.add_change(change)?;
        }
        Ok(self)
    }

    fn update_value_datatype(&mut self, datatype: Note) -> result::Result<&mut Self, UserError> {
        self.create_if_not_exists()?;
        self.map.add_change(am::LocalChange::set(
            self.path.clone().value_datatype_path(),
            am::Primitive::Str(datatype.to_smol_str()),
        ))?;
        Ok(self)
    }

    fn update_isa(&mut self, delta: &[NotesOp]) -> result::Result<&mut Self, UserError> {
        let path: FieldPath = (self.path.clone(), Field::IsA).into();
        self.create_if_not_exists()?;
        if self.map.value_at_path(&path).is_none() {
            self.map.add_change(am::LocalChange::set(
                path.0.clone(),
                am::Value::List([].into()),
            ))?;
        }
        for change in path.apply_ops(Vec::from(delta).into_iter())? {
            self.map.add_change(change)?;
        }
        Ok(self)
    }

    fn update_occurrences(&mut self, delta: &[NotesOp]) -> result::Result<&mut Self, UserError> {
        let path: FieldPath = (self.path.clone(), Field::Occurrences).into();
        self.create_if_not_exists()?;
        if self.map.value_at_path(&path).is_none() {
            self.map.add_change(am::LocalChange::set(
                path.0.clone(),
                am::Value::List([].into()),
            ))?;
        }
        for change in path.apply_ops(Vec::from(delta).into_iter())? {
            self.map.add_change(change)?;
        }
        Ok(self)
    }
}

impl<'a> MutableAutomergeNote<'a> {
    /*
    pub fn move_occurrences(&mut self, from: &[usize], to: usize) -> result::Result<(), UserError> {
        // Load the current list of occurrences:
        let occurrences = self.occurrences();
        // Check the parameters for safety:
        if let Some(err) = from
            .iter()
            .filter(|i| **i >= occurrences.len())
            .map(|i| UserError::IndexOutOfBounds {
                index: *i,
                bound: occurrences.len(),
            })
            .next()
        {
            return Err(err);
        }
        if to >= (occurrences.len() - from.len()) {
            return Err(UserError::IndexOutOfBounds {
                index: to,
                bound: occurrences.len() - from.len(),
            });
        }
        // Copy out the occurrences that are going to be moved:
        let many = from
            .iter()
            .map(|f| self.occurrences()[*f].to_string().as_str().into())
            .collect();
        // Delete them from their old locations:
        let path = self.path.clone().occurrences_path();
        let from32 = from
            .iter()
            .map(|u| cast_to_u32(*u))
            .collect::<result::Result<Vec<u32>, UserError>>()?;
        use am::LocalChange;
        for f in from32 {
            self.map
                .add_change(LocalChange::delete(path.clone().index(f)))?;
        }
        // Finally add them to their new location:
        self.map.add_change(LocalChange::insert_many(
            path.clone().index(cast_to_u32(to)?),
            many,
        ))
    }
    */
}

fn invalid_change_request(e: am::InvalidChangeRequest) -> UserError {
    e.into()
}

fn cast_to_u32(u: usize) -> result::Result<u32, UserError> {
    if u > (std::u32::MAX as usize) {
        Err(UserError::Overflow {
            over: u,
            max: (std::u32::MAX as usize),
        })
    } else {
        Ok(u as u32)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn notes_exist_implicitly_and_empty_by_default() {
        let map = AutomergeNoteMap::default();
        let a = Note::random();
        let note_a = map.get(&a);
        assert!(note_a.is_empty());
        assert_eq!(note_a.value(), Value::default());
        assert_eq!(note_a.occurrences(), Vec::from([]));
    }

    #[test]
    fn create_note_with_value() {
        let mut map = AutomergeNoteMap::default();
        let a = &Note::random();
        map.merge_local("", |map| {
            map.get(a).update_value_text(&[Op::Insert("TEST".into())])?;
            Ok(())
        })
        .expect("");
        let note_a = map.get(a);
        assert!(!note_a.is_empty());
        assert_eq!(note_a.value(), Value::from("TEST"));
        assert!(note_a.occurrences().is_empty());
    }

    #[test]
    fn create_note_with_occurrence() {
        let mut map = AutomergeNoteMap::default();
        let a = Note::random();
        let b = Note::random();
        map.merge_local("", |map| map.get(&a).link_occurrence(0, b))
            .expect("");
        let note_a = map.get(&a);
        assert!(!note_a.is_empty());
        assert_eq!(note_a.value(), Value::default());
        assert_eq!(note_a.occurrences().len(), 1);
        assert_eq!(note_a.occurrences()[0], b);
    }

    #[test]
    fn create_note_with_value_and_edit_value() {
        let mut map = AutomergeNoteMap::default();
        let a = &Note::random();
        map.merge_local("", |map| {
            map.get(a).update_value_text(&[Op::Insert("TEST".into())])?;
            Ok(())
        })
        .expect("");
        map.merge_local("", |map| {
            use Op::*;
            map.get(a).update_value_text(&[
                Delete(2),
                Insert("PA".into()),
                Retain(1),
                Insert("S".into()),
                Delete(1),
            ])?;
            Ok(())
        })
        .expect("");
        let note_a = map.get(a);
        assert!(!note_a.is_empty());
        assert_eq!(note_a.value(), Value::from("PASS"));
        assert!(note_a.occurrences().is_empty());
    }

    #[test]
    fn create_note_with_occurrence_and_unlink_occurrence() {
        let mut map = AutomergeNoteMap::default();
        let a = Note::random();
        let b = Note::random();
        map.merge_local("", |map| map.get(&a).link_occurrence(0, b))
            .expect("");
        map.merge_local("", |map| map.get(&a).unlink_occurrence(0))
            .expect("");
        let note_a = map.get(&a);
        assert!(note_a.is_empty());
    }

    /*
    #[test]
    fn create_note_with_occurrences_and_move_occurrence() {
        let mut map = AutomergeNoteMap::default();
        let a = Note::random();
        let b = Note::random();
        let c = Note::random();
        let d = Note::random();
        map.merge_local("", |map| map.get(&a).link_occurrence(0, b))
            .expect("");
        map.merge_local("", |map| map.get(&a).link_occurrence(1, c))
            .expect("");
        map.merge_local("", |map| map.get(&a).link_occurrence(2, d))
            .expect("");
        assert_eq!(map.get(&a).occurrences(), Vec::from([b, c, d]));
        map.merge_local("", |map| map.get(&a).move_occurrences(&[2, 1], 0))
            .expect("");
        assert_eq!(map.get(&a).occurrences(), Vec::from([d, c, b]));
    }
    */

    #[test]
    fn unlink_out_of_bounds_rejected() {
        let mut map = AutomergeNoteMap::default();
        let a = Note::random();
        let b = Note::random();
        assert!(map
            .merge_local("", |map| map.get(&a).link_occurrence(0, b))
            .is_ok());
        assert!(map
            .merge_local("", |map| map.get(&a).unlink_occurrence(1))
            .is_err());
        assert_eq!(map.get(&a).occurrences(), Vec::from([b]));
    }

    /*
    #[test]
    fn move_from_out_of_bounds_rejected() {
        let mut map = AutomergeNoteMap::default();
        let a = Note::random();
        let b = Note::random();
        assert!(map
            .merge_local("", |map| map.get(&a).link_occurrence(0, b))
            .is_ok());
        assert!(map
            .merge_local("", |map| map.get(&a).move_occurrences(&[1], 0))
            .is_err());
        assert_eq!(map.get(&a).occurrences(), Vec::from([b]));
    }

    #[test]
    fn move_to_out_of_bounds_rejected() {
        let mut map = AutomergeNoteMap::default();
        let a = Note::random();
        let b = Note::random();
        assert!(map
            .merge_local("", |map| map.get(&a).link_occurrence(0, b))
            .is_ok());
        assert!(map
            .merge_local("", |map| map.get(&a).move_occurrences(&[0], 1))
            .is_err());
        assert_eq!(map.get(&a).occurrences(), Vec::from([b]));
    }
    */

    #[test]
    fn restore_from_saved() {
        let topic = Note::random();
        {
            let mut map =
                AutomergeNoteMap::open(Location::SledName("test_restore_from_saved".into()))
                    .expect("sled db should be durable")
                    .expect("opening any named sled should not be a user error");
            assert!(map
                .merge_local("", |map| map
                    .get(&topic)
                    .update_value_text(&[Op::Insert("saved".into())])
                    .map(|_| 0))
                .is_ok());
            //map.sync().expect("").expect("");
            drop(map);
        }
        {
            let map = AutomergeNoteMap::open(Location::SledName("test_restore_from_saved".into()))
                .expect("")
                .expect("");
            assert_eq!(map.get(&topic).value().text(), "saved");
        }
    }
}
