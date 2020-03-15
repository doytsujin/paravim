type
  uint16_t = uint16
  uint32_t = uint32
  uint64_t = uint64
  int64_t = int64

## **************************
##  Section - ABI Versioning
## **************************
## *
##  The latest ABI version that is supported by the current version of the
##  library. When Languages are generated by the Tree-sitter CLI, they are
##  assigned an ABI version number that corresponds to the current CLI version.
##  The Tree-sitter library is generally backwards-compatible with languages
##  generated using older CLI versions, but is not forwards-compatible.
##

const
  TREE_SITTER_LANGUAGE_VERSION* = 11

## *
##  The earliest ABI version that is supported by the current version of the
##  library.
##

const
  TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION* = 9

## *****************
##  Section - Types
## *****************

type
  TSSymbol* = uint16_t
  TSFieldId* = uint16_t
  TSInputEncoding* = enum
    TSInputEncodingUTF8, TSInputEncodingUTF16
  TSSymbolType* = enum
    TSSymbolTypeRegular, TSSymbolTypeAnonymous, TSSymbolTypeAuxiliary
  TSPoint* {.bycopy.} = object
    row*: uint32_t
    column*: uint32_t

  TSRange* {.bycopy.} = object
    start_point*: TSPoint
    end_point*: TSPoint
    start_byte*: uint32_t
    end_byte*: uint32_t

  TSInput* {.bycopy.} = object
    payload*: pointer
    read*: proc (payload: pointer; byte_index: uint32_t; position: TSPoint;
               bytes_read: ptr uint32_t): cstring
    encoding*: TSInputEncoding

  TSLogType* = enum
    TSLogTypeParse, TSLogTypeLex
  TSLogger* {.bycopy.} = object
    payload*: pointer
    log*: proc (payload: pointer; a2: TSLogType; a3: cstring)

  TSInputEdit* {.bycopy.} = object
    start_byte*: uint32_t
    old_end_byte*: uint32_t
    new_end_byte*: uint32_t
    start_point*: TSPoint
    old_end_point*: TSPoint
    new_end_point*: TSPoint

  TSNode* {.bycopy.} = object
    context*: array[4, uint32_t]
    id*: pointer
    tree*: pointer #ptr TSTree

  TSTreeCursor* {.bycopy.} = object
    tree*: pointer
    id*: pointer
    context*: array[2, uint32_t]

  TSQueryCapture* {.bycopy.} = object
    node*: TSNode
    index*: uint32_t

  TSQueryMatch* {.bycopy.} = object
    id*: uint32_t
    pattern_index*: uint16_t
    capture_count*: uint16_t
    captures*: ptr TSQueryCapture

  TSQueryPredicateStepType* = enum
    TSQueryPredicateStepTypeDone, TSQueryPredicateStepTypeCapture,
    TSQueryPredicateStepTypeString
  TSQueryPredicateStep* {.bycopy.} = object
    `type`*: TSQueryPredicateStepType
    value_id*: uint32_t

  TSQueryError* = enum
    TSQueryErrorNone = 0, TSQueryErrorSyntax, TSQueryErrorNodeType,
    TSQueryErrorField, TSQueryErrorCapture






## ******************
##  Section - Parser
## ******************
## *
##  Create a new parser.
##

#proc ts_parser_new*(): ptr TSParser
proc ts_parser_new*(): pointer {.cdecl, importc: "ts_parser_new".}
## *
##  Delete the parser, freeing all of the memory that it used.
##

#proc ts_parser_delete*(parser: ptr TSParser)
proc ts_parser_delete*(parser: pointer) {.cdecl, importc: "ts_parser_delete".}
## *
##  Set the language that the parser should use for parsing.
##
##  Returns a boolean indicating whether or not the language was successfully
##  assigned. True means assignment succeeded. False means there was a version
##  mismatch: the language was generated with an incompatible version of the
##  Tree-sitter CLI. Check the language's version using `ts_language_version`
##  and compare it to this library's `TREE_SITTER_LANGUAGE_VERSION` and
##  `TREE_SITTER_MIN_COMPATIBLE_LANGUAGE_VERSION` constants.
##

#proc ts_parser_set_language*(self: ptr TSParser; language: ptr TSLanguage): bool
proc ts_parser_set_language*(self: pointer; language: pointer): bool {.cdecl, importc: "ts_parser_set_language".}
## *
##  Get the parser's current language.
##

#proc ts_parser_language*(self: ptr TSParser): ptr TSLanguage
## *
##  Set the ranges of text that the parser should include when parsing.
##
##  By default, the parser will always include entire documents. This function
##  allows you to parse only a *portion* of a document but still return a syntax
##  tree whose ranges match up with the document as a whole. You can also pass
##  multiple disjoint ranges.
##
##  The second and third parameters specify the location and length of an array
##  of ranges. The parser does *not* take ownership of these ranges; it copies
##  the data, so it doesn't matter how these ranges are allocated.
##
##  If `length` is zero, then the entire document will be parsed. Otherwise,
##  the given ranges must be ordered from earliest to latest in the document,
##  and they must not overlap. That is, the following must hold for all
##  `i` < `length - 1`:
##
##      ranges[i].end_byte <= ranges[i + 1].start_byte
##
##  If this requirement is not satisfied, the operation will fail, the ranges
##  will not be assigned, and this function will return `false`. On success,
##  this function returns `true`
##

#proc ts_parser_set_included_ranges*(self: ptr TSParser; ranges: ptr TSRange;
#                                   length: uint32_t): bool
## *
##  Get the ranges of text that the parser will include when parsing.
##
##  The returned pointer is owned by the parser. The caller should not free it
##  or write to it. The length of the array will be written to the given
##  `length` pointer.
##

#proc ts_parser_included_ranges*(self: ptr TSParser; length: ptr uint32_t): ptr TSRange
## *
##  Use the parser to parse some source code and create a syntax tree.
##
##  If you are parsing this document for the first time, pass `NULL` for the
##  `old_tree` parameter. Otherwise, if you have already parsed an earlier
##  version of this document and the document has since been edited, pass the
##  previous syntax tree so that the unchanged parts of it can be reused.
##  This will save time and memory. For this to work correctly, you must have
##  already edited the old syntax tree using the `ts_tree_edit` function in a
##  way that exactly matches the source code changes.
##
##  The `TSInput` parameter lets you specify how to read the text. It has the
##  following three fields:
##  1. `read`: A function to retrieve a chunk of text at a given byte offset
##     and (row, column) position. The function should return a pointer to the
##     text and write its length to the the `bytes_read` pointer. The parser
##     does not take ownership of this buffer; it just borrows it until it has
##     finished reading it. The function should write a zero value to the
##     `bytes_read` pointer to indicate the end of the document.
##  2. `payload`: An arbitrary pointer that will be passed to each invocation
##     of the `read` function.
##  3. `encoding`: An indication of how the text is encoded. Either
##     `TSInputEncodingUTF8` or `TSInputEncodingUTF16`.
##
##  This function returns a syntax tree on success, and `NULL` on failure. There
##  are three possible reasons for failure:
##  1. The parser does not have a language assigned. Check for this using the
##       `ts_parser_language` function.
##  2. Parsing was cancelled due to a timeout that was set by an earlier call to
##     the `ts_parser_set_timeout_micros` function. You can resume parsing from
##     where the parser left out by calling `ts_parser_parse` again with the
##     same arguments. Or you can start parsing from scratch by first calling
##     `ts_parser_reset`.
##  3. Parsing was cancelled using a cancellation flag that was set by an
##     earlier call to `ts_parser_set_cancellation_flag`. You can resume parsing
##     from where the parser left out by calling `ts_parser_parse` again with
##     the same arguments.
##

#proc ts_parser_parse*(self: ptr TSParser; old_tree: ptr TSTree; input: TSInput): ptr TSTree
## *
##  Use the parser to parse some source code stored in one contiguous buffer.
##  The first two parameters are the same as in the `ts_parser_parse` function
##  above. The second two parameters indicate the location of the buffer and its
##  length in bytes.
##

#proc ts_parser_parse_string*(self: ptr TSParser; old_tree: ptr TSTree; string: cstring;
#                            length: uint32_t): ptr TSTree
proc ts_parser_parse_string*(self: pointer; old_tree: pointer; string: cstring;
                            length: uint32_t): pointer {.cdecl, importc: "ts_parser_parse_string".}
## *
##  Use the parser to parse some source code stored in one contiguous buffer with
##  a given encoding. The first four parameters work the same as in the
##  `ts_parser_parse_string` method above. The final parameter indicates whether
##  the text is encoded as UTF8 or UTF16.
##

#proc ts_parser_parse_string_encoding*(self: ptr TSParser; old_tree: ptr TSTree;
#                                     string: cstring; length: uint32_t;
#                                     encoding: TSInputEncoding): ptr TSTree
## *
##  Instruct the parser to start the next parse from the beginning.
##
##  If the parser previously failed because of a timeout or a cancellation, then
##  by default, it will resume where it left off on the next call to
##  `ts_parser_parse` or other parsing functions. If you don't want to resume,
##  and instead intend to use this parser to parse some other document, you must
##  call `ts_parser_reset` first.
##

#proc ts_parser_reset*(self: ptr TSParser)
## *
##  Set the maximum duration in microseconds that parsing should be allowed to
##  take before halting.
##
##  If parsing takes longer than this, it will halt early, returning NULL.
##  See `ts_parser_parse` for more information.
##

#proc ts_parser_set_timeout_micros*(self: ptr TSParser; timeout: uint64_t)
## *
##  Get the duration in microseconds that parsing is allowed to take.
##

#proc ts_parser_timeout_micros*(self: ptr TSParser): uint64_t
## *
##  Set the parser's current cancellation flag pointer.
##
##  If a non-null pointer is assigned, then the parser will periodically read
##  from this pointer during parsing. If it reads a non-zero value, it will
##  halt early, returning NULL. See `ts_parser_parse` for more information.
##

#proc ts_parser_set_cancellation_flag*(self: ptr TSParser; flag: ptr csize)
## *
##  Get the parser's current cancellation flag pointer.
##

#proc ts_parser_cancellation_flag*(self: ptr TSParser): ptr csize
## *
##  Set the logger that a parser should use during parsing.
##
##  The parser does not take ownership over the logger payload. If a logger was
##  previously assigned, the caller is responsible for releasing any memory
##  owned by the previous logger.
##

#proc ts_parser_set_logger*(self: ptr TSParser; logger: TSLogger)
## *
##  Get the parser's current logger.
##

#proc ts_parser_logger*(self: ptr TSParser): TSLogger
## *
##  Set the file descriptor to which the parser should write debugging graphs
##  during parsing. The graphs are formatted in the DOT language. You may want
##  to pipe these graphs directly to a `dot(1)` process in order to generate
##  SVG output. You can turn off this logging by passing a negative number.
##

#proc ts_parser_print_dot_graphs*(self: ptr TSParser; file: cint)
## ****************
##  Section - Tree
## ****************
## *
##  Create a shallow copy of the syntax tree. This is very fast.
##
##  You need to copy a syntax tree in order to use it on more than one thread at
##  a time, as syntax trees are not thread safe.
##

#proc ts_tree_copy*(self: ptr TSTree): ptr TSTree
## *
##  Delete the syntax tree, freeing all of the memory that it used.
##

#proc ts_tree_delete*(self: ptr TSTree)
proc ts_tree_delete*(self: pointer) {.cdecl, importc: "ts_tree_delete".}
## *
##  Get the root node of the syntax tree.
##

#proc ts_tree_root_node*(self: ptr TSTree): TSNode
proc ts_tree_root_node*(self: pointer): TSNode {.cdecl, importc: "ts_tree_root_node".}
## *
##  Get the language that was used to parse the syntax tree.
##

#proc ts_tree_language*(a1: ptr TSTree): ptr TSLanguage
## *
##  Edit the syntax tree to keep it in sync with source code that has been
##  edited.
##
##  You must describe the edit both in terms of byte offsets and in terms of
##  (row, column) coordinates.
##

#proc ts_tree_edit*(self: ptr TSTree; edit: ptr TSInputEdit)
## *
##  Compare an old edited syntax tree to a new syntax tree representing the same
##  document, returning an array of ranges whose syntactic structure has changed.
##
##  For this to work correctly, the old syntax tree must have been edited such
##  that its ranges match up to the new tree. Generally, you'll want to call
##  this function right after calling one of the `ts_parser_parse` functions.
##  You need to pass the old tree that was passed to parse, as well as the new
##  tree that was returned from that function.
##
##  The returned array is allocated using `malloc` and the caller is responsible
##  for freeing it using `free`. The length of the array will be written to the
##  given `length` pointer.
##

#proc ts_tree_get_changed_ranges*(old_tree: ptr TSTree; new_tree: ptr TSTree;
#                                length: ptr uint32_t): ptr TSRange
## *
##  Write a DOT graph describing the syntax tree to the given file.
##

#proc ts_tree_print_dot_graph*(a1: ptr TSTree; a2: ptr FILE)
## ****************
##  Section - Node
## ****************
## *
##  Get the node's type as a null-terminated string.
##

proc ts_node_type*(a1: TSNode): cstring {.cdecl, importc: "ts_node_type".}
## *
##  Get the node's type as a numerical id.
##

#proc ts_node_symbol*(a1: TSNode): TSSymbol
## *
##  Get the node's start byte.
##

#proc ts_node_start_byte*(a1: TSNode): uint32_t
## *
##  Get the node's start position in terms of rows and columns.
##

proc ts_node_start_point*(a1: TSNode): TSPoint {.cdecl, importc: "ts_node_start_point".}
## *
##  Get the node's end byte.
##

#proc ts_node_end_byte*(a1: TSNode): uint32_t
## *
##  Get the node's end position in terms of rows and columns.
##

proc ts_node_end_point*(a1: TSNode): TSPoint {.cdecl, importc: "ts_node_start_point".}
## *
##  Get an S-expression representing the node as a string.
##
##  This string is allocated with `malloc` and the caller is responsible for
##  freeing it using `free`.
##

#proc ts_node_string*(a1: TSNode): cstring
proc ts_node_string*(a1: TSNode): cstring {.cdecl, importc: "ts_node_string".}
## *
##  Check if the node is null. Functions like `ts_node_child` and
##  `ts_node_next_sibling` will return a null node to indicate that no such node
##  was found.
##

#proc ts_node_is_null*(a1: TSNode): bool
## *
##  Check if the node is *named*. Named nodes correspond to named rules in the
##  grammar, whereas *anonymous* nodes correspond to string literals in the
##  grammar.
##

#proc ts_node_is_named*(a1: TSNode): bool
## *
##  Check if the node is *missing*. Missing nodes are inserted by the parser in
##  order to recover from certain kinds of syntax errors.
##

#proc ts_node_is_missing*(a1: TSNode): bool
## *
##  Check if the node is *extra*. Extra nodes represent things like comments,
##  which are not required the grammar, but can appear anywhere.
##

#proc ts_node_is_extra*(a1: TSNode): bool
## *
##  Check if a syntax node has been edited.
##

#proc ts_node_has_changes*(a1: TSNode): bool
## *
##  Check if the node is a syntax error or contains any syntax errors.
##

#proc ts_node_has_error*(a1: TSNode): bool
## *
##  Get the node's immediate parent.
##

#proc ts_node_parent*(a1: TSNode): TSNode
## *
##  Get the node's child at the given index, where zero represents the first
##  child.
##

proc ts_node_child*(a1: TSNode; a2: uint32_t): TSNode {.cdecl, importc: "ts_node_child".}
## *
##  Get the node's number of children.
##

proc ts_node_child_count*(a1: TSNode): uint32_t {.cdecl, importc: "ts_node_child_count".}
## *
##  Get the node's *named* child at the given index.
##
##  See also `ts_node_is_named`.
##

#proc ts_node_named_child*(a1: TSNode; a2: uint32_t): TSNode
## *
##  Get the node's number of *named* children.
##
##  See also `ts_node_is_named`.
##

#proc ts_node_named_child_count*(a1: TSNode): uint32_t
## *
##  Get the node's child with the given field name.
##

#proc ts_node_child_by_field_name*(self: TSNode; field_name: cstring;
#                                 field_name_length: uint32_t): TSNode
## *
##  Get the node's child with the given numerical field id.
##
##  You can convert a field name to an id using the
##  `ts_language_field_id_for_name` function.
##

#proc ts_node_child_by_field_id*(a1: TSNode; a2: TSFieldId): TSNode
## *
##  Get the node's next / previous sibling.
##

#proc ts_node_next_sibling*(a1: TSNode): TSNode
#proc ts_node_prev_sibling*(a1: TSNode): TSNode
## *
##  Get the node's next / previous *named* sibling.
##

#proc ts_node_next_named_sibling*(a1: TSNode): TSNode
#proc ts_node_prev_named_sibling*(a1: TSNode): TSNode
## *
##  Get the node's first child that extends beyond the given byte offset.
##

#proc ts_node_first_child_for_byte*(a1: TSNode; a2: uint32_t): TSNode
## *
##  Get the node's first named child that extends beyond the given byte offset.
##

#proc ts_node_first_named_child_for_byte*(a1: TSNode; a2: uint32_t): TSNode
## *
##  Get the smallest node within this node that spans the given range of bytes
##  or (row, column) positions.
##

#proc ts_node_descendant_for_byte_range*(a1: TSNode; a2: uint32_t; a3: uint32_t): TSNode
#proc ts_node_descendant_for_point_range*(a1: TSNode; a2: TSPoint; a3: TSPoint): TSNode
## *
##  Get the smallest named node within this node that spans the given range of
##  bytes or (row, column) positions.
##

#proc ts_node_named_descendant_for_byte_range*(a1: TSNode; a2: uint32_t; a3: uint32_t): TSNode
#proc ts_node_named_descendant_for_point_range*(a1: TSNode; a2: TSPoint; a3: TSPoint): TSNode
## *
##  Edit the node to keep it in-sync with source code that has been edited.
##
##  This function is only rarely needed. When you edit a syntax tree with the
##  `ts_tree_edit` function, all of the nodes that you retrieve from the tree
##  afterward will already reflect the edit. You only need to use `ts_node_edit`
##  when you have a `TSNode` instance that you want to keep and continue to use
##  after an edit.
##

#proc ts_node_edit*(a1: ptr TSNode; a2: ptr TSInputEdit)
## *
##  Check if two nodes are identical.
##

#proc ts_node_eq*(a1: TSNode; a2: TSNode): bool
## **********************
##  Section - TreeCursor
## **********************
## *
##  Create a new tree cursor starting from the given node.
##
##  A tree cursor allows you to walk a syntax tree more efficiently than is
##  possible using the `TSNode` functions. It is a mutable object that is always
##  on a certain syntax node, and can be moved imperatively to different nodes.
##

#proc ts_tree_cursor_new*(a1: TSNode): TSTreeCursor
## *
##  Delete a tree cursor, freeing all of the memory that it used.
##

#proc ts_tree_cursor_delete*(a1: ptr TSTreeCursor)
## *
##  Re-initialize a tree cursor to start at a different node.
##

#proc ts_tree_cursor_reset*(a1: ptr TSTreeCursor; a2: TSNode)
## *
##  Get the tree cursor's current node.
##

#proc ts_tree_cursor_current_node*(a1: ptr TSTreeCursor): TSNode
## *
##  Get the field name of the tree cursor's current node.
##
##  This returns `NULL` if the current node doesn't have a field.
##  See also `ts_node_child_by_field_name`.
##

#proc ts_tree_cursor_current_field_name*(a1: ptr TSTreeCursor): cstring
## *
##  Get the field name of the tree cursor's current node.
##
##  This returns zero if the current node doesn't have a field.
##  See also `ts_node_child_by_field_id`, `ts_language_field_id_for_name`.
##

#proc ts_tree_cursor_current_field_id*(a1: ptr TSTreeCursor): TSFieldId
## *
##  Move the cursor to the parent of its current node.
##
##  This returns `true` if the cursor successfully moved, and returns `false`
##  if there was no parent node (the cursor was already on the root node).
##

#proc ts_tree_cursor_goto_parent*(a1: ptr TSTreeCursor): bool
## *
##  Move the cursor to the next sibling of its current node.
##
##  This returns `true` if the cursor successfully moved, and returns `false`
##  if there was no next sibling node.
##

#proc ts_tree_cursor_goto_next_sibling*(a1: ptr TSTreeCursor): bool
## *
##  Move the cursor to the first child of its current node.
##
##  This returns `true` if the cursor successfully moved, and returns `false`
##  if there were no children.
##

#proc ts_tree_cursor_goto_first_child*(a1: ptr TSTreeCursor): bool
## *
##  Move the cursor to the first child of its current node that extends beyond
##  the given byte offset.
##
##  This returns the index of the child node if one was found, and returns -1
##  if no such child was found.
##

#proc ts_tree_cursor_goto_first_child_for_byte*(a1: ptr TSTreeCursor; a2: uint32_t): int64_t
#proc ts_tree_cursor_copy*(a1: ptr TSTreeCursor): TSTreeCursor
## *****************
##  Section - Query
## *****************
## *
##  Create a new query from a string containing one or more S-expression
##  patterns. The query is associated with a particular language, and can
##  only be run on syntax nodes parsed with that language.
##
##  If all of the given patterns are valid, this returns a `TSQuery`.
##  If a pattern is invalid, this returns `NULL`, and provides two pieces
##  of information about the problem:
##  1. The byte offset of the error is written to the `error_offset` parameter.
##  2. The type of error is written to the `error_type` parameter.
##

#proc ts_query_new*(language: ptr TSLanguage; source: cstring; source_len: uint32_t;
#                  error_offset: ptr uint32_t; error_type: ptr TSQueryError): ptr TSQuery
## *
##  Delete a query, freeing all of the memory that it used.
##

#proc ts_query_delete*(a1: ptr TSQuery)
## *
##  Get the number of patterns, captures, or string literals in the query.
##

#proc ts_query_pattern_count*(a1: ptr TSQuery): uint32_t
#proc ts_query_capture_count*(a1: ptr TSQuery): uint32_t
#proc ts_query_string_count*(a1: ptr TSQuery): uint32_t
## *
##  Get the byte offset where the given pattern starts in the query's source.
##
##  This can be useful when combining queries by concatenating their source
##  code strings.
##

#proc ts_query_start_byte_for_pattern*(a1: ptr TSQuery; a2: uint32_t): uint32_t
## *
##  Get all of the predicates for the given pattern in the query.
##
##  The predicates are represented as a single array of steps. There are three
##  types of steps in this array, which correspond to the three legal values for
##  the `type` field:
##  - `TSQueryPredicateStepTypeCapture` - Steps with this type represent names
##     of captures. Their `value_id` can be used with the
##    `ts_query_capture_name_for_id` function to obtain the name of the capture.
##  - `TSQueryPredicateStepTypeString` - Steps with this type represent literal
##     strings. Their `value_id` can be used with the
##     `ts_query_string_value_for_id` function to obtain their string value.
##  - `TSQueryPredicateStepTypeDone` - Steps with this type are *sentinels*
##     that represent the end of an individual predicate. If a pattern has two
##     predicates, then there will be two steps with this `type` in the array.
##

#proc ts_query_predicates_for_pattern*(self: ptr TSQuery; pattern_index: uint32_t;
#                                     length: ptr uint32_t): ptr TSQueryPredicateStep
## *
##  Get the name and length of one of the query's captures, or one of the
##  query's string literals. Each capture and string is associated with a
##  numeric id based on the order that it appeared in the query's source.
##

#proc ts_query_capture_name_for_id*(a1: ptr TSQuery; id: uint32_t; length: ptr uint32_t): cstring
#proc ts_query_string_value_for_id*(a1: ptr TSQuery; id: uint32_t; length: ptr uint32_t): cstring
## *
##  Disable a certain capture within a query.
##
##  This prevents the capture from being returned in matches, and also avoids
##  any resource usage associated with recording the capture. Currently, there
##  is no way to undo this.
##

#proc ts_query_disable_capture*(a1: ptr TSQuery; a2: cstring; a3: uint32_t)
## *
##  Disable a certain pattern within a query.
##
##  This prevents the pattern from matching and removes most of the overhead
##  associated with the pattern. Currently, there is no way to undo this.
##

#proc ts_query_disable_pattern*(a1: ptr TSQuery; a2: uint32_t)
## *
##  Create a new cursor for executing a given query.
##
##  The cursor stores the state that is needed to iteratively search
##  for matches. To use the query cursor, first call `ts_query_cursor_exec`
##  to start running a given query on a given syntax node. Then, there are
##  two options for consuming the results of the query:
##  1. Repeatedly call `ts_query_cursor_next_match` to iterate over all of the
##     the *matches* in the order that they were found. Each match contains the
##     index of the pattern that matched, and an array of captures. Because
##     multiple patterns can match the same set of nodes, one match may contain
##     captures that appear *before* some of the captures from a previous match.
##  2. Repeatedly call `ts_query_cursor_next_capture` to iterate over all of the
##     individual *captures* in the order that they appear. This is useful if
##     don't care about which pattern matched, and just want a single ordered
##     sequence of captures.
##
##  If you don't care about consuming all of the results, you can stop calling
##  `ts_query_cursor_next_match` or `ts_query_cursor_next_capture` at any point.
##   You can then start executing another query on another node by calling
##   `ts_query_cursor_exec` again.
##

#proc ts_query_cursor_new*(): ptr TSQueryCursor
## *
##  Delete a query cursor, freeing all of the memory that it used.
##

#proc ts_query_cursor_delete*(a1: ptr TSQueryCursor)
## *
##  Start running a given query on a given node.
##

#proc ts_query_cursor_exec*(a1: ptr TSQueryCursor; a2: ptr TSQuery; a3: TSNode)
## *
##  Set the range of bytes or (row, column) positions in which the query
##  will be executed.
##

#proc ts_query_cursor_set_byte_range*(a1: ptr TSQueryCursor; a2: uint32_t; a3: uint32_t)
#proc ts_query_cursor_set_point_range*(a1: ptr TSQueryCursor; a2: TSPoint; a3: TSPoint)
## *
##  Advance to the next match of the currently running query.
##
##  If there is a match, write it to `*match` and return `true`.
##  Otherwise, return `false`.
##

#proc ts_query_cursor_next_match*(a1: ptr TSQueryCursor; match: ptr TSQueryMatch): bool
#proc ts_query_cursor_remove_match*(a1: ptr TSQueryCursor; id: uint32_t)
## *
##  Advance to the next capture of the currently running query.
##
##  If there is a capture, write its match to `*match` and its index within
##  the matche's capture list to `*capture_index`. Otherwise, return `false`.
##

#proc ts_query_cursor_next_capture*(a1: ptr TSQueryCursor; match: ptr TSQueryMatch;
#                                  capture_index: ptr uint32_t): bool
## ********************
##  Section - Language
## ********************
## *
##  Get the number of distinct node types in the language.
##

#proc ts_language_symbol_count*(a1: ptr TSLanguage): uint32_t
## *
##  Get a node type string for the given numerical id.
##

#proc ts_language_symbol_name*(a1: ptr TSLanguage; a2: TSSymbol): cstring
## *
##  Get the numerical id for the given node type string.
##

#proc ts_language_symbol_for_name*(self: ptr TSLanguage; string: cstring;
#                                 length: uint32_t; is_named: bool): TSSymbol
## *
##  Get the number of distinct field names in the language.
##

#proc ts_language_field_count*(a1: ptr TSLanguage): uint32_t
## *
##  Get the field name string for the given numerical id.
##

#proc ts_language_field_name_for_id*(a1: ptr TSLanguage; a2: TSFieldId): cstring
## *
##  Get the numerical id for the given field name string.
##

#proc ts_language_field_id_for_name*(a1: ptr TSLanguage; a2: cstring; a3: uint32_t): TSFieldId
## *
##  Check whether the given node type id belongs to named nodes, anonymous nodes,
##  or a hidden nodes.
##
##  See also `ts_node_is_named`. Hidden nodes are never returned from the API.
##

#proc ts_language_symbol_type*(a1: ptr TSLanguage; a2: TSSymbol): TSSymbolType
## *
##  Get the ABI version number for this language. This version number is used
##  to ensure that languages were generated by a compatible version of
##  Tree-sitter.
##
##  See also `ts_parser_set_language`.
##

#proc ts_language_version*(a1: ptr TSLanguage): uint32_t
