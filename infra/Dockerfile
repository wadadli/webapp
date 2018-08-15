FROM ekidd/rust-musl-builder
RUN rustup install nightly && \
    rustup default nightly && \
    rustup target add x86_64-unknown-linux-musl --toolchain=nightly
