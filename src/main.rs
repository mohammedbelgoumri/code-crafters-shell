#[allow(unused_imports)]
use std::io::{self, Write};

fn main() {
    let mut cmd = String::new();
    loop {
        print!("$ ");
        io::stdout().flush().unwrap();
        io::stdin().read_line(&mut cmd).unwrap();
        println!("{}: command not found", cmd.trim());
        io::stdout().flush().unwrap();
    }
}
