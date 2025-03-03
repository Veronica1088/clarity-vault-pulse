;; VaultPulse - Enhanced Asset tracking system

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-vault-not-found (err u101))
(define-constant err-asset-not-found (err u102))
(define-constant err-invalid-quantity (err u103))
(define-constant err-vault-inactive (err u104))

;; Data structures
(define-map vaults
  { vault-id: uint }
  {
    owner: principal,
    created-at: uint,
    name: (string-ascii 64),
    active: bool
  }
)

(define-map assets
  { asset-id: uint, vault-id: uint }
  {
    name: (string-ascii 64),
    quantity: uint,
    created-at: uint,
    last-modified: uint
  }
)

;; Counter for IDs
(define-data-var next-vault-id uint u1)
(define-data-var next-asset-id uint u1)

;; Events
(define-data-var last-event-id uint u0)
(define-map events
  { event-id: uint }
  {
    event-type: (string-ascii 20),
    asset-id: (optional uint),
    vault-id: uint,
    data: (string-ascii 256)
  }
)

;; Helper functions
(define-private (log-event (event-type (string-ascii 20)) (vault-id uint) (asset-id (optional uint)) (data (string-ascii 256)))
  (let
    ((event-id (+ (var-get last-event-id) u1)))
    (var-set last-event-id event-id)
    (map-insert events
      { event-id: event-id }
      {
        event-type: event-type,
        asset-id: asset-id,
        vault-id: vault-id,
        data: data
      }
    )
    (ok event-id)
  )
)

;; Public functions
(define-public (create-vault (name (string-ascii 64)))
  (let
    ((vault-id (var-get next-vault-id)))
    (map-insert vaults
      { vault-id: vault-id }
      {
        owner: tx-sender,
        created-at: block-height,
        name: name,
        active: true
      }
    )
    (var-set next-vault-id (+ vault-id u1))
    (log-event "VAULT_CREATED" vault-id none name)
    (ok vault-id)
  )
)

(define-public (add-asset (vault-id uint) (name (string-ascii 64)) (quantity uint))
  (let
    (
      (asset-id (var-get next-asset-id))
      (vault (get-vault-by-id vault-id))
    )
    (asserts! (is-some vault) err-vault-not-found)
    (asserts! (get active (unwrap-panic vault)) err-vault-inactive)
    (asserts! (is-eq (some tx-sender) (get owner vault)) err-not-authorized)
    (asserts! (> quantity u0) err-invalid-quantity)
    
    (map-insert assets
      { asset-id: asset-id, vault-id: vault-id }
      {
        name: name,
        quantity: quantity,
        created-at: block-height,
        last-modified: block-height
      }
    )
    (var-set next-asset-id (+ asset-id u1))
    (log-event "ASSET_ADDED" vault-id (some asset-id) name)
    (ok asset-id)
  )
)

(define-public (transfer-asset (asset-id uint) (from-vault-id uint) (to-vault-id uint))
  (let
    (
      (asset (get-asset asset-id from-vault-id))
      (from-vault (get-vault-by-id from-vault-id))
      (to-vault (get-vault-by-id to-vault-id))
    )
    (asserts! (and (is-some from-vault) (is-some to-vault)) err-vault-not-found)
    (asserts! (is-some asset) err-asset-not-found)
    (asserts! (is-eq (some tx-sender) (get owner from-vault)) err-not-authorized)
    (asserts! (get active (unwrap-panic from-vault)) err-vault-inactive)
    (asserts! (get active (unwrap-panic to-vault)) err-vault-inactive)
    
    (let ((current-asset (unwrap-panic asset)))
      (map-delete assets { asset-id: asset-id, vault-id: from-vault-id })
      (map-insert assets
        { asset-id: asset-id, vault-id: to-vault-id }
        {
          name: (get name current-asset),
          quantity: (get quantity current-asset),
          created-at: (get created-at current-asset),
          last-modified: block-height
        }
      )
      (log-event "ASSET_TRANSFERRED" to-vault-id (some asset-id) "")
      (ok true)
    )
  )
)

;; Read only functions
(define-read-only (get-vault-by-id (vault-id uint))
  (map-get? vaults { vault-id: vault-id })
)

(define-read-only (get-asset (asset-id uint) (vault-id uint))
  (map-get? assets { asset-id: asset-id, vault-id: vault-id })
)

(define-read-only (get-event (event-id uint))
  (map-get? events { event-id: event-id })
)
