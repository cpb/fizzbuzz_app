# FizzBuzz App

A Rails app that runs a real-time FizzBuzz countdown in your browser.

## What it does

Enter a starting number and the app counts down to 1, streaming each result
live. Numbers divisible by 3 become Fizz, by 5 become Buzz, by both become
FizzBuzz — everything else shows the number itself.

Visit `/fizz_buzz/start` after starting the server.

## Prerequisites

- Ruby (see `.ruby-version`)
- [Bundler](https://bundler.io/)

## Setup

```sh
bin/setup
```

## Running the app

```sh
bin/dev          # starts the dev server
bin/rails test   # runs the test suite
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow, worktree
setup, and slash commands used to work on this project.
