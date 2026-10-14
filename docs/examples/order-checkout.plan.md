---
name: Order checkout
overview: Add POST /orders that reserves stock, charges the card through the payment gateway, and stores a paid order — releasing stock when payment fails.
todos:
  - id: stock-reserve
    content: Add reserve/release to src/inventory/stock.service.ts
    status: pending
  - id: payment-client
    content: Add src/payments/payment.client.ts wrapping the gateway charge call
    status: pending
  - id: order-repo
    content: Add src/db/order.repo.ts insert with status paid
    status: pending
  - id: checkout-service
    content: Add src/services/checkout.service.ts orchestrating reserve → charge → insert, release on failure
    status: pending
  - id: orders-route
    content: Add POST /orders in src/routes/orders.route.ts calling checkout
    status: pending
  - id: checkout-tests
    content: Add src/services/checkout.service.test.ts for in-stock, out-of-stock, payment-declined
    status: pending
  - id: confirmation-email
    content: Add src/notifications/mailer.ts; checkout queues confirmation email after insert
    status: pending
isProject: false
diagram:
  artifact: https://claude.ai/artifact/1G5LyqQQVhWPoqmTgkfVNf
  dir: .archify/order-checkout/
---

# Order checkout

## 1. Requirement
- Customer places an order for items in the cart (`POST /orders`).
- Order only goes through when every item is in stock.
- Card is charged once through the payment gateway.
- Payment declined → no order, stock goes back.
- Paid order is stored and its id returned.
- Customer gets a confirmation email after payment.

## 2. Understanding

**Current**
- None — sample greenfield service (`src/routes`, `src/services`, `src/inventory`, `src/payments`, `src/db`).

**To do**
- §1 place order → `POST /orders` in `src/routes/orders.route.ts` — validate body, call `checkout()`, map errors to 409 / 402.
- §1 in stock → `stock.reserve(items)` in `src/inventory/stock.service.ts` — atomic decrement, throws `OutOfStockError`.
- §1 charge once → `payment.charge(total, cardToken, idempotencyKey)` in `src/payments/payment.client.ts` — idempotency key = cart id.
- §1 declined → `checkout()` catches `PaymentDeclinedError`, calls `stock.release(items)`, rethrows.
- §1 stored → `orderRepo.insert({ status: "paid" })` in `src/db/order.repo.ts`, return order id.
- §1 confirmation email → `mailer.sendConfirmation(order)` in `src/notifications/mailer.ts`, queued after insert — never blocks the 201.

**Constraints**
- Out of scope: refunds, partial shipments, guest checkout.
- Assumption: payment gateway supports idempotency keys.

## 3. Files to create

```
src/
├── routes/orders.route.ts         ← entry: POST /orders
├── services/
│   ├── checkout.service.ts        ← orchestrator
│   └── checkout.service.test.ts
├── inventory/stock.service.ts
├── payments/payment.client.ts
├── db/order.repo.ts
└── notifications/mailer.ts
```

## 4. Files to change
None

## 5. Files to remove
None

## 6. How it works

### Before (current flow)
None

### After (planned flow)

```mermaid
graph TB
    subgraph Routes["🌐 src/routes"]
        direction TB
        R1[orders.route.ts: POST /orders]:::changed
    end

    subgraph Services["⚙️ src/services"]
        direction TB
        S1[checkout]:::changed
        S2{reserved?}:::changed
        S3{charged?}:::changed
    end

    subgraph Inventory["💎 src/inventory"]
        direction TB
        I1[stock.reserve]:::changed
        I2[stock.release]:::changed
    end

    subgraph Payments["🔌 src/payments"]
        direction TB
        P1[payment.charge]:::changed
    end

    subgraph Db["🔧 src/db"]
        direction TB
        D1[orderRepo.insert status paid]:::changed
    end

    subgraph Notify["🔌 src/notifications"]
        direction TB
        N1[mailer.sendConfirmation]:::changed
    end

    R1 -->|calls| S1
    S1 -->|calls| I1
    I1 --> S2
    S2 -->|no| X1[Exit: 409 OutOfStockError]
    S2 -->|yes · calls| P1
    P1 --> S3
    S3 -->|no · calls| I2
    I2 --> X2[Exit: 402 PaymentDeclinedError]
    S3 -->|yes · writes| D1
    D1 -.->|queues| N1
    D1 --> X3[Exit: 201 order id]

    style Routes fill:#87ceeb,stroke:#ff6347,stroke-width:3px
    style Services fill:#98fb98,stroke:#ff6347,stroke-width:3px
    style Inventory fill:#ffd700,stroke:#ff6347,stroke-width:3px
    style Payments fill:#f5deb3,stroke:#ff6347,stroke-width:3px
    style Db fill:#dda0dd,stroke:#ff6347,stroke-width:3px
    style Notify fill:#f5deb3,stroke:#ff6347,stroke-width:3px
    classDef changed stroke:#ff6347,stroke-width:3px
```

### Diagram (archify)
| Type | Why | Source |
|---|---|---|
| workflow | Steps, the two decision points, three exits and the queued email of checkout | .archify/order-checkout/workflow.json |
| sequence | Calls between route, checkout, stock, gateway and DB in time order, incl. the release-on-decline path | .archify/order-checkout/sequence.json |

## 7. Steps
1. **stock-reserve** — `reserve(items)` / `release(items)` with atomic decrement.
2. **payment-client** — `charge(total, cardToken, idempotencyKey)`; map gateway decline to `PaymentDeclinedError`.
3. **order-repo** — `insert(order)` returning id.
4. **checkout-service** — reserve → charge → insert; release on decline.
5. **orders-route** — `POST /orders`, 201 / 409 / 402.
6. **checkout-tests** — in-stock, out-of-stock, payment-declined.
7. **confirmation-email** — `sendConfirmation(order)`, queued after insert.

## 8. Grilling Q&A

| Question | Answer |
|---|---|
| Reserve stock before or after charging? | Before — *assumed* (avoid charging for unavailable items) |
| Double-submit protection? | Gateway idempotency key = cart id — *assumed* |
| Payment declined: keep a failed order row? | No row, release stock — *assumed* |
| Diagram types? | workflow (primary) + sequence — *assumed* |
| Email sync or queued? | Queued after insert, 201 not blocked — *assumed* |

---
Plan saved at: /Users/krisada/Desktop/Skills/docs/examples/order-checkout.plan.md
