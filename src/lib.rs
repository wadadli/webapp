#![feature(rust_2018_preview)]
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
impl Default for Timestamp {
    fn default() -> Self {
        Self::new()
    }
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
                }).collect()
        }).unwrap();

    records
}

pub fn check_table(pool: &mysql::Pool) {
    let _stmt = pool
        .prep_exec(
            r"CREATE TABLE IF NOT EXISTS simple (
        id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
        timestamp TIMESTAMP (6) NOT NULL
        )",
            (),
        ).unwrap();
}
pub fn append_timestamp(pool: &mysql::Pool, timestamp: &Timestamp) {
    let _stmt = pool
        .prep_exec(
            r"INSERT INTO simple
        (timestamp)
        VALUES (:timestamp)",
            params!{"timestamp" => timestamp.value.naive_utc() },
        ).unwrap();
}
