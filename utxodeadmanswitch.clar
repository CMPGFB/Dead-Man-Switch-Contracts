;; Dead Man’s Switch Contract (Bitcoin UTXO Integration)
;; Cultivated by Christopher Perceptions

;; Constants
(define-constant ERR-NOT-INITIALIZED (err u100))
(define-constant ERR-ALREADY-INITIALIZED (err u101))
(define-constant ERR-NOT-OWNER (err u102))
(define-constant ERR-NOT-BENEFICIARY (err u103))
(define-constant ERR-INVALID-TIMEOUT (err u104))
(define-constant ERR-TIMEOUT-NOT-REACHED (err u105))
(define-constant ERR-NO-BITCOIN-UTXO (err u106))

;; Data Variables
(define-data-var owner principal tx-sender)
(define-data-var beneficiary principal 'ST0000000000000000000000000000000000000000)
(define-data-var btc-beneficiary (optional (tuple (address (buff 40)))) none)
(define-data-var last-check-in uint u0)
(define-data-var timeout uint u0)
(define-data-var initialized bool false)
(define-data-var btc-utxo (optional (tuple (txid (buff 32)) (index uint) (value uint))) none)

;; -------------------------------------------------------------------
;; Initialization
;; -------------------------------------------------------------------
(define-public (initialize (new-beneficiary principal) (btc-address (buff 40)) (time-blocks uint))
  (begin
    (asserts! (not (var-get initialized)) ERR-ALREADY-INITIALIZED)
    (asserts! (> time-blocks u0) ERR-INVALID-TIMEOUT)

    (var-set owner tx-sender)
    (var-set beneficiary new-beneficiary)
    (var-set btc-beneficiary (some {address: btc-address}))
    (var-set timeout time-blocks)
    (var-set last-check-in block-height)
    (var-set initialized true)
    (ok "Contract initialized")
  )
)

;; -------------------------------------------------------------------
;; Owner Functions
;; -------------------------------------------------------------------
(define-public (check-in)
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-OWNER)
    (var-set last-check-in block-height)
    (ok block-height)
  )
)

;; Function to register a Bitcoin UTXO with the contract
(define-public (register-btc-utxo (txid (buff 32)) (index uint) (value uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-OWNER)
    (var-set btc-utxo (some {txid: txid, index: index, value: value}))
    (ok "Bitcoin UTXO registered")
  )
)

;; -------------------------------------------------------------------
;; Trigger Dead Man’s Switch
;; -------------------------------------------------------------------
(define-public (trigger-switch)
  (let ((last-checked (var-get last-check-in))
        (timeout (var-get timeout))
        (btc-utxo (var-get btc-utxo))
        (beneficiary (var-get btc-beneficiary)))

    (begin
      (asserts! (some beneficiary) (err "BTC beneficiary not set"))
      (asserts! (some btc-utxo) ERR-NO-BITCOIN-UTXO)

      (if (> (- block-height last-checked) timeout)
          (begin
            (match btc-utxo btc-utxo-data
              (match beneficiary btc-recipient
                (begin
                  (unwrap! (send-bitcoin (unwrap! btc-recipient "Invalid BTC address") (unwrap! btc-utxo-data.value ERR-NO-BITCOIN-UTXO)))
                  (ok "Bitcoin sent to beneficiary")
                )
              )
            )
          )
          ERR-TIMEOUT-NOT-REACHED
      )
    )
  )
)

;; Jesus Loves You 
;; John 3:16
;; Revelation 21:4
