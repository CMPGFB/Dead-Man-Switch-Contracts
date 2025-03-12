;; Dead Man Switch Contract
;; Authored By Christopher Perceptions 
;; This contract allows an owner to set up a mechanism where assets are transferred to a beneficiary if the owner fails to check in within a specified time period.

;; Constants
(define-constant ERR-NOT-INITIALIZED (err u100))
(define-constant ERR-ALREADY-INITIALIZED (err u101))
(define-constant ERR-NOT-OWNER (err u102))
(define-constant ERR-NOT-BENEFICIARY (err u103))
(define-constant ERR-INVALID-TIMEOUT (err u104))
(define-constant ERR-TIMEOUT-NOT-REACHED (err u105))
(define-constant ERR-NO-FUNDS (err u106))

;; Data Variables
(define-data-var owner principal 'ST000000000000000000000000000000000000000)
(define-data-var beneficiary principal 'ST000000000000000000000000000000000000000)
(define-data-var last-check-in uint u0)
(define-data-var timeout uint u0)
(define-data-var initialized bool false)

;; Events
(define-trait sip-010-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-balance (principal) (response uint uint))
  )
)

(define-map allowed-tokens principal bool)

;; Event definitions
(define-public (contract-event (event-type (string-ascii 50)) (event-data (string-utf8 500)))
  (ok true))

;; Helper functions
(define-read-only (is-contract-initialized)
  (var-get initialized)
)

(define-read-only (get-owner)
  (var-get owner)
)

(define-read-only (get-beneficiary)
  (var-get beneficiary)
)

(define-read-only (get-time-remaining)
  (let (
    (last-checkin (var-get last-check-in))
    (timeout-blocks (var-get timeout))
    (current-height block-height)
  )
    (if (>= current-height (+ last-checkin timeout-blocks))
      u0
      (- (+ last-checkin timeout-blocks) current-height)
    )
  )
)

(define-read-only (is-expired)
  (is-eq (get-time-remaining) u0)
)

(define-private (assert-initialized)
  (if (var-get initialized)
    (ok true)
    ERR-NOT-INITIALIZED
  )
)

(define-private (assert-owner)
  (if (is-eq tx-sender (var-get owner))
    (ok true)
    ERR-NOT-OWNER
  )
)

(define-private (assert-beneficiary)
  (if (is-eq tx-sender (var-get beneficiary))
    (ok true)
    ERR-NOT-BENEFICIARY
  )
)

;; -------------------------------------------------------------------
;; Initialization
;; -------------------------------------------------------------------
(define-public (initialize (new-beneficiary principal) (time-blocks uint))
  (begin
    (asserts! (not (var-get initialized)) ERR-ALREADY-INITIALIZED)
    (asserts! (> time-blocks u0) ERR-INVALID-TIMEOUT)
    
    (var-set owner tx-sender)
    (var-set beneficiary new-beneficiary)
    (var-set timeout time-blocks)
    (var-set last-check-in block-height)
    (var-set initialized true)
    
    (try! (contract-event "initialize" (concat (concat "owner: " (principal->string tx-sender)) 
                                            (concat ", beneficiary: " (principal->string new-beneficiary)))))
    (ok true)
  )
)

;; -------------------------------------------------------------------
;; Owner Functions
;; -------------------------------------------------------------------

(define-public (check-in)
  (begin
    (try! (assert-initialized))
    (try! (assert-owner))
    
    (var-set last-check-in block-height)
    (try! (contract-event "check-in" (concat "block: " (to-string block-height))))
    (ok block-height)
  )
)

(define-public (update-beneficiary (new-beneficiary principal))
  (begin
    (try! (assert-initialized))
    (try! (assert-owner))
    
    (var-set beneficiary new-beneficiary)
    (try! (contract-event "update-beneficiary" (principal->string new-beneficiary)))
    (ok new-beneficiary)
  )
)

(define-public (update-timeout (new-timeout uint))
  (begin
    (try! (assert-initialized))
    (try! (assert-owner))
    (asserts! (> new-timeout u0) ERR-INVALID-TIMEOUT)
    
    (var-set timeout new-timeout)
    (try! (contract-event "update-timeout" (to-string new-timeout)))
    (ok new-timeout)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (try! (assert-initialized))
    (try! (assert-owner))
    
    (var-set owner new-owner)
    (try! (contract-event "transfer-ownership" (principal->string new-owner)))
    (ok new-owner)
  )
)

(define-public (withdraw-stx (amount uint))
  (begin
    (try! (assert-initialized))
    (try! (assert-owner))
    (asserts! (<= amount (stx-get-balance (as-contract tx-sender))) ERR-NO-FUNDS)
    
    (try! (as-contract (stx-transfer? amount tx-sender (var-get owner))))
    (try! (contract-event "withdraw-stx" (to-string amount)))
    (ok amount)
  )
)

(define-public (allow-token (token-contract principal))
  (begin
    (try! (assert-initialized))
    (try! (assert-owner))
    
    (map-set allowed-tokens token-contract true)
    (try! (contract-event "allow-token" (principal->string token-contract)))
    (ok true)
  )
)

(define-public (withdraw-token (token-contract <sip-010-trait>) (amount uint))
  (begin
    (try! (assert-initialized))
    (try! (assert-owner))
    
    (try! (as-contract (contract-call? token-contract transfer 
                       amount 
                       tx-sender 
                       (var-get owner) 
                       none)))
    (try! (contract-event "withdraw-token" (concat (principal->string (contract-of token-contract)) 
                                               (concat ", amount: " (to-string amount)))))
    (ok amount)
  )
)

;; -------------------------------------------------------------------
;; Beneficiary Functions
;; -------------------------------------------------------------------
(define-public (claim-stx)
  (begin
    (try! (assert-initialized))
    (try! (assert-beneficiary))
    (asserts! (is-expired) ERR-TIMEOUT-NOT-REACHED)
    
    (let ((balance (stx-get-balance (as-contract tx-sender))))
      (asserts! (> balance u0) ERR-NO-FUNDS)
      
      (try! (as-contract (stx-transfer? balance tx-sender (var-get beneficiary))))
      (try! (contract-event "claim-stx" (to-string balance)))
      (ok balance)
    )
  )
)

(define-public (claim-token (token-contract <sip-010-trait>))
  (begin
    (try! (assert-initialized))
    (try! (assert-beneficiary))
    (asserts! (is-expired) ERR-TIMEOUT-NOT-REACHED)
    
    (let (
      (balance (unwrap! (as-contract (contract-call? token-contract get-balance tx-sender)) (err u107)))
    )
      (asserts! (> balance u0) ERR-NO-FUNDS)
      
      (try! (as-contract (contract-call? token-contract transfer 
                         balance 
                         tx-sender 
                         (var-get beneficiary) 
                         none)))
      (try! (contract-event "claim-token" (concat (principal->string (contract-of token-contract)) 
                                              (concat ", amount: " (to-string balance)))))
      (ok balance)
    )
  )
)

;; -------------------------------------------------------------------
;; Fallback: Allow the contract to receive STX
;; -------------------------------------------------------------------
(define-public (deposit-stx (amount uint))
  (begin
    (try! (assert-initialized))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (try! (contract-event "deposit-stx" (to-string amount)))
    (ok amount)
  )
)

;; Jesus Loves You 
;; John 3:16
;; Revelation 21:4
