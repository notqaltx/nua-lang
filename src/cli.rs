use clap::{Arg, Command};
use rlua::{Lua, Result};
use std::fs;

fn main() {
    let matches = Command::new("nua")
        .version("1.0").color(clap::ColorChoice::Auto)
        .subcommand(
            Command::new("run")
                .about("Runs a .nua file")
                .arg(Arg::new("file").help("The .nua file to run").required(true).index(1)),
        )
        .subcommand(
            Command::new("shell")
                .about("Runs a nua shell for testing purposes")
        )
        .subcommand(
            Command::new("test")
                .about("Runs a Lua file in the ./src/tests folder")
                .arg(Arg::new("file").help("The Lua file to run in ./src/tests/lua").required(true).index(1)),
        )
        .get_matches();

    if let Some(matches) = matches.subcommand_matches("run") {
        if let Some(file) = matches.get_one::<String>("file") {
            if let Err(e) = run_nua_file(file) {
                eprintln!("{}", e);
            }
        }
    } else if let Some(matches) = matches.subcommand_matches("test") {
        if let Some(file) = matches.get_one::<String>("file") {
            if let Err(e) = run_test_file(file) {
                eprintln!("{}", e);
            }
        }
    } else if matches.subcommand_matches("shell").is_some() {
        if let Err(e) = run_nua_shell() {
            eprintln!("{}", e); 
        }
    }
}
fn run_nua_file(file: &str) -> Result<()> {
    let lua = Lua::new();
    let code = fs::read_to_string("./src/lang/main.lua").expect("Could not read file");

    lua.context(|ctx| {
        ctx.globals().set("arg", vec![file])?;
        match ctx.load(&code).exec() {
            Ok(_) => (),
            Err(e) => println!("{}", e),
        }
        Ok(())
    })
}
fn run_nua_shell() -> Result<()> {
    let lua = Lua::new();
    let code = fs::read_to_string("./src/lang/main.lua").expect("Could not read file");

    lua.context(|ctx| {
        match ctx.load(&code).exec() {
            Ok(_) => (),
            Err(e) => println!("{}", e),
        }
        Ok(())
    })
}
fn run_test_file(file: &str) -> Result<()> {
    let lua = Lua::new();
    let test_file_path = format!("./src/tests/lua/{}", file);
    let code = fs::read_to_string(&test_file_path).expect("Could not read file");

    lua.context(|ctx| {
        ctx.globals().set("arg", vec![file])?;
        match ctx.load(&code).exec() {
            Ok(_) => (),
            Err(e) => println!("{}", e),
        }
        Ok(())
    })
}