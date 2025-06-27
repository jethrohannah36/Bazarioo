(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-member (err u101))
(define-constant err-invalid-listing (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-listing-not-available (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-invalid-vote (err u106))
(define-constant err-proposal-not-active (err u107))
(define-constant err-already-voted (err u108))

(define-data-var membership-fee uint u1000000)
(define-data-var listing-fee uint u100000)
(define-data-var platform-fee-percentage uint u250)
(define-data-var next-listing-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var total-members uint u0)
(define-data-var contract-balance uint u0)

(define-map members principal bool)
(define-map member-join-block principal uint)
(define-map listings
  uint
  {
    seller: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    price: uint,
    available: bool,
    created-at: uint,
    category: (string-ascii 50)
  }
)

(define-map purchases
  uint
  {
    buyer: principal,
    listing-id: uint,
    amount: uint,
    timestamp: uint
  }
)

(define-map proposals
  uint
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    votes-for: uint,
    votes-against: uint,
    end-block: uint,
    executed: bool,
    proposal-type: (string-ascii 50)
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, amount: uint }
)

(define-map member-reputation principal uint)

(define-public (join-marketplace)
  (let
    (
      (membership-cost (var-get membership-fee))
    )
    (asserts! (is-none (map-get? members tx-sender)) err-unauthorized)
    (try! (stx-transfer? membership-cost tx-sender (as-contract tx-sender)))
    (map-set members tx-sender true)
    (map-set member-join-block tx-sender stacks-block-height)
    (map-set member-reputation tx-sender u100)
    (var-set total-members (+ (var-get total-members) u1))
    (var-set contract-balance (+ (var-get contract-balance) membership-cost))
    (ok true)
  )
)

(define-public (create-listing (title (string-ascii 100)) (description (string-ascii 500)) (price uint) (category (string-ascii 50)))
  (let
    (
      (listing-id (var-get next-listing-id))
      (listing-cost (var-get listing-fee))
    )
    (asserts! (is-member tx-sender) err-not-member)
    (asserts! (> price u0) err-invalid-listing)
    (try! (stx-transfer? listing-cost tx-sender (as-contract tx-sender)))
    (map-set listings listing-id
      {
        seller: tx-sender,
        title: title,
        description: description,
        price: price,
        available: true,
        created-at: stacks-block-height,
        category: category
      }
    )
    (var-set next-listing-id (+ listing-id u1))
    (var-set contract-balance (+ (var-get contract-balance) listing-cost))
    (ok listing-id)
  )
)

(define-public (purchase-item (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings listing-id) err-invalid-listing))
      (item-price (get price listing))
      (seller (get seller listing))
      (platform-fee (/ (* item-price (var-get platform-fee-percentage)) u10000))
      (seller-amount (- item-price platform-fee))
    )
    (asserts! (is-member tx-sender) err-not-member)
    (asserts! (get available listing) err-listing-not-available)
    (asserts! (not (is-eq tx-sender seller)) err-unauthorized)
    (let ((transfer-result (try! (stx-transfer? item-price tx-sender (as-contract tx-sender)))))
      (let ((seller-transfer-result (try! (as-contract (stx-transfer? seller-amount (as-contract tx-sender) seller)))))
        (begin
          (map-set listings listing-id (merge listing { available: false }))
          (map-set purchases listing-id
            {
              buyer: tx-sender,
              listing-id: listing-id,
              amount: item-price,
              timestamp: stacks-block-height
            }
          )
          (var-set contract-balance (+ (var-get contract-balance) platform-fee))
          (unwrap! (update-reputation seller u10) err-unauthorized)
          (ok true)
        )
      )
    )
  )
)

(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)) (proposal-type (string-ascii 50)))
  (let
    (
      (proposal-id (var-get next-proposal-id))
      (end-block (+ stacks-block-height u1440))
    )
    (asserts! (is-member tx-sender) err-not-member)
    (map-set proposals proposal-id
      {
        proposer: tx-sender,
        title: title,
        description: description,
        votes-for: u0,
        votes-against: u0,
        end-block: end-block,
        executed: false,
        proposal-type: proposal-type
      }
    )
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (vote-proposal (proposal-id uint) (vote-for bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) err-invalid-vote))
      (voter-reputation (default-to u0 (map-get? member-reputation tx-sender)))
      (vote-key { proposal-id: proposal-id, voter: tx-sender })
    )
    (asserts! (is-member tx-sender) err-not-member)
    (asserts! (< stacks-block-height (get end-block proposal)) err-proposal-not-active)
    (asserts! (is-none (map-get? votes vote-key)) err-already-voted)
    (map-set votes vote-key { vote: vote-for, amount: voter-reputation })
    (if vote-for
      (map-set proposals proposal-id 
        (merge proposal { votes-for: (+ (get votes-for proposal) voter-reputation) }))
      (map-set proposals proposal-id 
        (merge proposal { votes-against: (+ (get votes-against proposal) voter-reputation) }))
    )
    (ok true)
  )
)

(define-public (update-listing-availability (listing-id uint) (available bool))
  (let
    (
      (listing (unwrap! (map-get? listings listing-id) err-invalid-listing))
    )
    (asserts! (is-eq tx-sender (get seller listing)) err-unauthorized)
    (map-set listings listing-id (merge listing { available: available }))
    (ok true)
  )
)

(define-public (set-membership-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set membership-fee new-fee)
    (ok true)
  )
)

(define-public (set-listing-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set listing-fee new-fee)
    (ok true)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u1000) err-invalid-listing)
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)

(define-public (withdraw-funds (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= amount (var-get contract-balance)) err-insufficient-payment)
    (try! (as-contract (stx-transfer? amount tx-sender contract-owner)))
    (var-set contract-balance (- (var-get contract-balance) amount))
    (ok true)
  )
)

(define-private (is-member (user principal))
  (default-to false (map-get? members user))
)

(define-private (update-reputation (user principal) (points uint))
  (let
    (
      (current-rep (default-to u0 (map-get? member-reputation user)))
    )
    (map-set member-reputation user (+ current-rep points))
    (ok true)
  )
)

(define-read-only (get-listing (listing-id uint))
  (map-get? listings listing-id)
)

(define-read-only (get-member-status (user principal))
  (default-to false (map-get? members user))
)

(define-read-only (get-member-reputation (user principal))
  (default-to u0 (map-get? member-reputation user))
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-purchase (listing-id uint))
  (map-get? purchases listing-id)
)

(define-read-only (get-membership-fee)
  (var-get membership-fee)
)

(define-read-only (get-listing-fee)
  (var-get listing-fee)
)

(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage)
)

(define-read-only (get-total-members)
  (var-get total-members)
)

(define-read-only (get-contract-balance)
  (var-get contract-balance)
)

(define-read-only (get-member-join-block (user principal))
  (map-get? member-join-block user)
)
