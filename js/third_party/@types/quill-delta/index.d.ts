declare interface Op {
    insert?: string | object;
    delete?: number;
    retain?: number;
    attributes?: AttributeMap;
}
declare namespace Op {
    function iterator(ops: Op[]): Iterator;
    function length(op: Op): number;
}
declare interface AttributeMap {
    [key: string]: any;
}
declare namespace AttributeMap {
    function compose(a: AttributeMap | undefined, b: AttributeMap | undefined, keepNull: boolean): AttributeMap | undefined;
    function diff(a?: AttributeMap, b?: AttributeMap): AttributeMap | undefined;
    function invert(attr?: AttributeMap, base?: AttributeMap): AttributeMap;
    function transform(a: AttributeMap | undefined, b: AttributeMap | undefined, priority?: boolean): AttributeMap | undefined;
}
declare class Delta {
    static Op: typeof Op;
    static AttributeMap: typeof AttributeMap;
    ops: Op[];
    constructor(ops?: Op[] | {
        ops: Op[];
    });
    insert(arg: string | object, attributes?: AttributeMap): this;
    delete(length: number): this;
    retain(length: number, attributes?: AttributeMap): this;
    push(newOp: Op): this;
    chop(): this;
    filter(predicate: (op: Op, index: number) => boolean): Op[];
    forEach(predicate: (op: Op, index: number) => void): void;
    map<T>(predicate: (op: Op, index: number) => T): T[];
    partition(predicate: (op: Op) => boolean): [Op[], Op[]];
    reduce<T>(predicate: (accum: T, curr: Op, index: number) => T, initialValue: T): T;
    changeLength(): number;
    length(): number;
    slice(start?: number, end?: number): Delta;
    compose(other: Delta): Delta;
    concat(other: Delta): Delta;
    //diff(other: Delta, cursor?: number | diff.CursorInfo): Delta;
    diff(other: Delta, cursor?: number): Delta;
    eachLine(predicate: (line: Delta, attributes: AttributeMap, index: number) => boolean | void, newline?: string): void;
    invert(base: Delta): Delta;
    transform(index: number, priority?: boolean): number;
    transform(other: Delta, priority?: boolean): Delta;
    transformPosition(index: number, priority?: boolean): number;
}
export = Delta;
declare class Iterator {
    ops: Op[];
    index: number;
    offset: number;
    constructor(ops: Op[]);
    hasNext(): boolean;
    next(length?: number): Op;
    peek(): Op;
    peekLength(): number;
    peekType(): string;
    rest(): Op[];
}
