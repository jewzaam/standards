# JSON Schema Validation via `npx ajv`

Validating JSON artifacts (manifests, config files, API payloads) against a
JSON Schema is a common CI and pre-submit task. `ajv-cli` is the standard
way to do it without authoring a custom Node script.

## `ajv-cli` exposes its binary as `ajv`, not `ajv-cli`

Common mistake:

```text
npx --yes -p ajv-cli@5 ajv-cli validate -s schema.json -d data.json
# 'ajv-cli' is not recognized as an internal or external command
```

The npm package is named `ajv-cli` but installs its binary as `ajv`. Correct
invocation:

```bash
npx --yes -p ajv-cli@5 -p ajv-formats@2 \
    ajv validate \
        -s schema.json \
        -d data.json \
        -c ajv-formats \
        --strict=false
```

## Required companion flags

- **`-c ajv-formats`** — required when the schema uses string formats like
  `uuid`, `uri-reference`, `date-time`, `email`. Without it, schemas that
  declare `"format": "uuid"` fail to compile because the format keyword is
  unknown to the core validator.
- **`-p ajv-formats@2`** — the `-c` flag references a plugin module that
  must be installed alongside `ajv-cli`. Both `-p` flags are needed in the
  same `npx` invocation.
- **`--strict=false`** — required when the schema contains keywords the
  strict mode rejects. Older draft-07 schemas commonly trip this (unknown
  keywords, `$schema` mismatches, etc.). Without it, validation fails with
  schema-compile errors rather than data-validation errors.

## When to apply

- CI workflows that need to validate JSON artifacts before publishing or
  submitting them upstream.
- Local Make targets (`test-manifest`, `test-schema`) that gate a release
  on schema compliance.

Prefer `npx ajv` to authoring a one-off Node validator script — `ajv-cli`
is maintained, handles `$ref`, draft selection, and format plugins, and
runs without a `package.json` in the repo.

## Make target shape

```makefile
test-manifest:  ## Validate manifest.json against the upstream schema
	npx --yes -p ajv-cli@5 -p ajv-formats@2 \
	    ajv validate \
	        -s schema.json \
	        -d manifest.json \
	        -c ajv-formats \
	        --strict=false
```

Pin the `ajv-cli` major version (`@5`) so CI behavior doesn't drift on
unrelated releases.
