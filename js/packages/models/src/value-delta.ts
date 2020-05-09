// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

function assertNever(x: never): never {
  throw new Error('Unexpected object: ' + x);
}

/** Describes a sequence of operations that might be applied to a string.
 */
export default class ValueDelta {
  #ops: ValueOp[] = [];

  constructor(ops: ValueOp[] = []) {
    this.#ops = [...ops];
  }

  /** Retains, or skips over, part of the target string.
   *
   * @param length - the number of characters to retain.
   */
  retain(length: number): this {
    this.#ops.push({kind: 'retain', retain: length});
    return this;
  }

  insert(content: string): this {
    this.#ops.push({kind: 'insert', insert: content});
    return this;
  }

  remove(length: number): this {
    this.#ops.push({kind: 'remove', remove: length});
    return this;
  }

  append(op: ValueOp): this {
    switch (op.kind) {
      case 'retain':
        return this.retain(op.retain);
      case 'insert':
        return this.insert(op.insert);
      case 'remove':
        return this.remove(op.remove);
      default:
        return assertNever(op);
    }
  }

  compose(other: ValueDelta): ValueDelta {
    const merged = new ValueDelta();
    const ti = this.#ops[Symbol.iterator]();
    const oi = other.#ops[Symbol.iterator]();
    let t = ti.next();
    let o = oi.next();
    while (!t.done || !o.done) {
      if (t.done) {
        merged.append(o.value);
        o = oi.next();
      } else if (o.done) {
        merged.append(t.value);
        t = ti.next();
      } else if (!t.done && !o.done) {
        switch (o.value.kind) {
          case 'insert':
            merged.append(o.value);
            o = oi.next();
            break;
          case 'retain':
            switch (t.value.kind) {
              case 'retain':
                if (o.value.retain < t.value.retain) {
                  merged.retain(o.value.retain);
                  t.value = {
                    kind: 'retain',
                    retain: t.value.retain - o.value.retain,
                  };
                  o = oi.next();
                } else if (o.value.retain == t.value.retain) {
                  merged.retain(o.value.retain);
                  t = ti.next();
                  o = oi.next();
                } else {
                  merged.retain(t.value.retain);
                  o.value = {
                    kind: 'retain',
                    retain: o.value.retain - t.value.retain,
                  };
                  t = ti.next();
                }
                break;
              case 'insert':
                if (o.value.retain < t.value.insert.length) {
                  merged.insert(t.value.insert.slice(0, o.value.retain));
                  t.value = {
                    kind: 'insert',
                    insert: t.value.insert.slice(o.value.retain),
                  };
                  o = oi.next();
                } else {
                  const retain = o.value.retain - t.value.insert.length;
                  merged.append(t.value);
                  if (retain > 0) {
                    o.value = {
                      kind: 'retain',
                      retain: o.value.retain - t.value.insert.length,
                    };
                  } else {
                    o = oi.next();
                  }
                  t = ti.next();
                }
                break;
              case 'remove':
                if (o.value.retain < t.value.remove) {
                  merged.remove(o.value.retain);
                  t.value = {
                    kind: 'remove',
                    remove: t.value.remove - o.value.retain,
                  };
                  o = oi.next();
                } else {
                  merged.append(t.value);
                  if (o.value.retain == t.value.remove) {
                    o = oi.next();
                  } else {
                    o.value = {
                      kind: 'remove',
                      remove: o.value.retain - t.value.remove,
                    };
                  }
                  t = ti.next();
                }
                break;
              default:
                return assertNever(t.value);
            }
            break;
          case 'remove':
            switch (t.value.kind) {
              case 'retain':
                if (o.value.remove < t.value.retain) {
                  merged.remove(o.value.remove);
                  t.value = {
                    kind: 'retain',
                    retain: t.value.retain - o.value.remove,
                  };
                  o = oi.next();
                } else {
                  merged.remove(t.value.retain);
                  if (o.value.remove == t.value.retain) {
                    o = oi.next();
                  } else {
                    o.value = {
                      kind: 'remove',
                      remove: o.value.remove - t.value.retain,
                    };
                  }
                  t = ti.next();
                }
                break;
              case 'insert':
                break;
              case 'remove':
                break;
              default:
                return assertNever(t.value);
            }
            break;
          default:
            return assertNever(o.value);
        }
      }
    }
    return merged;
  }

  apply(value: string): string {
    let result = '';
    let i = 0;
    for (const op of this.#ops) {
      switch (op.kind) {
        case 'retain':
          result += value.slice(i, i + op.retain);
          i += op.retain;
          break;
        case 'insert':
          result += op.insert;
          break;
        case 'remove':
          i += op.remove;
          break;
        default:
          return assertNever(op);
      }
    }
    return result + value.slice(i);
  }
}

export interface ValueDeltaRetain {
  kind: 'retain';
  readonly retain: number;
}

export interface ValueDeltaInsert {
  kind: 'insert';
  readonly insert: string;
}

export interface ValueDeltaRemove {
  kind: 'remove';
  readonly remove: number;
}

export type ValueOp = ValueDeltaRetain | ValueDeltaInsert | ValueDeltaRemove;
