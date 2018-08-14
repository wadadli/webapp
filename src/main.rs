#![feature(rust_2018_preview)]
use iron::prelude::*;
use iron::status;
use webapp::Timestamp;

const SERVER_ADDRESS: &str = "localhost:8000";

fn main() {
    let timestamp = Timestamp::new();
    let pool =
        mysql::Pool::new("mysql://root:kubernetesiseatingtheworld@localhost:3306/test").unwrap();

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
