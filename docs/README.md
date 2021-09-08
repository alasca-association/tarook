# Managed Kubernetes Handbook

This is an mdbook.

## Table of Contents

See [SUMMARY.md](src/SUMMARY.md).

## How to render

1. Install cargo and rustc from apt: `apt install cargo rustc`
2. Run `cargo install mdbook`
3. `~/.cargo/bin/mdbook serve -p 8000`
4. Open `http://127.0.0.1:8000` in your browser

Alternatively, you can render the book and open it without going through `mdbook serve`, but Browsers may be a tad picky about that: `~/.cargo/bin/mdbook build` and then open `book/index.html`.
