#set page(width: 800pt, height: auto, margin: 20pt)
#set text(font: "Liberation Sans", size: 20pt, fill: rgb("1f2328"))
#set heading(
  numbering: (..args) => {
    let nums = args.pos()
    if nums.len() > 1 {
      numbering("1.1.", ..nums.slice(1))
    }
  },
)
// #set page(numbering: "1")

= CodeCrafters build your own shell

#line(length: 100%)

== Stages

=== Print a prompt
=== Invalid commands

+ Display a prompt `$ `.
+ Read user input.
+ Print error messages `{command}: command not found`.

=== Implement a REPL

+ Display a prompt `$ `, then read a line of input.
+ Print error messages `{command}: command not found`.
+ Repeat.


=== The `exit` builtin

Terminates the shell.

=== The `echo` builtin

- Form: `echo {args...}`
- Print inputs to stdout, separated by spaces, and followed by a newline.

=== The `type` builtin

+ If the argument is a builtin, print `{command} is a shell builtin`.
+ Else, look for it in the `PATH` environment variable.
  + If found and executable, print `{command} is a <full path>` for the first match.
  + Else, print `{command}: not found`.

=== Run external programs

+ Read an input of the form `{program} {args...}`.
+ If `program` is an executable from the `PATH`, run it, forwarding all arguments.

#line(length: 100%)

== Navigation

=== The `pwd` builtin

Print the full absolute path to the current working directory.

=== The `cd` builtin

Takes the form: `cd {path}`:
+ If `path` is the symbol `~`, change to the user's home directory (from the `HOME` environment variable).
+ If `path` is an absolute or relative path, change to it, if it exists.
+ Else, print `cd {path}: no such file or directory`.

#line(length: 100%)


== Quoting

=== Single quotes

- Everything withing single quotes is literal
  (spaces are not collapsed, escapes are not handled, and special characters are treated as literals).
  In particular, backslashes are read literally.
- Two single-quoted strings juxtaposed without whitespace are concatenated.
- An empty single-quoted string is ignored.

=== Double quotes

- A backslash followed by `$, \, "` or `` \` `` forms an escape sequence.
- A `$` triggers expansion.
- Everything else is identical to single quotes.

=== Unquoted Backslash

- Any character following a backslash is read literally.


=== Executing quoted executables

- Executable names can be quoted with single or double quotes.

#line(length: 100%)

== Redirection

- `{command} > {file}` or `{command} 1> {file}`: redirect stdout to a file.
- `{command} 2> {file}`: redirect stderr to a file.
- `{command} >> {file}` or `{command} 1>> {file}`: append stdout to a file.
- `{command} 2>> {file}`: append stderr to a file.

#line(length: 100%)


== Command completion

- Hitting tab after a partial command triggers command completion.
- The candidates for completion are builtins and members of the `PATH` environment variable.
- If multiple candidates match the same prefix:
  - Print the maximal common prefix if it's not empty.
  - Else, print the list of candidates after each subsequent hit of tab, and reprint the partial command.
- If there are no candidates, ring the bell (0x07).

#line(length: 100%)

== File completion

- Hitting tab after a partial (potentially empty) argument triggers file completion.
- The prefix is the text after the last space.
- The candidates are files in the current directory (or the path specified).
- If a single candidate matches the prefix, print it, followed by a slash if it's a directory and a space otherwise.
- If multiple candidates match the prefix:
  - Ring the bell (0x07).
  - At each subsequent hit of tab, print the list of candidates.
  - Reprint the partial command.
- If there are no candidates, ring the bell.

#line(length: 100%)

== Pipelines

- A pipeline is a sequence of commands separated by `|`.
- The output of each command is the input of the next.
- The output of the last command is the return value of the pipeline.

#line(length: 100%)

== History

- `history` is a builtin.
- `history {count}`: print a numbered list of the last {count} commands
  (including invalid commands, but ignoring empty lines; default: full).
- The up and down arrow keys can be used to navigate the history.
- Hitting enter on a history line executes it.
- `history -r <file>` reads the history from a file.
- `history -w <file>` writes the history to a file.
- `history -a <file>` appends the history to a file.
- The previous 3 commands include themself in the history.
- At startup, the history is read from `$HISTFILE`.
- At exit, the history is appended to `$HISTFILE`, if set.
- The history file is created if it doesn't exist.

#line(length: 100%)

== Background jobs

+ When the last token of a command is `&`, the command is run in the background,
  the number of the job and pid is printed.
+ Background jobs `stdout` and `stderr` are printed to the terminal.
+ `jobs` is a builtin that prints information about jobs:
  + Each job is printed on a new line.
  + The format is: `[<job number>]<marker>  <status> <command>`.
  + `marker` is `+` for the last job, `-` for the penultimate job, and a space for all other jobs.
  + `status` is `Running` if the job is running.
  + When the job exits, `status` is `Done`, and the job must be reaped.
  + Numbers of reaped jobs are free to be reused for new jobs.

#line(length: 100%)

== Programmable completion
- The `complete` builtin can be used to implement programmable completion.
- `complete -C <path> <command>`: means `<command>` can be completed by the program `<path>`.
- `path` must contain a file that prints the completion to stdout.
- `complete -p <command>`:
  - If `command` has a completion function, print `complete -C <path> <command>`.
  - Else, print `complete: <command>: no completion specification`.
- `complete -r <command>`: remove the completion for `<command>`.
- The completer uses `COMP_LINE` and `COMP_POINT` environment variables to determine the current command line and cursor position.
- The case where 0 or multiple completions are provided are handled analogously to progarm and file completion.

== Parameter expansion

- `declare` is a builtin.
- Form: `declare <name>=<value>` or, `declare -p <name>`.
- `declare <name>=<value>`: if `<name>` is a valid identifier, set `<name>` to `<value>`.
- `declare -p <name>`: print the value of `<name>` if it exists.
- Outside of quotes, `$<name>` expands to the value of `<name>`, same for `${name}`.
- Undefined variables expand to an empty string, and are dropped.



