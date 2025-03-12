;; Dead Man’s Switch Contract (Using Bitcoin UTXOs)

(define-data-var owner principal 'ST0000000000000000000000000000000000000000)
(define-data-var beneficiary principal 'ST0000000000000000000000000000000000000000)
(define-data-var btc-beneficiary (optional (tuple (address (buff 40)))) none)
(define-data-var last-check-in int 0)
(define-data-var timeout int 0)
(define-data-var initialized bool false)

;; ------------------------------------------
;; Initialization Function
;; ------------------------------------------
(define-public (initialize (beneficiary principal) (btc-address (buff 40)) (timeout int))
  (begin
    (if (var-get initialized)
        (err "Already initialized")
        (if (<= timeout 0)
            (err "Timeout must be positive")
            (begin
              (var-set owner tx-sender)
              (var-set beneficiary beneficiary)
              (var-set btc-beneficiary (some {address: btc-address}))
              (var-set timeout timeout)
              (var-set last-check-in block-height)
              (var-set initialized true)
              (ok "Contract initialized")
            )
        )
    )
  )
)

;; ------------------------------------------
;; Owner Functions
;; ------------------------------------------

;; Owner must check in to prevent funds from transferring to the beneficiary
(define-public (check-in)
  (begin
    (if (is-eq tx-sender (var-get owner))
        (begin
          (var-set last-check-in block-height)
          (ok block-height)
        )
        (err "Only owner can check in")
    )
  )
)

;; ------------------------------------------
;; Bitcoin UTXO Interaction
;; ------------------------------------------

;; Function to deposit BTC to the contract-controlled UTXO
(define-public (deposit-btc (amount int))
  (begin
    (if (is-eq tx-sender (var-get owner))
        (begin
          (stx-transfer? amount tx-sender (contract-principal))
          (ok "Bitcoin deposited")
        )
        (err "Only owner can deposit BTC")
    )
  )
)

;; Function to send BTC to the beneficiary if the owner is inactive
(define-public (trigger-switch)
  (let ((last-checked (var-get last-check-in))
        (timeout (var-get timeout))
        (beneficiary (var-get btc-beneficiary)))

    (if (some beneficiary)
        (if (> (- block-height last-checked) timeout)
            (begin
              (match beneficiary btc-recipient
                (begin
                  (send-bitcoin (unwrap! btc-recipient "Invalid BTC address") (stx-get-balance (contract-principal)))
                  (ok "Bitcoin sent to beneficiary")
                )
              )
            )
            (err "Timeout not reached yet")
        )
        (err "Beneficiary BTC address not set")
    )
  )
)

;; Jesus Loves You 
;; John 3:16
;; Revelation 21:4
