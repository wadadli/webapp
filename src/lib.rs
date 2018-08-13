#[macro_use]
extern crate mysql;
extern crate chrono;

use chrono::prelude::*;

struct Config {
    user: String,
    hostname: String,
    database: String,
    port: u16,
    pool: mysql::Pool,
}

#[derive(Debug)]
pub struct Timestamp {
    pub id: Option<u32>,
    pub value: DateTime<Utc>,
}

impl Timestamp {
    pub fn new() -> Self {
        Self {
            id: None,
            value: Utc::now(),
        }
    }
}

pub fn get_records(records: Result<mysql::QueryResult, mysql::Error>) -> Vec<Timestamp> {
    let records: Vec<Timestamp> = records
        .map(|record| {
            record
                .map(|x| x.unwrap())
                .map(|row| {
                    let (id, value) = mysql::from_row(row);
                    let value = DateTime::from_utc(value, Utc);
                    Timestamp { id, value }
                })
                .collect()
        })
        .unwrap();

    records
}

/*
 *pub fn append_timestamp(connection: mysql::Conn, timestamp: Timestamp) -> Result<(), &'static str> {
 *    connection.prep_exec(
 *        r"INSERT INTO simple
 *        (timestamp)
 *        VALUES (:timestamp)",
 *        params!{"timestamp" => timestamp.value.naive_utc()},
 *    )
 *}
 */
