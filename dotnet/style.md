# .NET Coding Style

Applies to all C# projects targeting .NET 8 or newer.

## Async patterns

- `async Task` for ordinary async methods. Do not return `void` from async
  methods except for delegate-compatible event handlers.
- `async void` only for top-level handlers subscribed to
  `EventHandler` / `EventHandler<T>`. **Always** wrap the body in
  `try / catch` and log the exception — unhandled exceptions from
  `async void` propagate to the UI `SynchronizationContext` and can crash
  the host process.
- Handlers subscribed to `Func<..., Task>` events must return `Task` (the
  publisher awaits the returned task; returning `void` silently drops the
  await).
- `CancellationToken` as the last parameter (or second-to-last when
  `IProgress<T>` follows). Propagate through every call, including
  `Task.Run(action, ct)`.
- Never block on async with `.Result` / `.Wait()` on a UI or
  request-handling thread. Acceptable only on a dedicated background
  `Thread` whose explicit job is to host the async loop.

## UI marshalling (WPF)

Background-thread code that touches UI-bound properties marshals via:

```csharp
await Application.Current.Dispatcher.InvokeAsync(() => SomeProperty = newValue);
```

Use `Dispatcher.InvokeAsync` (TAP-integrated). Do not use
`Dispatcher.BeginInvoke` (legacy, no async integration).

## Nullable reference types

- `<Nullable>enable</Nullable>` at the project level.
- `#nullable disable` per-file is acceptable for XAML code-behind and
  `IValueConverter` files where WPF generated/runtime patterns produce
  excessive noise. Document the disable with a one-line comment.

## .NET language features

| Feature | Use |
|---|---|
| File-scoped namespaces (C# 10) | Yes — `namespace Foo.Bar;` |
| Primary constructors (C# 12) | Acceptable, but prefer explicit constructor when the type uses attributes on the constructor (e.g., MEF `[ImportingConstructor]`). |
| `record` types | Immutable DTOs only. **Not** for mutable view-model properties (no `INotifyPropertyChanged` integration). |
| `record struct` | Hot-path value objects only. |
| `using` declarations | Prefer for single-disposable scopes. |
| Top-level statements | Only for console-style entry points. Class libraries are unaffected. |

## MVVM

Preferred base class for view-models is `CommunityToolkit.Mvvm.ComponentModel.ObservableObject`
with `[ObservableProperty]` source-generated properties. Class must be
declared `partial`.

```csharp
public partial class MyViewModel : ObservableObject {
    [ObservableProperty]
    private string title;
}
```

- `RelayCommand` and `AsyncRelayCommand` come from
  `CommunityToolkit.Mvvm.Input`.
- `[ObservableProperty]`-generated properties are not `virtual` and
  therefore not Moq-proxyable on concrete classes — for tests, instantiate
  the real view-model and observe `PropertyChanged`. INPC events fire
  synchronously without a `Dispatcher`.

When `ObservableObject` is unavailable or the host framework supplies its
own INPC base class, implement `INotifyPropertyChanged` manually with
`[CallerMemberName]`:

```csharp
public event PropertyChangedEventHandler PropertyChanged;
protected void RaisePropertyChanged([CallerMemberName] string name = null)
    => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
```

## Exceptions

- Log every caught exception via the project logger before swallowing or
  rethrowing. Never `catch (Exception) { }`.
- Prefer `catch (SpecificException)` over `catch (Exception)`. Use
  `Exception` only at the outermost handler of an async-void or
  fire-and-forget boundary.
- Use the exception-taking overload of the logger (`Logger.Error(ex, "context")`)
  so the stack trace is preserved.

## Logging

- Go through a single project logger abstraction. Do not introduce a
  parallel logging framework alongside the host's.
- Levels: `Trace` (high-frequency, off by default), `Debug` (state useful
  during repro), `Info` (lifecycle events), `Warning` (recoverable
  anomaly), `Error` (operation failed; always include the exception).
- Gate expensive trace payload construction with `IsEnabled`:

```csharp
if (Logger.IsEnabled(LogLevelEnum.Trace)) {
    Logger.Trace($"State dump: {ExpensiveDump()}");
}
```

- Do not log credentials, API keys, tokens, or PII. Log files persist
  beyond the immediate session and are shared during support.
