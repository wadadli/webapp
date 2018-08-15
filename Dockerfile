FROM scratch

ADD target/x86_64-unknown-linux-musl/release/webapp /

EXPOSE 8000

ENTRYPOINT ["/webapp"]
