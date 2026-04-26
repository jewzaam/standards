# Naming Conventions

## General Principles

1. **Repo names:** lowercase, hyphens (`my-tool` not `myTool` or `my_tool`)
1. **Python packages:** lowercase, underscores (`my_tool` not `my-tool`)
1. **Modules:** lowercase, underscores, singular (`model.py` not `models.py` — exception: `types` shadows stdlib, use `models.py` instead)
1. **Variables:** descriptive, include unit of measure where relevant (`timeout_seconds` not `timeout`)
1. **Don't repeat context:** a field inside `ImageConfig` should be `width`, not `image_width`
1. **Start with a verb** for tools/commands that perform actions

## Tool/Command Naming Pattern (Optional)

For families of related CLI tools that move or transform data through a pipeline, a structured pattern helps users predict tool names from their function:

```text
{prefix}-{verb}-{qualifier?}-{noun}-to-{destination?}
```

| Component | Required | Description |
|-----------|----------|-------------|
| `prefix` | Yes | Shared family identifier (e.g., project namespace) |
| `verb` | Yes | Action the tool performs |
| `qualifier` | No | Modifier for the noun |
| `noun` | Yes | What the tool operates on (always singular) |
| `destination` | No | Where data moves to |

Guidelines:

1. **Start with a verb** - Every tool name begins with an action
2. **Use singular nouns** - `light` not `lights`, `header` not `headers`
3. **Include destination when moving** - Use `-to-{dest}` suffix for tools that relocate data
4. **Use qualifiers sparingly** - Only when distinguishing between variants

Define the verbs, nouns, qualifiers, and destinations specific to your project family in your project's docs.
