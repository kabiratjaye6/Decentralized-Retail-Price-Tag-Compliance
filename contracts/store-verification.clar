;; Store Verification Contract
;; Validates legitimate retail locations

(define-data-var admin principal tx-sender)

;; Map to store verified retail locations
(define-map verified-stores
  { store-id: uint }
  {
    store-name: (string-utf8 100),
    store-address: (string-utf8 200),
    is-verified: bool,
    verification-date: uint
  }
)

;; Counter for store IDs
(define-data-var store-id-counter uint u0)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Add a new store to the verified list
(define-public (register-store (store-name (string-utf8 100)) (store-address (string-utf8 200)))
  (let
    (
      (new-id (+ (var-get store-id-counter) u1))
    )
    (asserts! (is-admin) (err u403))
    (var-set store-id-counter new-id)
    (map-set verified-stores
      { store-id: new-id }
      {
        store-name: store-name,
        store-address: store-address,
        is-verified: false,
        verification-date: u0
      }
    )
    (ok new-id)
  )
)

;; Verify a store
(define-public (verify-store (store-id uint))
  (let
    (
      (store (unwrap! (map-get? verified-stores { store-id: store-id }) (err u404)))
    )
    (asserts! (is-admin) (err u403))
    (map-set verified-stores
      { store-id: store-id }
      (merge store {
        is-verified: true,
        verification-date: block-height
      })
    )
    (ok true)
  )
)

;; Revoke verification of a store
(define-public (revoke-verification (store-id uint))
  (let
    (
      (store (unwrap! (map-get? verified-stores { store-id: store-id }) (err u404)))
    )
    (asserts! (is-admin) (err u403))
    (map-set verified-stores
      { store-id: store-id }
      (merge store {
        is-verified: false,
        verification-date: u0
      })
    )
    (ok true)
  )
)

;; Read-only function to check if a store is verified
(define-read-only (is-store-verified (store-id uint))
  (default-to false (get is-verified (map-get? verified-stores { store-id: store-id })))
)

;; Read-only function to get store details
(define-read-only (get-store-details (store-id uint))
  (map-get? verified-stores { store-id: store-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
