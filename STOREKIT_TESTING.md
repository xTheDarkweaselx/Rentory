# StoreKit Testing

- StoreKit configuration file: `Rentory.storekit`
- Product ID: `com.fusionstudios.rentory.lifetimeunlock`
- Product type: Non-consumable

## Enable In Xcode

1. Open the scheme selector.
2. Choose `Edit Scheme`.
3. Select `Run`.
4. Open `Options`.
5. Set `StoreKit Configuration` to `Rentory.storekit`.

## Test Scenarios

- Product loads on the paywall.
- Lifetime unlock purchase succeeds.
- Restore purchase works.
- Cancelled purchase shows a friendly message.
- Relaunch keeps the unlock active.
- Free limits are removed after unlock.
