# Step 1 - Build the Rust application
FROM rust:1.85-alpine AS builder-stage
ARG TARGETPLATFORM
WORKDIR /usr/src/app

# Install necessary dependencies
RUN apk add --no-cache \
    build-base \
    binutils


# Set up target - use natvie compilation for the target platform
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      rustup target add x86_64-unknown-linux-musl; \
      echo "x86_64-unknown-linux-musl" > /tmp/target; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      rustup target add aarch64-unknown-linux-musl; \
      echo "aarch64-unknown-linux-musl" > /tmp/target; \
    else \
      echo "Unsupported platform: $TARGETPLATFORM" && exit 1; \
    fi

# Copy manifest and caceh deps
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN TARGET=$(cat /tmp/target) && \
    cargo build --release --target $TARGET --locked && \
    rm -rf src

# Copy actual source code and build binary
COPY . .
RUN TARGET=$(cat /tmp/target) && \
    cargo build --release --target $TARGET --locked && \
    strip target/$TARGET/release/rifuki-actions-playground && \
    cp target/$TARGET/release/rifuki-actions-playground ./rifuki-actions-playground

# Final stage - copy the binary to a minimal image
FROM gcr.io/distroless/static:nonroot
WORKDIR /app
COPY --from=builder-stage /usr/src/app/rifuki-actions-playground ./rifuki-actions-playground
USER nonroot
EXPOSE 8080
ENTRYPOINT ["/app/rifuki-actions-playground"]
