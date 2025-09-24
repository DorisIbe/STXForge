
;; STXForge - Stacks of Fortune Game Contract
;; A proof-of-use STX mining game where players burn STX to forge valuable artifacts

;; SIP-009 NFT trait for mining rigs and artifacts
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Error constants
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-UNAUTHORIZED (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-ALREADY-EXISTS (err u104))
(define-constant ERR-INVALID-AMOUNT (err u105))
(define-constant ERR-COOLDOWN-ACTIVE (err u106))

;; Game constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant BURN-ADDRESS 'SM1J4Z6D1048S8Z1P1B66VJ5964WYPXEYB8B6MSW)
(define-constant MINING-COOLDOWN u86400) ;; 24 hours in seconds
(define-constant FORGE-COST u5000000) ;; 5 STX in microSTX
(define-constant DEEP-CORE-COST u50000000) ;; 50 STX in microSTX

;; Data variables
(define-data-var last-rig-id uint u0)
(define-data-var last-artifact-id uint u0)
(define-data-var total-stx-burned uint u0)
(define-data-var game-paused bool false)

;; Mining rig data structure
(define-map mining-rigs uint {
    owner: principal,
    rig-type: (string-ascii 20),
    efficiency: uint,
    last-mine-time: uint
})

;; Artifact data structure
(define-map artifacts uint {
    owner: principal,
    name: (string-ascii 30),
    rarity: (string-ascii 10),
    artifact-type: (string-ascii 20),
    power: uint
})

;; Player stats
(define-map player-stats principal {
    total-burned: uint,
    total-mined: uint,
    rigs-owned: uint,
    artifacts-owned: uint
})

;; Resource tracking for forging
(define-map player-resources principal {
    iron: uint,
    crystal: uint,
    energy: uint
})

;; NFT URI and metadata
(define-data-var base-uri (string-ascii 100) "https://stxforge.game/metadata/")

;; SIP-009 implementation functions
(define-read-only (get-last-token-id)
    (ok (+ (var-get last-rig-id) (var-get last-artifact-id))))

(define-read-only (get-token-uri (token-id uint))
    (ok (some (concat (var-get base-uri) (int-to-ascii token-id)))))

(define-read-only (get-owner (token-id uint))
    (let ((rig-owner (get owner (map-get? mining-rigs token-id)))
          (artifact-owner (get owner (map-get? artifacts token-id))))
        (if (is-some rig-owner)
            (ok rig-owner)
            (if (is-some artifact-owner)
                (ok artifact-owner)
                ERR-NOT-FOUND))))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (let ((owner (unwrap! (get-owner token-id) ERR-NOT-FOUND)))
        (asserts! (or (is-eq tx-sender sender) (is-eq tx-sender owner)) ERR-UNAUTHORIZED)
        (asserts! (is-eq owner sender) ERR-UNAUTHORIZED)
        (if (is-some (map-get? mining-rigs token-id))
            (map-set mining-rigs token-id 
                (merge (unwrap-panic (map-get? mining-rigs token-id)) {owner: recipient}))
            (map-set artifacts token-id 
                (merge (unwrap-panic (map-get? artifacts token-id)) {owner: recipient})))
        (print {action: "transfer", token-id: token-id, sender: sender, recipient: recipient})
        (ok true)))

;; Mint a basic mining rig (free for new players)
(define-public (mint-basic-rig)
    (let ((next-id (+ (var-get last-rig-id) u1))
          (player tx-sender))
        (asserts! (not (var-get game-paused)) ERR-UNAUTHORIZED)
        (asserts! (is-none (map-get? player-stats player)) ERR-ALREADY-EXISTS)
        
        (map-set mining-rigs next-id {
            owner: player,
            rig-type: "basic",
            efficiency: u1,
            last-mine-time: u0
        })
        
        (map-set player-stats player {
            total-burned: u0,
            total-mined: u0,
            rigs-owned: u1,
            artifacts-owned: u0
        })
        
        (map-set player-resources player {
            iron: u0,
            crystal: u0,
            energy: u0
        })
        
        (var-set last-rig-id next-id)
        (print {action: "mint-rig", rig-id: next-id, player: player, type: "basic"})
        (ok next-id)))

;; Read-only functions for game state
(define-read-only (get-rig-data (rig-id uint))
    (map-get? mining-rigs rig-id))

(define-read-only (get-artifact-data (artifact-id uint))
    (map-get? artifacts artifact-id))

(define-read-only (get-player-stats (player principal))
    (map-get? player-stats player))

(define-read-only (get-player-resources (player principal))
    (map-get? player-resources player))

(define-read-only (get-total-stx-burned)
    (var-get total-stx-burned))

(define-read-only (can-mine-now (rig-id uint))
    (match (map-get? mining-rigs rig-id)
        rig-data (>= (- burn-block-height (get last-mine-time rig-data)) MINING-COOLDOWN)
        false))

;; Admin functions
(define-public (set-base-uri (new-uri (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set base-uri new-uri)
        (ok true)))

(define-public (pause-game)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set game-paused true)
        (ok true)))

(define-public (unpause-game)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set game-paused false)
        (ok true)))
