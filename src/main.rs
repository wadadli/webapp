#![feature(rust_2018_preview)]
use clap::{App, Arg};
use iron::prelude::*;
use iron::status;
use webapp::Timestamp;

const SERVER_ADDRESS: &str = "localhost:8000";

fn main() {
    let cli = App::new("dummy-webapp")
        .version("v1.0-beta")
        .about("connects to mysql and severes a table")
        .author("Michael Singh")
        .arg(
            Arg::with_name("user")
                .short("u")
                .long("user")
                .value_name("USER")
                .help("Sets a username for a mysql connection")
                .takes_value(true)
                .required(true),
        ).arg(
            Arg::with_name("password")
                .short("p")
                .long("password")
                .value_name("PASSWORD")
                .help("Sets a password for the USER for a mysql connection")
                .takes_value(true)
                .required(true),
        ).arg(
            Arg::with_name("hostname")
                .short("h")
                .long("hostname")
                .value_name("HOSTNAME")
                .help("Sets hostname to connect to")
                .takes_value(true)
                .required(true),
        ).arg(
            Arg::with_name("table")
                .short("t")
                .long("table")
                .value_name("TABLE")
                .help("Sets the table for to operate on")
                .takes_value(true)
                .required(true),
        ).arg(
            Arg::with_name("port")
                .short("P")
                .long("port")
                .value_name("PORT")
                .help("Sets the port to connect to on the host")
                .takes_value(true)
                .required(true),
        ).get_matches();
    let username = cli.value_of("user").unwrap();
    let password = cli.value_of("password").unwrap();
    let hostname = cli.value_of("hostname").unwrap();
    let port = cli.value_of("port").unwrap();
    let table = cli.value_of("table").unwrap();

    let uri = format!(
        "mysql://{}:{}@{}:{}/{}",
        username, password, hostname, port, table
    );

    let timestamp = Timestamp::new();
    let pool = mysql::Pool::new(uri).unwrap();

    webapp::check_table(&pool);
    webapp::append_timestamp(&pool, &timestamp);

    let hello_world = move |_: &mut Request<'_, '_>| -> IronResult<Response> {
        let timestamps = pool.prep_exec("SELECT * from simple", ());
        let timestamps = webapp::get_records(timestamps);

        Ok(Response::with((status::Ok, format!("{:#?}", timestamps))))
    };
    let _server = Iron::new(hello_world).http(SERVER_ADDRESS).unwrap();
    println!("Serving on http://{}", SERVER_ADDRESS);
}
