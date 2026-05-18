# .NET Testing

Applies to all C# projects. Plugin-specific WPF/STA constraints are
called out separately.

## Stack

- **Test framework**: `xUnit` (broader tooling, more idiomatic for new
  .NET 8+ projects). `NUnit` is acceptable when the host project already
  uses it (NINA core itself uses NUnit + FluentAssertions).
- **Mocking**: `Moq`. Host interfaces in well-designed plugins
  (mediators, accessors, options interfaces) mock cleanly.
- **Assertions**: `FluentAssertions`.
- **WPF/STA helpers**: `Xunit.StaFact` — provides `[WpfFact]` and
  `[StaFact]` attributes so a test runs on an STA thread with a `Dispatcher`.

## Test project layout

```
<repo>/
├── <Project>.csproj
└── tests/
    └── <Project>.Tests.csproj
```

Baseline test csproj:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <IsPackable>false</IsPackable>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.*" />
    <PackageReference Include="xunit" Version="2.*" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.*" />
    <PackageReference Include="Moq" Version="4.*" />
    <PackageReference Include="FluentAssertions" Version="6.*" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\<Project>.csproj" />
  </ItemGroup>
</Project>
```

## TFM choice for tests

Two viable patterns:

1. **Match the project under test.** When testing a `net8.0-windows`
   library, the test project also targets `net8.0-windows` (specifically
   `net8.0-windows10.0.22621.0` to pin a Windows SDK version when NUnit's
   `net8.0-windows`+`win-x64` combination is unstable). Pro: can
   reference the production assembly directly. Con: tests are
   Windows-bound.

2. **Pure `net8.0` tests over a refactored pure-.NET core.** Extract the
   host-independent logic into a separate `net8.0` class library; both
   the platform-targeted assembly and the `net8.0` test project
   reference it. Pro: tests run on Linux CI. Con: requires the
   refactor.

Prefer (2) when CI cost matters; (1) when the tested logic is
inseparable from the platform.

## Internal visibility

Test access to `internal` types:

```xml
<ItemGroup>
  <InternalsVisibleTo Include="<Project>.Tests" />
</ItemGroup>
```

Unsigned assemblies need only the name. Do not add `PublicKey` clauses
unless the production assembly is strong-named (it is not for typical
plugin scenarios).

## WPF / view-model tests

- `[ObservableProperty]`-generated setters are not `virtual` — Moq
  cannot proxy them on concrete classes. Test view-models by
  instantiating the real class, subscribing to `PropertyChanged`, and
  asserting on the event payload. INPC fires synchronously without a
  `Dispatcher`.
- For anything that touches `Application.Current.Dispatcher`, mark the
  test `[WpfFact]` (from `Xunit.StaFact`). Plain `[Fact]` runs on the
  MTA thread pool and will throw on Dispatcher access.

## Test discipline

- Every new code path ships with at least one test. Existing tests
  validate prior behavior — new functionality is uncovered until a new
  test asserts it.
- Tests describe behavior, not implementation. The name reads as a
  sentence: `Server_BindsToCachedPort_WhenConfiguredPortIsTaken`.
- One logical assertion per test. FluentAssertions `.Should().Satisfy(...)`
  composes multiple checks into one logical assertion when needed.
- No test reads from or writes to disk under a hard-coded path. Use
  `Path.GetTempFileName()` / `Path.GetTempPath()` and clean up with
  `IDisposable` fixtures.
- No test depends on wall-clock time. Inject a clock abstraction or use
  `DateTime` parameters.

## Coverage and CI

- Coverage tool: `coverlet.collector` (xUnit) or `coverlet.msbuild`.
- Failing tests block merge. Coverage drop below the project's baseline
  blocks merge unless explicitly waived.
- CI runs `dotnet test --no-build --verbosity normal` on the test
  project after a single `dotnet build`.
