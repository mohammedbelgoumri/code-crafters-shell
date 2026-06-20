#[allow(unused_imports)]
use std::io::{self, Write};

fn main() {
    loop {
        let mut cmd = String::new();
        print!("$ ");
        io::stdout().flush().unwrap();
        io::stdin().read_line(&mut cmd).unwrap();
        cmd = cmd.trim().into();
        if cmd == "exit" {
            break;
        } else {
            println!("{}: command not found", cmd);
            io::stdout().flush().unwrap();
        }
    }
}
