#let theme = sys.inputs.at("theme", default: "light")
#let text-color = if theme == "dark" { rgb("f0f6fc") } else { rgb("1f2328") }

#set page(width: 800pt, height: auto, margin: 20pt, fill: none)
#set text(fill: text-color, size: 18pt)
#set heading(
  numbering: (..args) => {
    let nums = args.pos()
    if nums.len() > 1 {
      numbering("1.1.", ..nums.slice(1))
    }
  },
)
// #set page(numbering: "1")

= CodeCrafters build your own shell — implementation plan

Reordered into build order (core → parsing → execution features →
interactive polish) rather than course order, and corrected against
POSIX/real-shell behavior where the original draft was wrong or
ambiguous. Lines marked *Verify* are plausible but not independently
confirmed against the actual test cases — check them against your
own test run before trusting the wording here.

#line(length: 100%)

== Build order

+ Core REPL & command dispatch
+ Navigation (`pwd`, `cd`)
+ Tokenizer: quoting
+ Parser: redirection
+ Parser: pipelines
+ Expansion: parameter expansion (`declare`, `$VAR`)
+ Process management: background jobs
+ Interactive: history
+ Interactive: command & file completion
+ Interactive: programmable completion

Each section below is tagged with which layer of the tokenizer /
parser / expansion / executor split it belongs to, so you can see at a
glance what's blocked on what.

#line(length: 100%)

== Core REPL & command dispatch

*Layer: executor (no tokenizer/parser dependency yet — a bare
whitespace split is enough until the Quoting section).*

=== Prompt and REPL loop

+ Display a prompt `$ `.
+ Read a line of input.
+ If the command isn't a builtin and isn't found on `PATH`, print
  `{command}: command not found`.
+ Repeat.

=== The `exit` builtin

- Form: `exit {code}`.
- Exits the shell with the given integer exit code.
- `0` indicates success; any other value indicates an error.
- #strong[Correction from the original draft:] this takes an exit-code
  argument — "terminates the shell" alone is incomplete.

=== The `echo` builtin

- Form: `echo {args...}`.
- Print inputs to stdout, separated by spaces, followed by a newline.

=== The `type` builtin

+ If the argument is a builtin, print `{command} is a shell builtin`.
+ Else, search `PATH`:
  + If found and executable, print `{command} is a <full path>` for
    the first match.
  + Else, print `{command}: not found`.

=== Run external programs

+ Read an input of the form `{program} {args...}`.
+ If `program` resolves to an executable via `PATH`, run it,
  forwarding all arguments.

#line(length: 100%)

== Navigation

*Layer: executor.*

=== The `pwd` builtin

Print the full absolute path to the current working directory.

=== The `cd` builtin

Form: `cd {path}`.

+ If `path` is `~`, change to the user's home directory (from the
  `HOME` environment variable).
+ Else if `path` is an absolute or relative path that exists, change
  to it.
+ Else, print `cd {path}: no such file or directory`.

#line(length: 100%)

== Tokenizer: quoting

*Layer: tokenizer. This is the character-level, quoting-aware scan
that every later stage (redirection, pipelines, parameter expansion)
depends on — get this right before building anything on top of it.*

=== Single quotes

- Everything within `'...'` is literal: spaces aren't collapsed,
  backslash isn't special, no character is treated as an operator or
  expansion trigger.
- Adjacent quoted/unquoted fragments with no separating whitespace
  glue into a single token — `'foo'bar"baz"` is one word, not three.
  #strong[Correction:] this rule isn't specific to two single-quoted
  strings; it applies to any adjacent combination of quoted and
  unquoted spans.
- An empty quoted span (`''`) contributes nothing when glued to
  adjacent fragments (`a''b` → `ab`). #strong[Correction:] this does
  *not* mean a standalone `''` disappears as an argument — `echo ''`
  still passes one empty-string argument to `echo`. Only glued-empty
  spans vanish; a whole empty word does not.

=== Double quotes

- A backslash is only special when immediately followed by `$`,
  `` ` ``, `"`, `\`, or a newline — in those cases it escapes the
  following character. #strong[Correction:] a backslash before a
  single quote (`\'`) is *not* an escape sequence inside double
  quotes; `\'` is a literal backslash followed by a literal `'`. This
  matches both POSIX and real shell test behavior — don't include `'`
  in the escaped-character set.
- `$` triggers expansion (see Parameter expansion, below).
- Everything else behaves like single quotes: literal, no operator
  meaning.

=== Unquoted backslash

- Any character following an unquoted backslash is read literally
  (the backslash itself is consumed, not kept).

=== Executing quoted executables

- The command name may itself be single- or double-quoted;
  quote-removal applies to it the same as to any other word before
  it's used as a program name.

#line(length: 100%)

== Parser: redirection

*Layer: parser (`io_redirect`/`io_file` productions). Only the
output-side subset below is required — no `<`, `<<`, `<<-`, `<&`,
`>&`, `<>`, or `>|` needed for this course.*

- `{command} > {file}` or `{command} 1> {file}`: redirect stdout to a
  file (truncate).
- `{command} 2> {file}`: redirect stderr to a file (truncate).
- `{command} >> {file}` or `{command} 1>> {file}`: append stdout to a
  file.
- `{command} 2>> {file}`: append stderr to a file.

#line(length: 100%)

== Parser: pipelines

*Layer: parser (`pipe_sequence`), plus executor work to wire real
pipes and handle builtins mid-pipeline.*

- A pipeline is a sequence of commands separated by `|`.
- Each command's stdout feeds the next command's stdin.
- The pipeline's exit status is the exit status of its last command.
  #strong[Correction:] the original draft's "the output of the last
  command is the return value of the pipeline" conflates *stdout
  content* (already covered by the previous point) with *exit status*
  (a separate, and separately testable, thing) — keep these two
  distinct in your implementation.
- A builtin inside a pipeline still needs its stdin/stdout wired to
  the pipe — for a builtin this means redirecting the shell process's
  own file descriptors around the call and restoring them after,
  rather than forking.

#line(length: 100%)

== Expansion: parameter expansion

*Layer: expansion pass (runs on parsed `WORD` nodes, after tokenizing
and parsing, right before execution — see the tokenizer+parser+
expansion spec for how this pass fits in).*

=== The `declare` builtin

- Form: `declare {name}={value}` or `declare -p {name}`.
- `declare {name}={value}`: if `{name}` is a valid identifier
  (name-shaped), set the shell variable `{name}` to `{value}`.
- `declare -p {name}`: print `{name}`'s value if it's set.
  #strong[Verify:] confirm the exact expected output format for both
  the set and unset cases — the original draft doesn't specify one,
  and there's a dedicated test stage specifically for the *missing*-
  variable case (`declare -p` on an unset name), which needs its own
  explicit behavior, not just "if it exists."

=== Expansion rules

- Outside single quotes, `$name` and `${name}` expand to the current
  value of `name`.
- An unset variable expands to an empty string.
  #strong[Verify:] the original draft additionally says the resulting
  empty word is "dropped" (i.e. `echo $UNSET` produces *zero*
  arguments, not one empty-string argument) — this is correct real-
  shell behavior via field splitting, but it's a narrow special case
  worth confirming against an actual test run rather than assuming;
  if the checker instead expects the word to survive as an empty
  argument, you don't need general field splitting to get this case
  right either way, just this one specific rule.

#line(length: 100%)

== Process management: background jobs

*Layer: executor. Parser-side, this only needs the trailing `&`
handled as an async marker on `separator_op`; everything else here is
process-table bookkeeping.*

=== Starting and observing background jobs

+ When the last token of a command is `&`, run it in the background
  and print its job number and PID.
+ A background job's stdout and stderr print directly to the
  terminal.

=== The `jobs` builtin

+ Prints one line per job, format: `[{job number}]{marker}  {status} {command}`.
+ `{marker}` is `+` for the most-recently-started job, `-` for the
  second-most-recent, and a space for all others.
+ `{status}` is `Running` while the job is active.
+ When a job exits, `{status}` becomes `Done` and the job must be
  reaped (before the next prompt is shown).
+ A reaped job's number is free to be reused by a later job.

#line(length: 100%)

== Interactive: history

*Layer: interactive/readline — outside POSIX's shell grammar
entirely; no tokenizer/parser work involved.*

=== The `history` builtin

- `history {count}`: print a numbered list of the last `{count}`
  commands (default: all). Includes invalid commands; ignores empty
  lines.
- `history -r {file}`: read history from a file.
- `history -w {file}`: write history to a file (overwrite).
- `history -a {file}`: append new history entries to a file.
- #strong[Verify:] the original draft's note that "the previous 3
  commands include themself in the history" is unclear as written —
  confirm what's actually being asserted (most likely: that running
  `history -r`/`-w`/`-a` itself gets recorded as a history entry, same
  as any other command) before relying on it.

=== Interactive recall

- Up/down arrow keys navigate through history.
- Pressing enter on a recalled line executes it.

=== Persistence

- At startup, history is read from `$HISTFILE` if set.
- At exit, history is appended to `$HISTFILE` if set.
- `$HISTFILE` is created if it doesn't already exist.

#line(length: 100%)

== Interactive: command & file completion

*Layer: interactive/readline — no POSIX grounding, entirely
terminal/raw-mode + filesystem work.*

=== Command completion

- Tab after a partial command triggers completion.
- Candidates: shell builtins and executables found on `PATH`.
- One or more candidates share a longer common prefix than what's
  typed → complete to that prefix.
- Multiple candidates, no further common prefix → on each subsequent
  tab, print the full candidate list and reprint the partial command.
- No candidates → ring the bell (`0x07`).

=== File completion

- Tab after a partial (possibly empty) argument triggers file
  completion.
- The completion prefix is the text after the last space.
- Candidates: filesystem entries in the relevant directory.
- Exactly one candidate → print it, with a trailing `/` if it's a
  directory, or a trailing space otherwise.
- Multiple candidates → ring the bell on first tab; on subsequent
  tabs, print the candidate list and reprint the partial command.
- No candidates → ring the bell.

#line(length: 100%)

== Interactive: programmable completion

*Layer: interactive/readline, plus a subprocess-invocation executor
piece (the `-C` completer program).*

- The `complete` builtin registers custom completion behavior.
- `complete -C {path} {command}`: registers `{path}` as the completer
  program for `{command}`.
- The completer program prints its completion candidates to stdout.
- `complete -p {command}`:
  - If `{command}` has a registered completer, print
    `complete -C {path} {command}`.
  - Else, print `complete: {command}: no completion specification`.
- `complete -r {command}`: unregister `{command}`'s completer.
- The completer process reads `COMP_LINE` and `COMP_POINT` from its
  environment to determine the current command line and cursor
  position.
- Zero or multiple candidates from a `-C` completer are handled the
  same way as command/file completion above (bell on none; common-
  prefix-then-list on multiple).
