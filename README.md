EctoSubscribe
=============

`ecto_subscribe` allows to subscribe on change a model.

Usage
==============

You can define your `ecto` model and use `subscribe` macro:

```elixir
import Ecto.Subscribe.Api

defmodule MyModel do
  use Ecto.Model

  subscribe(repo: MyRepo)
  schema "user" do
    field :name,    :string
    field :old, :integer
  end
end
```

After this tell to the `ecto_subscribe` about your `repo` and subcribe on event with:

```elixir
Ecto.Subscribe.init(MyRepo)
Ecto.Subscribe.Api.subscribe(MyRepo, MyModel, "old > 20", [adapter: Ecto.Subscribe.Adapter.Log actions: [:create]])
```

When any event will occur, `ecto_subscribe` will write to log this.

`ecto_subcribe` supports following adapters:

* Ecto.Subscribe.Adapter.Log - writes ecto `changeset` to the log;
* Ecto.Subscribe.Adapter.Remote - sends ecto `changeset` via rpc to the given node.

`ecto_subscribe` supports following actions:

* create - occurs after inserting of new data which matched with condition of subscription;
* delete - occurs after deleting of data which matched with condition of subscription;
* update - occurs after updating of data which matched with condition of subscription.

If `actions` option not given, subscription will be created for all three events.

Testing
==============

For running unut tests execute:

```
MIX_ENV=pg mix test
```

or

```
MIX_ENV=mysql mix test
```
