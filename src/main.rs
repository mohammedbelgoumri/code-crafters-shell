#[allow(unused_imports)]
use std::io::{self, Write};
use std::str::FromStr;
#[derive(Debug)]
enum Command {
    Exit,
    Echo(String),
    Type(Box<Command>),
}

enum ParseCommandError {
    Error(String),
}

impl FromStr for Command {
    type Err = ParseCommandError;
    fn from_str(input: &str) -> Result<Self, Self::Err> {
        if input == "exit" {
            Ok(Command::Exit)
        } else if let Some(messgae) = input.strip_prefix("echo ") {
            Ok(Command::Echo(messgae.into()))
        } else if let Some(cmd) = input.strip_prefix("type") {
            let cmd: Command = cmd.parse()?;
            Ok(Command::Type(Box::new(cmd)))
        } else {
            Err(ParseCommandError::Error(format!("{input}: not found")))
        }
    }
}

fn parse(input: &str) -> Option<Command> {
    if input == "exit" {
        Some(Command::Exit)
    } else {
        input
            .strip_prefix("echo ")
            .map(|message| Command::Echo(message.into()))
    }
}

fn main() {
    loop {
        let mut cmd = String::new();
        print!("$ ");
        io::stdout().flush().unwrap();
        io::stdin().read_line(&mut cmd).unwrap();
        match cmd.parse() {
            Ok(Command::Exit) => break,
            Ok(Command::Echo(message)) => {
                println!("{message}");
            }
            Ok(Command::Type(cmd)) => {
                println!("{:?} is a shell builtin", cmd)
            }
            Err(ParseCommandError::Error(_)) => {
                println!("{}: command not found", cmd.trim());
            }
        }
        io::stdout().flush().unwrap();
    }
}
