#[allow(unused_imports)]
use std::io::{self, Write};

enum Command {
    Exit,
    Echo(String),
}

fn parse(input: &str) -> Option<Command> {
    if input == "exit" {
        Some(Command::Exit)
    } else {
        input
            .strip_prefix("echo")
            .map(|message| Command::Echo(message.into()))
    }
}

fn main() {
    loop {
        let mut cmd = String::new();
        print!("$ ");
        io::stdout().flush().unwrap();
        io::stdin().read_line(&mut cmd).unwrap();
        match parse(cmd.trim()) {
            Some(Command::Exit) => break,
            Some(Command::Echo(message)) => {
                println!("{message}");
            }
            None => {
                println!("{}: command not found", cmd.trim());
            }
        }
        io::stdout().flush().unwrap();
    }
}
