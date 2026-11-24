# NINA 3.x Plugin Standards

Conventions for building, packaging, and publishing a C# NINA 3.x
(Nighttime Imaging 'N' Astronomy) plugin targeting the public
`NINA.Plugin` NuGet on .NET 8 Windows.

Derived from citation-backed research; this document is the standard
itself. Authoritative primary sources for every claim below: the
[NINA source](https://github.com/isbeorn/nina), the
[plugin template](https://github.com/isbeorn/nina.plugin.template), the
[`NINA.Plugin` NuGet package](https://www.nuget.org/packages/NINA.Plugin),
and the
[plugin manifest repository](https://github.com/isbeorn/nina.plugin.manifests)
(formerly `bitbucket.org/Isbeorn/nina.plugin.manifests`, now archived and
moved to GitHub).

For host-independent .NET conventions, see [style.md](style.md),
[project-structure.md](project-structure.md), and [testing.md](testing.md).

## Quick-reference

| Aspect | Standard |
|---|---|
| TFM | `net8.0-windows` for the NINA 3.2 line; `net10.0-windows` for 3.3 (see §1a). Bump only when `NINA.Plugin` does. |
| Platform | x64 |
| `UseWPF` | `true` when the plugin includes XAML |
| NuGet | `NINA.Plugin <matching-version>` only; rely on transitive deps |
| `MinimumApplicationVersion` | Matches the `NINA.Plugin` NuGet version |
| Install root | `%LOCALAPPDATA%\NINA\Plugins\<api-version>\<title>\` |
| `<api-version>` segment | **3-part**, currently `3.0.0` for all NINA 3.x |
| Plugin class | `[Export(typeof(IPluginManifest))] : PluginBase` |
| Constructor | `[ImportingConstructor]` exactly once per class |
| Persisted options | `new PluginOptionsAccessor(profileService, Guid.Parse(this.Identifier))` |
| Options UI key | `<AssemblyTitle>_Options` |
| ResourceDictionary code-behind | `[Export(typeof(ResourceDictionary))] partial class : ResourceDictionary` |
| RelayCommand | `CommunityToolkit.Mvvm.Input.RelayCommand` (NINA's own is `[Obsolete]`) |
| Logger backend | Serilog (NOT log4net); static `NINA.Core.Utility.Logger` |
| Embedded HTTP | `EmbedIO 3.5.2` with `HttpListenerMode.EmbedIO` |
| Cleanup | Override `Task Teardown()`; unsubscribe / unregister; `base.Teardown()` last |
| Publishing | PR to `github.com/isbeorn/nina.plugin.manifests`; `manifest.json` per schema |
| Hash | SHA-256 over the installer file; recomputed if DLL changes |

## 1. Project layout and csproj

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0-windows</TargetFramework>
    <Platforms>x64</Platforms>
    <PlatformTarget>x64</PlatformTarget>
    <OutputType>Library</OutputType>
    <UseWPF>true</UseWPF>
    <CopyLocalLockFileAssemblies>true</CopyLocalLockFileAssemblies>
    <GenerateAssemblyInfo>false</GenerateAssemblyInfo>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <WarningsNotAsErrors>NU1701</WarningsNotAsErrors>
    <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
    <LangVersion>latest</LangVersion>
  </PropertyGroup>

  <ItemGroup>
    <!-- NINA.Plugin version matches the target NINA stable.
         3.2.0.9001 for NINA 3.2 stable. -->
    <PackageReference Include="NINA.Plugin" Version="3.2.0.9001" />
    <!-- third-party PackageReferences here, exact versions -->
  </ItemGroup>
</Project>
```

Rules:

- `net8.0-windows` matches the running NINA 3.2 host. NINA 3.3+ may bump
  to `net10.0-windows`; track whatever `NINA.Plugin` ships.
- Reference `NINA.Plugin` only and rely on transitive resolution. Do not
  pull `NINA.Core`, `NINA.Equipment`, etc. as direct package references
  unless a specific reason applies.
- Pin `NINA.Plugin` to the exact version (no `3.2.*`); it must equal
  `MinimumApplicationVersion` (§10.4). Commit the lock file and restore
  with `--locked-mode` in CI.
- `GenerateAssemblyInfo=false` is required when `Properties/AssemblyInfo.cs`
  is used (§3); otherwise the SDK emits duplicate attributes (CS0579).
- `NINA.Plugin` pulls net4x packages: keep `TreatWarningsAsErrors` but
  exempt `NU1701`.
- Do not rely on `PrivateAssets=all` to keep NINA's DLLs out of `bin`: the
  reference exporter still sees ~84 DLLs there, 71 already in NINA. Use the
  ship list (§2).
- **Deploy by script or make target, not a post-build step.** A running
  NINA locks the deployed DLL and would fail every build. Deploy with NINA
  closed (`make install`; `install-dev-nina`: kill, install, relaunch).
  Install path: `%LOCALAPPDATA%\NINA\Plugins\3.0.0\<AssemblyTitle>\`.
- The install path's `<api-version>` is the **3-segment** `3.0.0`, not
  the 4-segment `3.0.0.9001` package version. All NINA 3.x plugins
  install under `\NINA\Plugins\3.0.0\` regardless of the running NINA
  build.
- The plugin template's checked-in csproj still targets .NET Framework
  4.8 for historical reasons — ignore it. The VS wizard generates a
  `net8.0-windows` project.
- **Build output path depends on whether you build the sln or the
  csproj.** With `<Platforms>x64</Platforms>` set, `dotnet build -c
  Release` against the `.sln` resolves the `Release|x64` solution
  configuration and emits to `bin\x64\Release\`. Building the `.csproj`
  directly (no sln in cwd) emits to `bin\Release\`. Local builds and CI
  typically diverge on this — pin scripts (install, package, ship-list
  selection) to `bin\x64\Release` and always drive builds through the
  sln so CI and local agree.

### 1a. Which NINA line

TFM, `NINA.Plugin` package version and `MinimumApplicationVersion` move together. The
default branch targets the latest **stable** line (`net8.0-windows`, `NINA.Plugin
3.2.0.9001`). A 3.3 build (`net10.0-windows`, `NINA.Plugin 3.3.x-nightly`, min version
equal to the package) lives on a separate long-lived branch and ships its own manifest in
the 3.3 bucket. Do not compile against a `-beta`/`-nightly` package for a stable release.
The official template (`dotnet new`, .NET 10, NINA 3.3) is a useful reference for layout,
`Plugin.props` identity and `docs/`, but this standard applies to both lines.

## 2. Do not bundle host-shipped assemblies

NINA isolates plugins via `AssemblyLoadContext`, but the plugin still
resolves shared types through its own context first. Bundling an
assembly NINA already ships causes either a second copy (breaking
cross-context type identity) or a version mismatch surfacing as
`TypeLoadException` / `MissingMethodException`.

Do not copy any of these into the plugin folder:

```text
NINA.Astrometry, NINA.Core, NINA.Equipment, NINA.Image,
NINA.PlateSolving, NINA.Profile, NINA.Sequencer, NINA.WPF.Base,
NINA.CustomControlLibrary,
CommunityToolkit.Mvvm, Newtonsoft.Json,
Serilog, Serilog.Sinks.File, Serilog.Sinks.Console,
System.ComponentModel.Composition, OxyPlot.Core,
SQLite (SourceGear.sqlite3 / System.Data.SQLite),
gRPC, Google.Protobuf, Accord.Math
```

Ship only what the plugin owns, through one **ship list** (a single file
shared by the install script and the release packager): name each plugin-owned
and third-party DLL, fail when a listed DLL is missing, and warn about any DLL
in the output that is neither listed nor present in the NINA install
directory. Do not ship `.pdb` files unless needed.

**NINA does not ship log4net.** Logging is Serilog under the hood.
Anything online that mentions log4net for NINA is out of date.

## 3. AssemblyInfo.cs — the manifest source of truth

`PluginBase` reads `IPluginManifest` data from assembly attributes:

| Status | Attribute | Maps to |
|---|---|---|
| **Required** | `[Guid("...")]` | `Identifier` |
| **Required** | `[AssemblyTitle("...")]` | `Name` (drives DataTemplate key, install folder, manifest Name) |
| **Required** | `[AssemblyVersion("M.m.p.b")]` | (CLR identity) |
| **Required** | `[AssemblyFileVersion("M.m.p.b")]` | `Version` |
| **Required** | `[AssemblyDescription("...")]` | `Descriptions.ShortDescription` |
| Recommended | `[AssemblyCompany("...")]` | `Author` |
| Recommended | `[AssemblyMetadata("License", "...")]` | `License` |
| Recommended | `[AssemblyMetadata("LicenseURL", "...")]` | `LicenseURL` |
| Recommended | `[AssemblyMetadata("Repository", "...")]` | `Repository` |
| Recommended | `[AssemblyMetadata("MinimumApplicationVersion", "3.2.0.9001")]` | `MinimumApplicationVersion` |
| Optional | `[AssemblyMetadata("Homepage", "...")]` | `Homepage` |
| Optional | `[AssemblyMetadata("ChangelogURL", "...")]` | `ChangelogURL` |
| Optional | `[AssemblyMetadata("Tags", "a, b, c")]` | `Tags` (string array; comma-separated) |
| Optional | `[AssemblyMetadata("LongDescription", "...")]` | `Descriptions.LongDescription` |
| Optional | `[AssemblyMetadata("FeaturedImageURL", "...")]` | `Descriptions.FeaturedImageURL` |
| Optional | `[AssemblyMetadata("ScreenshotURL", "...")]` | `Descriptions.ScreenshotURL` |
| Optional | `[AssemblyMetadata("AltScreenshotURL", "...")]` | `Descriptions.AltScreenshotURL` |

Notes:

- The plugin manifest README documents a `[AssemblyMetadata("ShortDescription", ...)]`
  framing, but `PluginBase` actually reads the standard
  `[AssemblyDescription(...)]` attribute. Set both consistently: a
  substantive `[AssemblyTitle]` and a clean `[AssemblyDescription]` that
  match.
- `AssemblyVersion` segments are 16-bit unsigned (`0`–`65535`). Always
  emit 4 segments.
- Defaults when missing: `Version` → `1.0.0.0`,
  `MinimumApplicationVersion` → `1.11.0.0`. Both are accepted by
  `PluginLoader` but rejected by manifest-repo validation. Treat
  unspecified versions as a hard error.
- Missing `[Guid]`: `PluginOptionsAccessor.GetAssemblyGuid` returns
  `null`, options cannot persist, and identity tracking breaks. Set the
  GUID once and never change it.

A canonical template is in [Appendix A](#appendix-a-canonical-assemblyinfo).

## 4. The main plugin class — MEF wiring

```csharp
[Export(typeof(IPluginManifest))]
public class MyPlugin : PluginBase, INotifyPropertyChanged {
    private readonly IProfileService profileService;
    private readonly IImageSaveMediator imageSaveMediator;
    private readonly IPluginOptionsAccessor pluginSettings;

    [ImportingConstructor]
    public MyPlugin(IProfileService profileService,
                    IImageSaveMediator imageSaveMediator) {
        this.profileService = profileService;
        this.imageSaveMediator = imageSaveMediator;
        this.pluginSettings = new PluginOptionsAccessor(
            profileService, Guid.Parse(this.Identifier));

        profileService.ProfileChanged += OnProfileChanged;
        imageSaveMediator.BeforeImageSaved += OnBeforeImageSaved;
    }

    public override async Task Teardown() {
        profileService.ProfileChanged -= OnProfileChanged;
        imageSaveMediator.BeforeImageSaved -= OnBeforeImageSaved;
        await base.Teardown();
    }

    private void OnProfileChanged(object sender, EventArgs e) {
        RaisePropertyChanged(nameof(SomeProfileSpecificProperty));
    }

    private async Task OnBeforeImageSaved(object sender, BeforeImageSavedEventArgs e) {
        // mutate FITS headers here
    }

    public event PropertyChangedEventHandler PropertyChanged;
    protected void RaisePropertyChanged([CallerMemberName] string name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}
```

Rules:

- Exactly **one** `[Export(typeof(IPluginManifest))]` per plugin
  assembly.
- Exactly **one** `[ImportingConstructor]` per class. The default MEF
  `CreationPolicy` is `Shared` (singleton per container) and the plugin
  manager relies on this — do not declare `[PartCreationPolicy(NonShared)]`
  on the manifest class.
- Inject only what the plugin needs.
- Do not access `ISequenceMediator` in the constructor body — it is not
  initialized until after all plugins are loaded. Defer to
  `Initialize()`.
- `PluginBase` provides virtual async `Initialize()` and `Teardown()`
  returning `Task.CompletedTask`. Override one or both as needed.
- `PluginBase` does **not** extend `BaseINPC` and does **not** implement
  `IDisposable`. `Teardown()` is the only cleanup hook. Implement INPC
  on the plugin class directly (as above) or compose with a separate
  view-model.

## 5. Mediators and device consumers

Two interaction patterns.

### 5.1 Event subscription

For discrete actions:

| Mediator | Notable events |
|---|---|
| `IImagingMediator` | `ImagePrepared(ImagePreparedEventArgs)` — **NOT** `ImageSaved` |
| `IImageSaveMediator` | `BeforeImageSaved(Func<obj, BeforeImageSavedEventArgs, Task>)`, `BeforeFinalizeImageSaved(Func<obj, BeforeFinalizeImageSavedEventArgs, Task>)`, `ImageSaved(EventHandler<ImageSavedEventArgs>)` |
| `ITelescopeMediator` | `BeforeMeridianFlip`, `AfterMeridianFlip`, `Parked`, `Homed`, `Unparked`, `Slewed` |
| Other device mediators | Similar per-action event pattern |

- The `Func<..., Task>` events on `IImageSaveMediator` are **awaited** by
  the publisher. Implement these as `async Task` methods. Returning
  `async void` silently drops the await.
- The fire-and-forget `EventHandler<ImageSavedEventArgs>` (`ImageSaved`)
  is the case where `async void` is the only delegate-compatible option
  — wrap the entire body in `try / catch { Logger.Error(ex); }` because
  unhandled exceptions from `async void` propagate to the UI
  `SynchronizationContext` and can crash NINA.
- `BeforeFinalizeImageSaved` cannot mutate FITS headers — the changes
  are not reflected in the written file. Use `BeforeImageSaved` for that
  work.

### 5.2 Device-consumer registration

For streaming device-state polls:

```csharp
public class MyPlugin : PluginBase, ITelescopeConsumer {
    [ImportingConstructor]
    public MyPlugin(ITelescopeMediator telescopeMediator) {
        this.telescopeMediator = telescopeMediator;
        telescopeMediator.RegisterConsumer(this);
    }

    public void UpdateDeviceInfo(TelescopeInfo info) {
        // called on the hardware poll thread
    }

    public override Task Teardown() {
        telescopeMediator.RemoveConsumer(this);
        return base.Teardown();
    }
}
```

Note: the API verb is `RemoveConsumer`, not `Unregister`.

### 5.3 Thread semantics

Mediator events and `UpdateDeviceInfo` callbacks fire on background
threads in the general case. Plugin code that touches UI-bound
properties must marshal via `Dispatcher.InvokeAsync` — see
[style.md § UI marshalling](style.md#ui-marshalling-wpf).

### 5.4 Cleanup discipline

- Every `+= handler` requires a paired `-= handler` in `Teardown()`.
- Every `RegisterConsumer(this)` requires a paired `RemoveConsumer(this)`.
- **Never** subscribe with an anonymous lambda — there is no
  equal-delegate-instance match for unsubscription. Always use a named
  method or store the delegate in a field.

## 6. Options UI (WPF)

### 6.1 The DataTemplate key

NINA renders the plugin's options panel by resolving:

```csharp
Application.Current.Resources[plugin.Name + "_Options"]
```

`plugin.Name` is `IPluginManifest.Name`, auto-populated from
`[AssemblyTitle]`. The constant `DataTemplatePostfix.Options` is
`"_Options"`.

With `[assembly: AssemblyTitle("MyPlugin")]` the DataTemplate must be
keyed `x:Key="MyPlugin_Options"`.

### 6.2 Wiring

`Options.xaml`:

```xml
<ResourceDictionary
    x:Class="MyPlugin.Options"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <DataTemplate x:Key="MyPlugin_Options">
        <StackPanel DataContext="{Binding}" Orientation="Vertical">
            <!-- bindings against plugin class properties -->
        </StackPanel>
    </DataTemplate>
</ResourceDictionary>
```

`Options.xaml.cs`:

```csharp
using System.ComponentModel.Composition;
using System.Windows;

namespace MyPlugin {
    [Export(typeof(ResourceDictionary))]
    partial class Options : ResourceDictionary {
        public Options() { InitializeComponent(); }
    }
}
```

`[Export(typeof(ResourceDictionary))]` is what tells `PluginLoader` to
merge the dictionary into `Application.Current.Resources.MergedDictionaries`.
Forgetting it produces an empty options pane.

DataContext inside the template is the `IPluginManifest` instance
itself (the `PluginBase` subclass).

### 6.3 Other DataTemplate postfixes

| Postfix | Key form | Purpose |
|---|---|---|
| `_Options` | `<IPluginManifest.Name>_Options` | Plugin global options panel |
| `_Mini` | `<FullyQualifiedTypeName>_Mini` | Compact sequencer item view |
| `_Dockable` | `<FullyQualifiedTypeName>_Dockable` | Dockable imaging-tab panel |
| `_<DeviceType>Settings` | `<FullyQualifiedTypeName>_CameraSettings`, etc. | Custom device-driver settings |

### 6.4 Themed styles

NINA's themed brushes and styles are merged into
`Application.Current.Resources` at app startup. Reference via
`{StaticResource ...}` without merging anything additional in the plugin
dictionary.

There is **no** `BorderedTextBlock` style — wrap a `TextBlock` (with the
`StandardTextBlock` style) in a `Border`.

### 6.5 RelayCommand

`NINA.Core.Utility.RelayCommand` is `[Obsolete]`. Use
`CommunityToolkit.Mvvm.Input.RelayCommand` / `AsyncRelayCommand`. NINA
ships `CommunityToolkit.Mvvm 8.4.0`, so:

```xml
<PackageReference Include="CommunityToolkit.Mvvm" Version="8.4.0">
  <ExcludeAssets>runtime</ExcludeAssets>
</PackageReference>
```

`ExcludeAssets=runtime` keeps compile-time references but suppresses
publishing the DLL (NINA already ships it).

## 7. Persisted options — IPluginOptionsAccessor

Construct in the plugin constructor:

```csharp
this.pluginSettings = new PluginOptionsAccessor(
    profileService, Guid.Parse(this.Identifier));
```

The GUID **must** match `[assembly: Guid(...)]`. Defensive form for the
case where the attribute is missing or duplicated:

```csharp
var guid = PluginOptionsAccessor.GetAssemblyGuid(typeof(MyOptions))
    ?? throw new Exception("GUID was not found in assembly metadata");
this.pluginSettings = new PluginOptionsAccessor(profileService, guid);
```

### 7.1 Typed accessors

Typed `GetValueT(name, default)` / `SetValueT(name, value)` pairs exist
for:

`Boolean, Byte, SByte, Char, Decimal, Double, Single, Int32, UInt32,
Int64, UInt64, Int16, UInt16, String, DateTime, Guid, Color, Enum<T>`

Naming follows CLS type names: `GetValueSingle`, not `GetValueFloat`.
Color is stored as an ARGB integer. Enums are stored as strings via
`Enum.GetName` and parsed back with `Enum.TryParse<T>` — **renaming an
enum member silently breaks deserialization** for existing profiles.
Treat enum-member renames as a versioned change requiring migration.

### 7.2 Profile scope

All settings are **per-profile**. Storage is
`profileService.ActiveProfile.PluginSettings`, an in-memory
`Dictionary<Guid, IDictionary<string, object>>` namespaced by plugin
GUID. Two plugins with the same setting name do not collide because
they have different GUIDs.

Profile files live at `%LOCALAPPDATA%\NINA\Profiles\<profile-guid>.profile`
and are serialized via `DataContractSerializer`. `Profile.Save()` uses a
journal → backup → final three-file write for crash safety.

### 7.3 Profile-change handling

Subscribe to `IProfileService.ProfileChanged` and re-raise PropertyChanged
notifications when the active profile switches; otherwise the UI shows
stale values from the previous profile:

```csharp
profileService.ProfileChanged += OnProfileChanged;   // named method, not a lambda

private void OnProfileChanged(object s, EventArgs e) {
    RaisePropertyChanged(nameof(MySetting));          // every persisted property
}
```

Put persisted settings in a separate `BaseINPC` options class, built with
`PluginOptionsAccessor.GetAssemblyGuid(typeof(MyPlugin)) ?? throw ...` (never
via a throwaway `new MyPlugin()`), with a `DetachFromProfileService()` the
plugin calls from `Teardown()`. Bind the options template through a property
(`{Binding Options.Port}`). Settings that disrupt a running service (port, bind
address) take effect only on an explicit **Apply** button.

Secrets (API tokens) in options are stored DPAPI-encrypted
(`ProtectedData`, `DataProtectionScope.CurrentUser`); profile files are plain text.

### 7.4 Convention: use `nameof()` for keys

```csharp
public bool EnableX {
    get => pluginSettings.GetValueBoolean(nameof(EnableX), defaultValue: true);
    set { pluginSettings.SetValueBoolean(nameof(EnableX), value); RaisePropertyChanged(); }
}
```

No magic strings. Refactor-safe.

## 8. Embedded HTTP servers

Plugins that expose HTTP endpoints (REST APIs, Prometheus metrics, local
UI servers) **must** use EmbedIO with `HttpListenerMode.EmbedIO` to
avoid the http.sys URL-ACL admin requirement.

```csharp
private CancellationTokenSource serverToken;
private Thread serverThread;

public void StartServer() {
    serverToken = new CancellationTokenSource();
    serverThread = new Thread(() => {
        using var server = new WebServer(o => o
            .WithUrlPrefix($"http://{BindAddress}:{Port}")   // default 127.0.0.1
            .WithMode(HttpListenerMode.EmbedIO));
        server.WithWebApi("/api", m => m.WithController<MyController>());
        server.RunAsync(serverToken.Token).Wait();
    }) { Name = "MyPlugin HTTP", IsBackground = true };
    serverThread.Start();
}

public void StopServer() => serverToken?.Cancel();
```

Why this pattern:

- `HttpListenerMode.EmbedIO` bypasses http.sys by binding raw managed
  TCP sockets. No admin, no `netsh urlacl`, no firewall warning at
  startup (only at first external connection).
- A dedicated named `Thread` gives the debugger a useful identifier.
  `IsBackground = true` lets it die at process exit.
- `serverToken.Cancel()` is registered on the listener and unblocks
  `.Wait()` cleanly.

NuGet: `EmbedIO 3.5.2`, targets `.NETStandard 2.0`, no version conflicts
with NINA's other dependencies.

Port selection: a fixed user-configurable port with fallback via
`CoreUtil.GetNearestAvailablePort(port)`. Expose `Port` (configured) and
`CachedPort` (actually bound) properties so the user can see which port
was used when the configured one was taken.

Bind to loopback (`127.0.0.1`) by default. Non-loopback binding (`*`) must (a) be off by
default and an explicit user setting, (b) require authentication for any endpoint that changes
device or plugin state (read-only metrics may be unauthenticated), (c) show a visible warning in
the options UI, and (d) be described in the README Security section (what is exposed, to whom,
how to firewall it). Never block `Initialize()` on bind
probing (run it with `Task.Run`) and surface server status as a string in the
options UI. `RunAsync(token)` as a held `Task` is equally acceptable to the
dedicated thread above.

Response encoding: write text responses with `new UTF8Encoding(encoderShouldEmitUTF8Identifier: false)`.
`Encoding.UTF8` emits a BOM, which shows up as garbage bytes and breaks strict
scrapers (jewzaam/nina-prometheus-exporter#14). Test the first bytes of each response.

Do **not** use `HttpListenerMode.Microsoft` — that path requires
elevation or `netsh http add urlacl` to bind any prefix other than
`http://localhost:port/`.

## 9. Logging

Backend is **Serilog**, not log4net. Use `NINA.Core.Utility.Logger` as a
static class.

```csharp
Logger.Info("Server started on port " + port);
Logger.Warning("Configured port unavailable; bound " + cachedPort);
try { ... } catch (Exception ex) { Logger.Error("Server failed to start", ex); }

if (Logger.IsEnabled(LogLevelEnum.Trace)) {
    Logger.Trace($"State dump: {ExpensiveDump()}");
}
```

- Methods: `Error`, `Warning`, `Info`, `Debug`, `Trace`,
  `SetLogLevel(LogLevelEnum)`, `IsEnabled(LogLevelEnum)`, `CloseAndFlush()`.
- `Error` overloads (NINA `release/3.2.x`): `(Exception)`, `(string customMsg, Exception)`,
  `(string)`. There is **no** `(Exception, string)`: `Error(ex, "msg")` compiles but
  binds the text to `memberName`. Always `Error("msg", ex)`; never `Error($"{ex.Message}")`
  (drops the stack). `Warning/Info/Debug/Trace` take only a string.
- `[CallerMemberName]`, `[CallerFilePath]`, `[CallerLineNumber]` optional
  params are auto-supplied — don't pass them.
- Log file:
  `%LOCALAPPDATA%\NINA\Logs\<timestamp>-<version>.<processId>-.log`,
  monthly rolling, 90-day retention, 1-second flush.
- Line format:
  `{Timestamp:yyyy-MM-ddTHH:mm:ss.ffff}|{LegacyLogLevel}|{Message:lj}{NewLine}{Exception}`

Level discipline:

| Level | Use |
|---|---|
| `Trace` | High-frequency hot-path; off by default; gate with `IsEnabled` |
| `Debug` | Internal state useful during bug reproduction |
| `Info` | Lifecycle events (server started, settings loaded) |
| `Warning` | Recoverable anomaly |
| `Error` | Operation failed; always include the exception |

NINA does **not** auto-prefix the plugin name. Heavy-logging plugins
maintain their own separate log file in
`%LOCALAPPDATA%\NINA\<PluginName>\Logs\` and use a per-plugin prefix.
This is a pattern, not a framework affordance.

Never log credentials, API keys, tokens, or PII. Log files persist 90
days and are shared during support.

## 10. Publishing

Manifest PR target: `https://github.com/isbeorn/nina.plugin.manifests`. The
former Bitbucket repo `bitbucket.org/Isbeorn/nina.plugin.manifests` is
archived; do not open PRs there. Schema authority is `manifest.schema.json`
at the GitHub repo root.

### 10.1 Schema (selected required fields)

```json
{
  "Name": "MyPlugin",
  "Identifier": "78fc6455-c1ba-4dc5-a8d0-9f48aecd733d",
  "Author": "Your Name",
  "License": "Apache-2.0",
  "LicenseURL": "https://www.apache.org/licenses/LICENSE-2.0",
  "Repository": "https://github.com/you/myplugin",
  "Version": { "Major": 1, "Minor": 0, "Patch": 0, "Build": 0 },
  "MinimumApplicationVersion": { "Major": 3, "Minor": 2, "Patch": 0, "Build": 9001 },
  "Installer": {
    "URL": "https://github.com/you/myplugin/releases/download/v1.0.0/MyPlugin.zip",
    "Type": "ARCHIVE",
    "Checksum": "abc123...",
    "ChecksumType": "SHA256"
  },
  "Descriptions": {
    "ShortDescription": "..."
  }
}
```

Optional manifest fields: `ChangelogURL`, `Tags`, `Homepage`,
`LongDescription`, `FeaturedImageURL`, `ScreenshotURL`,
`AltScreenshotURL`, `Channel ("Beta")`.

### 10.2 GUID matching

The same GUID lives in four places and must agree exactly:

1. `[assembly: Guid("...")]` in `AssemblyInfo.cs`
2. `IPluginManifest.Identifier` (auto-derived from #1 via `PluginBase`)
3. `manifest.json` `"Identifier"`
4. The GUID passed to `new PluginOptionsAccessor(...)`

The GUID **must never change across versions** — it is the
install/uninstall identity.

### 10.3 SHA-256 over the installer

The checksum is computed over the file referenced by `Installer.URL`:

- `Installer.Type = "DLL"` → hash of the `.dll`
- `Installer.Type = "ARCHIVE"` → hash of the `.zip`

**Recompiling after manifest creation invalidates the checksum.** In
CI, the build → hash → manifest sequence must be one transactional
workflow.

### 10.4 MinimumApplicationVersion

Match the `NINA.Plugin` NuGet version the plugin was compiled against.
Compiled against `NINA.Plugin 3.2.0.9001` → manifest declares
`MinimumApplicationVersion = {3, 2, 0, 9001}`.

### 10.5 Folder structure

The official sample workflow writes the manifest to
`manifests/<first-letter-lower>/<Plugin Name>/manifest.<tag>.json` (flat, plugin
version in the filename). Older entries use a NINA-API-version subfolder
(`.../3.0.0/`). Follow the sample workflow; do not invent a layout.

### 10.6 Channels

Beta is selected by `CreateManifest.ps1 -beta` in the template workflow;
`Channel` is not a property in `manifest.schema.json`. Users opt in via NINA
Options > General > Plugin Repositories with URL
`https://nighttime-imaging.eu/wp-json/nina/v1/beta`.

### 10.7 Validation before PR

Validate the generated manifest against `manifest.schema.json` with ajv
(see [build/json-schema-validation.md](../build/json-schema-validation.md))
or `node validate-latest-manifest.js` from the manifest repo. Add a
`make test-manifest` target that does this.

### 10.8 Automation

Preferred: the template's `tools/github-action.yaml` on a version-tag push. It
needs a PAT for the fork PR; a **fine-grained** token suffices. If CI must not
hold a broad token, publish the manifest PR from a local `make publish-manifest`
instead, using your own `gh` auth. Either way: build, hash and manifest are one
transactional step, and the script asserts `Installer.URL` contains
`/<version>/`. Compute SHA-256 with `System.Security.Cryptography`, not
`Get-FileHash` (missing on some runners).

### 10.9 Release rules (from maintainer review)

Derived from isbeorn/daleghent review of manifest PRs (e.g. #467, #148, #246, #384, #589, #751).

1. **Direct, live asset URL.** `Installer.URL` is a GitHub release asset under the
   version tag (`/releases/download/<version-tag>/<file>`). Never a blob/tree page,
   never `/releases/download/main/`. CI asserts the URL contains the version tag and
   gets HTTP 200 before the manifest PR is opened.
2. **Release assets are immutable.** Never re-upload or rebuild an asset under a
   released version; installed users get no update and checksums break. Fix = new version.
3. **Generate, never hand-write.** Use the template's GitHub Action (version-tag push)
   or `CreateManifest.ps1`. A fine-grained PAT is sufficient; a classic PAT is not needed.
   Hand-rolled or AI-written manifests are rejected.
4. **Validate locally** with `node validate-latest-manifest.js` before the PR. Limits:
   `ShortDescription` <= 256 chars, `Name` <= 50, no empty `Tags`, `Installer.Type` is
   `DLL` or `ARCHIVE`, `Descriptions` and checksum fields required.
5. **Identity is fixed.** `Identifier` equals the assembly `[Guid]`, never changes;
   `MinimumApplicationVersion` equals the NINA version the released DLL references.
6. **One PR = one manifest** (one version, one channel), rebased on `main`, no stray
   or duplicate files. Experimental work goes to the Beta channel first.
7. **Ship licence files in the release ZIP** (plugin LICENSE and third-party notices);
   use exact SPDX ids (`GPL-3.0-only`, not `GPL-3.0`); avoid GPL libraries in an MPL host.
8. **Ship own dependencies, not NINA's.** Bundle third-party non-system libraries;
   allow-list the DLLs copied into the ZIP (§2).
9. **Clean the template.** Remove sample code and instructions; use a distinct logo.
10. **Disclose and own.** Disclose material AI use in the PR; an accountable human
    tests and answers for the code. State what problem the plugin solves that NINA
    core or an existing plugin does not. Answer review within two weeks.

### 10.10 Pre-submission self-review

Maintainers review plugin source, not only the manifest. Before submitting check:

- Hardware safety: fail closed; cancellation really stops hardware; a failed step
  (e.g. park) is not followed by dependent steps (e.g. close dome).
- Failures are reported as failures, never as success with substitute data.
- State (account, server, profile) is bound at request time, not read later after a profile change.
- Background work does not depend on UI visibility (`IsVisible`).
- Remote control needs explicit local consent inside NINA; document privacy behaviour.
- Reuse NINA APIs (`NINA.Astrometry`, mediators, message broker) instead of reimplementing.
- Do not patch vendor binaries.
- HTTP/text output uses a no-BOM encoder (§8).

## 11. Pitfalls — do-not list

1. **Do not** bundle NINA-shipped assemblies in the plugin output folder
   (§2).
2. **Do not** use the obsolete `NINA.Core.Utility.RelayCommand` — use
   `CommunityToolkit.Mvvm.Input.RelayCommand` (§6.5).
3. **Do not** subscribe with anonymous lambdas — cannot unsubscribe;
   named methods only (§5.4).
4. **Do not** leave `async void` handler bodies unwrapped — always
   `try / catch` and log (§5.1).
5. **Do not** look for `ImageSaved` on `IImagingMediator` — it lives on
   `IImageSaveMediator` (§5.1).
6. **Do not** mutate FITS headers in `BeforeFinalizeImageSaved` — the
   changes are not reflected; use `BeforeImageSaved` (§5.1).
7. **Do not** access `ISequenceMediator` in `[ImportingConstructor]` —
   defer to `Initialize()` (§4).
8. **Do not** use `HttpListenerMode.Microsoft` — requires admin / netsh
   (§8).
9. **Do not** introduce a parallel logging framework — go through
   `NINA.Core.Utility.Logger` (§9).
10. **Do not** change the plugin GUID across versions — breaks install
    identity (§10.2).
11. **Do not** recompile after manifest generation — invalidates the
    SHA-256 (§10.3).
12. **Do not** use `Dispatcher.BeginInvoke` — use `Dispatcher.InvokeAsync`
    ([style.md](style.md)).
13. **Do not** rename enum members exposed via `GetValueEnum<T>` —
    silently breaks deserialization (§7.1).
14. **Do not** trust the install-folder `<api-version>` to be 4-segment
    — it is the 3-segment `3.0.0` (§1).
15. **Do not** use `Encoding.UTF8` for HTTP or text responses — it emits a BOM that
    breaks scrapers (e.g. OTel Prometheus); use `new UTF8Encoding(false)` (§8).
16. **Do not** put `/releases/download/main/` or a re-uploaded asset in `Installer.URL` (§10.9).

## 12. Repository conventions

Reference implementation: [jewzaam/nina-prometheus-exporter](https://github.com/jewzaam/nina-prometheus-exporter).
Where this section and a generic standard disagree, the plugin-specific rule wins
([common/doc-authority.md](../common/doc-authority.md)).

- **Layout.** Flat (plugin csproj at root, `tests/` excluded via `DefaultItemExcludes`)
  for one project; `src/` + `tests/` once there are three or more projects
  ([project-structure.md](project-structure.md)).
- **Logic separation.** Put NINA-free logic in a `net8.0` library (never `net10.0`: a
  `net8.0-windows` plugin cannot reference it) and keep the plugin a thin adapter;
  or keep one assembly, mock NINA interfaces with Moq and use `InternalsVisibleTo`.
  Pick one per repo and say which in the README.
- **Version.** `X.Y.Z.0`; `AssemblyVersion` == `AssemblyFileVersion`; tag is the bare
  four-segment version (no `v`); a `version-check` target requires a bump versus the
  base branch on PRs.
- **Manifest metadata lives in `Properties/AssemblyInfo.cs`** (§3), not in csproj
  items, so the manifest generator can parse it.
- **Release asset** is `<AssemblyName>.<X.Y.Z.B>.zip` attached to a GitHub release by
  CI. Tags pushed with `GITHUB_TOKEN` do not re-trigger workflows: tag inside the same run.
- **Makefile** (see [build/makefile.md](../build/makefile.md)): default `check` runs
  build, unit tests, format, reachability and version-check. NINA targets: `install`,
  `uninstall`, `kill-nina`, `run-nina`, `install-dev-nina`, `build-package`,
  `build-manifest`, `test-manifest`, `publish-manifest`.
- **CI.** One workflow on `windows-latest`: a quality job on PR and main
  (`make restore RESTORE_FLAGS=--locked-mode`, `make check`), and a main-only,
  idempotent release job (skip if the tag exists).
- **Docs.** README (Install, Configure, Security, License), CHANGELOG (Keep a Changelog),
  LICENSE shipped in the zip, `.editorconfig`. `.gitignore` also covers `*.zip`,
  `manifest.json`, `manifest.schema.json`.
- **Logging and errors.** Every caught exception is logged with `Logger.Error("msg", ex)`;
  never surface errors only as UI status text.
- **Initialize vs constructor.** Constructors only store dependencies; subscribe, register
  consumers and start services in `Initialize()`, one collector class per mediator
  (`Subscribe()` / `Dispose()`), all disposed from `Teardown()`, which ends with `base.Teardown()`.
- **Dockable panels.** `[Export(typeof(IDockableVM))]` on a `DockableVM` subclass; DataTemplate
  key `<FullTypeName>_Dockable`; frozen icon `GeometryGroup`. Do not create a second plugin
  instance to obtain the GUID; do not share state through static view models.
- **Sequencer items.** `[Export(typeof(ISequenceItem))]` with `[ExportMetadata]` Name,
  Description, Icon, Category; `[JsonObject(MemberSerialization.OptIn)]`; implement `Clone`
  and `IValidatable`; template key `<FullTypeName>_Mini`.
- **UI tests.** Every interactive control has `AutomationProperties.AutomationId`. NINA tab
  content is not visible to UI Automation, so FlaUI tests against real NINA need an
  in-plugin test hook (env var named `<PLUGIN>_TEST_*`, inert when unset). UI tests run
  as a separate executable, close NINA first, and never kill unrelated NINA instances
  without the screen lock. See knowledgebase `dotnet/windows-ui-testing.md`.
- **Generated-file header.** AI-written files carry the header required by
  [project-structure.md](project-structure.md).

## 13. Sequencer entities

Applies to items, triggers, conditions and containers (seen in every surveyed plugin).

- Export the matching interface (`ISequenceItem`, `ISequenceTrigger`, `ISequenceCondition`,
  `ISequenceContainer`) with `[ExportMetadata]` Name, Description, Icon, Category, and
  `[JsonObject(MemberSerialization.OptIn)]`. Persisted properties carry `[JsonProperty]` and
  raise `PropertyChanged` in the setter.
- Category is the plugin's display name, or a host key (`Lbl_SequenceCategory_*`) when the
  item belongs in a built-in category.
- Provide an `[ImportingConstructor]`, a copy constructor, `Clone()` and `ToString()`.
  **`Clone()` copies every persisted field**, not only metadata; test it with non-default values.
- Implement `IValidatable`: `Validate()` builds a new `Issues` list, reassigns it and raises
  `PropertyChanged(nameof(Issues))`; call it from setters and `AfterParentChanged()`.
- Report failure by throwing `SequenceEntityFailedException` with a user-readable message so
  NINA's retry and on-error behaviour applies; never report failure as success (§10.10).
- `Execute` forwards its `CancellationToken` to every blocking call and to hardware moves.
- Event-driven triggers hook in `SequenceBlockInitialize`, unhook in `SequenceBlockTeardown`,
  handle being dropped into a running sequence in `AfterParentChanged`, ignore their own
  kind's failures, and move work to `BackgroundQueueWorker<T>` so the sequence never blocks.
- Containers deep-copy children and call `AttachNewParent`.
- Saved sequences serialize type and assembly names. Renaming a class, namespace or assembly
  breaks users' sequences; add an `ISequenceEntityUpgrader` (3.3) when it is unavoidable.
- Templates: editor `<FullTypeName>_Mini` (and `_Dockable`, `_Options` per §6).
- Capture pipeline: `CaptureImage` → `ToImageData` → `PrepareImage` →
  `imageSaveMediator.Enqueue` (or `CaptureAndPrepareImage`). Do not reimplement it.

Other extension points (`IEquipmentProvider<T>`, `IPluggableBehavior`, `IMessageBroker`,
`ISymbolBroker`, `IOptionsVM` file patterns) are exported with `[Export]` the same way; ask in
the NINA repo before reaching in by reflection.

## 14. Shared state, settings scope and files

- NINA composes the manifest and extension parts in **separate MEF containers**.
  `CreationPolicy.Shared` is not a process-wide singleton: the plugin instance and a
  `DockableVM` or sequence item do not share injected instances of your own types. Bridge them
  with a static event, `IMessageBroker`, or a self-registering service, never an assumption.
  Keep cleanup idempotent; the host may dispose the container as well as call `Teardown`.
- Settings are per-profile (`PluginOptionsAccessor`, §7) or global (`Properties.Settings` with
  `Upgrade()` and `CoreUtil.SaveSettings`, or a JSON file under `PluginSettings/<GUID>/`).
  Never store credentials in either unencrypted.
- Never write runtime data (cache, thumbnails, logs) into the plugin install folder; updates
  replace it. Use `%LOCALAPPDATA%\NINA\<PluginName>\`.
- Every `async void` handler and every `new Task(async ...)` is wrapped in try/catch with
  `Logger.Error("msg", ex)`.
- **Logging reconciliation:** use `NINA.Core.Utility.Logger` by default; a separate Serilog file
  is allowed for heavy-logging plugins when it lives under
  `%LOCALAPPDATA%\NINA\<PluginName>\Logs\`, has bounded retention, and users are told to attach it.
- Do not reference every `NINA.*` package; reference `NINA.Plugin` only (§1). Remove upgrade-assistant
  leftovers (`Microsoft.Windows.Compatibility`, `System.Data.DataSetExtensions`).

## 15. Testing

- NUnit or xUnit with Moq in a `*.Tests` project that references the plugin and the same
  `NINA.Plugin` package ([testing.md](testing.md)). Run tests in CI and **gate the release on them**.
- Composition test: build two `CompositionContainer`s (manifest and parts, as NINA does), assert
  the exports resolve and `RegisterConsumer`/`RemoveConsumer` are paired.
- Under STA (`[NonParallelizable]`) instantiate every exported `ResourceDictionary` and
  `LoadContent()` every DataTemplate; a XAML binding contract test asserts each `{Binding X}`
  resolves to a public property (typos otherwise fail silently at runtime).
- Point `CoreUtil.APPLICATIONTEMPPATH` at a per-run directory so tests never touch real NINA data.
- Astrometry or database code needs NINA's native libraries (NOVAS, SOFA, SQLite.Interop)
  vendored into the test project.
- `Clone()` tests use non-default values; init and teardown tests are paired.

## 16. Release CI hardening

- The version has one source. With `GenerateAssemblyInfo=false`, `-p:Version=<tag>` **does nothing**
  and the tag and DLL can diverge (Target Scheduler, Hocus Focus, Ground Station). Either derive the tag from
  `AssemblyInfo.cs` (the reference exporter) or have CI fail when tag and `AssemblyVersion` differ.
- Pin actions to commit SHAs (Dependabot updates them); default `permissions: contents: read`, grant
  `contents: write` only to the publish job.
- Vendor `CreateManifest.ps1` and `manifest.schema.json` with a provenance note instead of curling
  them from `main` at build time.
- Build the manifest from the assets actually published, never from a rebuild.
- Do not pipe a long-lived classic PAT into `gh auth login`; use a fine-grained token or the local
  `make publish-manifest` flow (§10.8).

## Appendix A: Canonical AssemblyInfo

```csharp
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("MyPlugin")]
[assembly: AssemblyDescription("Short one-line description (shows in plugin manager)")]
[assembly: AssemblyCompany("Your Name")]
[assembly: AssemblyProduct("MyPlugin")]
[assembly: AssemblyCopyright("Copyright © 2026")]
[assembly: ComVisible(false)]
[assembly: Guid("00000000-0000-0000-0000-000000000000")]   // do not change after first release
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

[assembly: AssemblyMetadata("License", "Apache-2.0")]
[assembly: AssemblyMetadata("LicenseURL", "https://www.apache.org/licenses/LICENSE-2.0")]
[assembly: AssemblyMetadata("Repository", "https://github.com/you/myplugin")]
[assembly: AssemblyMetadata("Homepage", "https://github.com/you/myplugin")]
[assembly: AssemblyMetadata("ChangelogURL", "https://github.com/you/myplugin/releases")]
[assembly: AssemblyMetadata("MinimumApplicationVersion", "3.2.0.9001")]
[assembly: AssemblyMetadata("Tags", "imaging, automation")]
[assembly: AssemblyMetadata("LongDescription", "Longer multi-paragraph description.")]
[assembly: AssemblyMetadata("FeaturedImageURL", "https://example.com/featured.png")]
[assembly: AssemblyMetadata("ScreenshotURL", "https://example.com/screenshot.png")]
```

## Appendix B — Audit checklist

When auditing a plugin against this standard:

1. **csproj**: `net8.0-windows`, `x64`, `UseWPF=true`, single
   `NINA.Plugin` package reference, post-build deploys to
   `\NINA\Plugins\3.0.0\<Title>\`, does **not** copy NINA-shipped DLLs.
2. **AssemblyInfo.cs**: required and recommended `[AssemblyMetadata]`
   keys present; `MinimumApplicationVersion` matches `NINA.Plugin`
   version; `[Guid]` set.
3. **Main plugin class**: `[Export(typeof(IPluginManifest))]`, single
   `[ImportingConstructor]`, every `+=` paired with a `-=` in
   `Teardown()`.
4. **Options UI** (when present): `Options.xaml.cs` has
   `[Export(typeof(ResourceDictionary))]`; DataTemplate key matches
   `<AssemblyTitle>_Options`.
5. **Persisted settings** (when present): constructs
   `PluginOptionsAccessor` with the assembly GUID; subscribes to
   `IProfileService.ProfileChanged` and unsubscribes in `Teardown()`.
6. **HTTP server** (when present): EmbedIO with
   `HttpListenerMode.EmbedIO`, dedicated named thread, `CancellationToken`
   stop pattern.
7. **Logging**: all calls go through `NINA.Core.Utility.Logger`. No
   log4net, no direct Serilog, no `Console.WriteLine`.
8. **Publishing artifacts**: `manifest.json` matches the published
   schema; `Installer.ChecksumType = "SHA256"`; `Identifier` matches
   `[Guid]`.
