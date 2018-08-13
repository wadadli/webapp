#[macro_use]
extern crate mysql;
extern crate iron;
extern crate webapp;

use iron::prelude::*;
use iron::status;
use webapp::Timestamp;

const SERVER_ADDRESS: &'static str = "localhost:8000";

fn main() {
    let timestamp = Timestamp::new();
    let pool =
        mysql::Pool::new("mysql://root:kubernetesiseatingtheworld@localhost:3306/test").unwrap();

    pool.prep_exec(
        r"CREATE TABLE IF NOT EXISTS simple (
        id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
        timestamp TIMESTAMP (6) NOT NULL
        )",
        (),
    ).unwrap();

    pool.prep_exec(
        r"INSERT INTO simple
        (timestamp)
        VALUES (:timestamp)",
        params!{"timestamp" => timestamp.value.naive_utc() },
    ).unwrap();

    fn hello_world(_: &mut Request) -> IronResult<Response> {
        let pool = mysql::Pool::new("mysql://root:kubernetesiseatingtheworld@localhost:3306/test")
            .unwrap();

        let timestamps = pool.prep_exec("SELECT * from simple", ());
        let timestamps = webapp::get_records(timestamps);

        Ok(Response::with((status::Ok, format!("{:#?}", timestamps))))
    }
    let _server = Iron::new(hello_world).http(SERVER_ADDRESS).unwrap();
    println!("Serving on http://{}", SERVER_ADDRESS);
}
