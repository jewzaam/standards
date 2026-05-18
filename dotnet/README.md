# .NET Standards

C# and .NET standards applicable to all projects, with NINA plugin standards
nested under `nina-plugin.md` for that subsystem.

The NINA plugin standard is derived from citation-backed research
maintained privately. Every claim there traces to a numbered
public source (NINA repo, NuGet, plugin template, manifest repo, MEF/WPF
docs). This standard restates the resulting conventions in normative
form, without the citation refs — the standard itself is the source of
truth for consumers of this repo.

## Files

| Standard | Description |
|----------|-------------|
| [Style](style.md) | Async, nullable, .NET 8/10 language features, MVVM |
| [Project Structure](project-structure.md) | csproj layout, TFM choice, deps |
| [Testing](testing.md) | xUnit/NUnit, Moq, FluentAssertions, STA/WPF tests |
| [NINA Plugin](nina-plugin.md) | NINA 3.x C# plugin: build, MEF, mediators, options, HTTP, logging, publishing |
