# Usecase Orchestration — Testing (manual)

Use only when the user asks for tests, test strategy, or refactor-for-testability.

## Principle

Pure steps need **the simplest possible unit test** — no mocks, no DI container, no DB. If a test is complex, the function is probably not pure enough or the input is too heavy.

## What to test where

| Layer | Test type | Mock? |
|-------|-----------|-------|
| Pure steps (`make*`, `build*`, `validate*` on in-memory data) | Unit | **None** — literals in, assert out |
| Ownership validator’s pure child (`validateOwnedByUser`) | Unit | **None** |
| I/O steps (`find*`, `save*`) | Integration | Real or in-memory DB / fake gateway |
| Orchestrator | Integration | Mock repos **or** test DB; assert order + outcome |

**Smell:** every test mocks everything — pure steps were not extracted.

## Pure step — keep tests trivial

```typescript
describe('makeDuplicate', () => {
  it('clears id and suffixes name', () => {
    const source = { id: '1', name: 'Alpha', status: 'draft' }
    expect(makeDuplicate(source)).toEqual({
      id: undefined,
      name: 'Alpha (copy)',
      status: 'draft',
    })
  })
})

describe('validateCanDuplicate', () => {
  it('throws when not draft', () => {
    expect(() => validateCanDuplicate({ status: 'published' }))
      .toThrow(CannotDuplicateError)
  })
})
```

**Avoid in pure-step tests:** repo wiring in `beforeEach`, full app bootstrap, shared mutable fixtures, two rules in one `it`.

## Design for testability (refactor guide)

| Problem | Fix |
|---------|-----|
| Hidden clock inside pure step | Pass `now` as argument |
| Reads from injected service | Move read to I/O step; pass result in |
| Mutates input object | Return new object |
| 8+ fields to call function | Smaller input type or split steps |
| Only handler test for this rule | Extract `validate*` / `build*` and unit test |

## Orchestrator — integration only

```typescript
describe('DuplicateItemUsecase', () => {
  it('rejects non-draft item', async () => {
    itemRepo.findByIdOrFail.mockResolvedValue({ status: 'published' })
    await expect(usecase.execute({ id: '1' })).rejects.toThrow(CannotDuplicateError)
    expect(itemRepo.save).not.toHaveBeenCalled()
  })
})
```

Do **not** re-assert pure-step logic here — that belongs on the extracted function.

## Checklist

- [ ] Each pure step: happy path + one failure path; **no mocks**
- [ ] Tests colocated with step or same module folder
- [ ] Validator throws domain error, not generic error
- [ ] Orchestrator test covers wiring/order only
- [ ] No snapshot of entire handler file
