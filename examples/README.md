# Cake Demo Apps

## Available examples

- [`SELECT` and decode into Cats](./01_select_and_decode/README.md)
- [`UNION` and decode into Beings](./02_union_and_decode/README.md)
- [`INSERT`](./03_insert/README.md)
- [`DELETE`](./04_delete/README.md)
- [`UPDATE`](./05_update/README.md)
- [`INSERT ON CONFLICT UPDATE`](./06_insert_on_conflict_update/README.md)
- [`SELECT` and `JOIN`](./07_select_join/README.md)
- [fragment with prepared statement](./08_prepared_fragment/README.md)

The demo apps come with a docker `compose.yml` file which contains a
database setup. You will need to install or have installed _Git_,
_Erlang_, _Gleam_, and _Docker_ however, thus:

### Installing prerequisites

If not already installed, install:

1. Install [Git](https://github.com/git-guides/install-git).
2. Install _Erlang_, _Rebar3_, and _Gleam_, see
   [Installing](https://gleam.run/getting-started/installing/) chapter on
   the Gleam website for instructions.
3. Install [Docker Desktop](https://docs.docker.com/desktop/) or
   [Docker Engine](https://docs.docker.com/engine/install/).

### Obtaining a copy of Cake

Open a terminal of your choice to clone _Cake_:

```shell
git clone https://github.com/inoas/gleam-cake.git
cd gleam-cake
```

### Starting the docker compose setup for demo apps

Open a terminal of your choice and within the `gleam-cake` directory cloned
above:

```shell
cd examples/docker
bin/attached
```

### Start the demo app

Open a new terminal and run:

```shell
cd examples
cd 01_select_and_decode # ...or any other example app!
gleam clean
gleam run
```
