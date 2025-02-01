;; VaultPulse - Asset tracking system

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-vault-not-found (err u101))
(define-constant err-asset-not-found (err u102))

;; Data structures
(define-map vaults
  { vault-id: uint }
  {
    owner: principal,
    created-at: uint,
    name: (string-ascii 64)
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

;; Public functions
(define-public (create-vault (name (string-ascii 64)))
  (let
    (
      (vault-id (var-get next-vault-id))
    )
    (map-insert vaults
      { vault-id: vault-id }
      {
        owner: tx-sender,
        created-at: block-height,
        name: name
      }
    )
    (var-set next-vault-id (+ vault-id u1))
    (ok vault-id)
  )
)

(define-public (add-asset (vault-id uint) (name (string-ascii 64)) (quantity uint))
  (let
    (
      (asset-id (var-get next-asset-id))
      (vault (get-vault-by-id vault-id))
    )
    (asserts! (is-eq (some tx-sender) (get owner vault)) err-not-authorized)
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
    (ok asset-id)
  )
)

;; Read only functions
(define-read-only (get-vault-by-id (vault-id uint))
  (map-get? vaults { vault-id: vault-id })
)

(define-read-only (get-asset (asset-id uint) (vault-id uint))
  (map-get? assets { asset-id: asset-id, vault-id: vault-id })
)
