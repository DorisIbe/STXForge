;; STXForge - Stacks of Fortune Game Contract
;; A proof-of-use STX mining game where players burn STX to forge valuable artifacts

;; STXForge NFT-like functionality for mining rigs and artifacts

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
(define-constant BURN-ADDRESS 'SP000000000000000000002Q6VF78)
(define-constant MINING-COOLDOWN u86400) ;; 24 hours in seconds
(define-constant FORGE-COST u5000000) ;; 5 STX in microSTX
(define-constant DEEP-CORE-COST u50000000) ;; 50 STX in microSTX

;; Data variables
(define-data-var last-rig-id uint u0)
(define-data-var last-artifact-id uint u0)
(define-data-var total-stx-burned uint u0)
(define-data-var game-paused bool false)

;; Mining rig data structure
(define-map mining-rigs
    uint
    {
        owner: principal,
        rig-type: (string-ascii 20),
        efficiency: uint,
        last-mine-time: uint,
    }
)

;; Artifact data structure
(define-map artifacts
    uint
    {
        owner: principal,
        name: (string-ascii 30),
        rarity: (string-ascii 10),
        artifact-type: (string-ascii 20),
        power: uint,
    }
)

;; Player stats
(define-map player-stats
    principal
    {
        total-burned: uint,
        total-mined: uint,
        rigs-owned: uint,
        artifacts-owned: uint,
    }
)

;; Resource tracking for forging
(define-map player-resources
    principal
    {
        iron: uint,
        crystal: uint,
        energy: uint,
    }
)

;; NFT URI and metadata
(define-data-var base-uri (string-ascii 100) "https://stxforge.game/metadata/")

;; SIP-009 implementation functions
(define-read-only (get-last-token-id)
    (ok (+ (var-get last-rig-id) (var-get last-artifact-id)))
)

(define-read-only (get-token-uri (token-id uint))
    (ok (some (concat (var-get base-uri) (int-to-ascii token-id))))
)

(define-read-only (get-owner (token-id uint))
    (let (
            (rig-owner (get owner (map-get? mining-rigs token-id)))
            (artifact-owner (get owner (map-get? artifacts token-id)))
        )
        (if (is-some rig-owner)
            (ok rig-owner)
            (if (is-some artifact-owner)
                (ok artifact-owner)
                ERR-NOT-FOUND
            )
        )
    )
)

(define-public (transfer
        (token-id uint)
        (sender principal)
        (recipient principal)
    )
    (let ((owner (unwrap! (unwrap! (get-owner token-id) ERR-NOT-FOUND) ERR-NOT-FOUND)))
        (asserts! (or (is-eq tx-sender sender) (is-eq tx-sender owner))
            ERR-UNAUTHORIZED
        )
        (asserts! (is-eq owner sender) ERR-UNAUTHORIZED)
        (if (is-some (map-get? mining-rigs token-id))
            (map-set mining-rigs token-id
                (merge (unwrap-panic (map-get? mining-rigs token-id)) { owner: recipient })
            )
            (map-set artifacts token-id
                (merge (unwrap-panic (map-get? artifacts token-id)) { owner: recipient })
            )
        )
        (print {
            action: "transfer",
            token-id: token-id,
            sender: sender,
            recipient: recipient,
        })
        (ok true)
    )
)

;; Mint a basic mining rig (free for new players)
(define-public (mint-basic-rig)
    (let (
            (next-id (+ (var-get last-rig-id) u1))
            (player tx-sender)
        )
        (asserts! (not (var-get game-paused)) ERR-UNAUTHORIZED)
        (asserts! (is-none (map-get? player-stats player)) ERR-ALREADY-EXISTS)

        (map-set mining-rigs next-id {
            owner: player,
            rig-type: "basic",
            efficiency: u1,
            last-mine-time: u0,
        })

        (map-set player-stats player {
            total-burned: u0,
            total-mined: u0,
            rigs-owned: u1,
            artifacts-owned: u0,
        })

        (map-set player-resources player {
            iron: u0,
            crystal: u0,
            energy: u0,
        })

        (var-set last-rig-id next-id)
        (print {
            action: "mint-rig",
            rig-id: next-id,
            player: player,
            type: "basic",
        })
        (ok next-id)
    )
)

;; Read-only functions for game state
(define-read-only (get-rig-data (rig-id uint))
    (map-get? mining-rigs rig-id)
)

(define-read-only (get-artifact-data (artifact-id uint))
    (map-get? artifacts artifact-id)
)

(define-read-only (get-player-stats (player principal))
    (map-get? player-stats player)
)

(define-read-only (get-player-resources (player principal))
    (map-get? player-resources player)
)

(define-read-only (get-total-stx-burned)
    (var-get total-stx-burned)
)

(define-read-only (can-mine-now (rig-id uint))
    (match (map-get? mining-rigs rig-id)
        rig-data (>= (- burn-block-height (get last-mine-time rig-data)) MINING-COOLDOWN)
        false
    )
)

;; Admin functions
(define-public (set-base-uri (new-uri (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set base-uri new-uri)
        (ok true)
    )
)

(define-public (pause-game)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set game-paused true)
        (ok true)
    )
)

(define-public (unpause-game)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set game-paused false)
        (ok true)
    )
)

;; Mining function (free daily action)
(define-public (mine (rig-id uint))
    (let (
            (rig-data (unwrap! (map-get? mining-rigs rig-id) ERR-NOT-FOUND))
            (player tx-sender)
            (current-time burn-block-height)
        )
        (asserts! (not (var-get game-paused)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get owner rig-data) player) ERR-UNAUTHORIZED)
        (asserts!
            (>= (- current-time (get last-mine-time rig-data)) MINING-COOLDOWN)
            ERR-COOLDOWN-ACTIVE
        )

        ;; Update rig last mine time
        (map-set mining-rigs rig-id
            (merge rig-data { last-mine-time: current-time })
        )

        ;; Simple randomization based on block height and rig ID
        (let (
                (random-value (mod (+ burn-block-height rig-id) u100))
                (efficiency (get efficiency rig-data))
            )
            ;; Determine mining outcome based on efficiency and randomness
            (if (<= random-value (* efficiency u20))
                ;; Found resources
                (let ((resource-type (mod random-value u3)))
                    (update-player-resources player resource-type u1)
                    (update-player-stats player u0 u1 u0 u0)
                    (print {
                        action: "mine",
                        player: player,
                        rig-id: rig-id,
                        result: "resource",
                        type: resource-type,
                    })
                    (ok "resource-found")
                )
                ;; Found nothing
                (begin
                    (print {
                        action: "mine",
                        player: player,
                        rig-id: rig-id,
                        result: "nothing",
                    })
                    (ok "nothing-found")
                )
            )
        )
    )
)

;; Forge function (burns STX to create artifacts)
(define-public (forge
        (resource-type uint)
        (quantity uint)
    )
    (let (
            (player tx-sender)
            (burn-amount FORGE-COST)
            (current-resources (unwrap! (map-get? player-resources player) ERR-NOT-FOUND))
        )
        (asserts! (not (var-get game-paused)) ERR-UNAUTHORIZED)
        (asserts! (> quantity u0) ERR-INVALID-AMOUNT)

        ;; Check if player has enough resources
        (asserts!
            (>= (get-resource-amount current-resources resource-type) quantity)
            ERR-INSUFFICIENT-FUNDS
        )

        ;; Burn STX
        (unwrap! (stx-transfer? burn-amount player BURN-ADDRESS)
            ERR-INSUFFICIENT-FUNDS
        )

        ;; Deduct resources
        (update-player-resources player resource-type (- u0 quantity))

        ;; Create artifact with randomized properties
        (let (
                (artifact-id (+ (var-get last-artifact-id) u1))
                (random-value (mod (+ burn-block-height artifact-id resource-type) u100))
                (artifact-rarity (get-rarity-from-random random-value))
                (artifact-power (+ u1 (mod random-value u10)))
            )
            (map-set artifacts artifact-id {
                owner: player,
                name: (get-artifact-name resource-type artifact-rarity),
                rarity: artifact-rarity,
                artifact-type: (get-artifact-type resource-type),
                power: artifact-power,
            })

            (var-set last-artifact-id artifact-id)
            (var-set total-stx-burned (+ (var-get total-stx-burned) burn-amount))
            (update-player-stats player burn-amount u0 u0 u1)

            (print {
                action: "forge",
                player: player,
                artifact-id: artifact-id,
                burn-amount: burn-amount,
                rarity: artifact-rarity,
            })
            (ok artifact-id)
        )
    )
)

;; Helper functions for forging
(define-private (get-resource-amount
        (resources {
            iron: uint,
            crystal: uint,
            energy: uint,
        })
        (resource-type uint)
    )
    (if (is-eq resource-type u0)
        (get iron resources)
        (if (is-eq resource-type u1)
            (get crystal resources)
            (get energy resources)
        )
    )
)

(define-private (update-player-resources
        (player principal)
        (resource-type uint)
        (amount uint)
    )
    (let ((current-resources (default-to {
            iron: u0,
            crystal: u0,
            energy: u0,
        }
            (map-get? player-resources player)
        )))
        (if (is-eq resource-type u0)
            (map-set player-resources player
                (merge current-resources { iron: (+ (get iron current-resources) amount) })
            )
            (if (is-eq resource-type u1)
                (map-set player-resources player
                    (merge current-resources { crystal: (+ (get crystal current-resources) amount) })
                )
                (map-set player-resources player
                    (merge current-resources { energy: (+ (get energy current-resources) amount) })
                )
            )
        )
    )
)

(define-private (update-player-stats
        (player principal)
        (burned uint)
        (mined uint)
        (rigs uint)
        (artifacts-count uint)
    )
    (let ((current-stats (default-to {
            total-burned: u0,
            total-mined: u0,
            rigs-owned: u0,
            artifacts-owned: u0,
        }
            (map-get? player-stats player)
        )))
        (map-set player-stats player {
            total-burned: (+ (get total-burned current-stats) burned),
            total-mined: (+ (get total-mined current-stats) mined),
            rigs-owned: (+ (get rigs-owned current-stats) rigs),
            artifacts-owned: (+ (get artifacts-owned current-stats) artifacts-count),
        })
    )
)

(define-private (get-rarity-from-random (random uint))
    (if (<= random u5)
        "legendary"
        (if (<= random u20)
            "epic"
            (if (<= random u50)
                "rare"
                "common"
            )
        )
    )
)

(define-private (get-artifact-name
        (resource-type uint)
        (rarity (string-ascii 10))
    )
    (if (is-eq resource-type u0)
        (concat rarity " Iron Blade")
        (if (is-eq resource-type u1)
            (concat rarity " Crystal Orb")
            (concat rarity " Energy Core")
        )
    )
)

(define-private (get-artifact-type (resource-type uint))
    (if (is-eq resource-type u0)
        "weapon"
        (if (is-eq resource-type u1)
            "magic"
            "tech"
        )
    )
)

;; Deep-core mining (burns 50 STX for higher rewards)
(define-public (deep-core-mine (rig-id uint))
    (let (
            (rig-data (unwrap! (map-get? mining-rigs rig-id) ERR-NOT-FOUND))
            (player tx-sender)
            (burn-amount DEEP-CORE-COST)
        )
        (asserts! (not (var-get game-paused)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get owner rig-data) player) ERR-UNAUTHORIZED)
        
        ;; Burn STX for deep-core access
        (unwrap! (stx-transfer? burn-amount player BURN-ADDRESS) ERR-INSUFFICIENT-FUNDS)
        
        ;; Enhanced randomization for deep-core mining
        (let (
                (random-value (mod (+ burn-block-height rig-id (var-get total-stx-burned)) u100))
                (efficiency (get efficiency rig-data))
            )
            ;; Deep-core has much better odds (80% success rate)
            (if (<= random-value u80)
                ;; Success - create rare artifact directly
                (let (
                        (artifact-id (+ (var-get last-artifact-id) u1))
                        (artifact-rarity (get-rare-rarity-from-random random-value))
                        (artifact-power (+ u5 (mod random-value u15)))
                        (resource-type (mod random-value u3))
                    )
                    (map-set artifacts artifact-id {
                        owner: player,
                        name: (get-artifact-name resource-type artifact-rarity),
                        rarity: artifact-rarity,
                        artifact-type: (get-artifact-type resource-type),
                        power: artifact-power,
                    })
                    
                    (var-set last-artifact-id artifact-id)
                    (var-set total-stx-burned (+ (var-get total-stx-burned) burn-amount))
                    (update-player-stats player burn-amount u0 u0 u1)
                    
                    (print {
                        action: "deep-core-mine",
                        player: player,
                        rig-id: rig-id,
                        artifact-id: artifact-id,
                        burn-amount: burn-amount,
                        rarity: artifact-rarity,
                    })
                    (ok artifact-id)
                )
                ;; Failure - still update stats
                (begin
                    (var-set total-stx-burned (+ (var-get total-stx-burned) burn-amount))
                    (update-player-stats player burn-amount u0 u0 u0)
                    (print {
                        action: "deep-core-mine",
                        player: player,
                        rig-id: rig-id,
                        result: "nothing",
                        burn-amount: burn-amount,
                    })
                    (ok u0)
                )
            )
        )
    )
)

;; Enhanced rarity calculation for deep-core mining
(define-private (get-rare-rarity-from-random (random uint))
    (if (<= random u15)
        "legendary"
        (if (<= random u40)
            "epic"
            "rare"
        )
    )
)

;; Simple marketplace - list artifact for sale
(define-map marketplace-listings uint {
    seller: principal,
    price: uint,
    artifact-id: uint,
    active: bool
})

(define-data-var last-listing-id uint u0)

(define-public (list-artifact-for-sale (artifact-id uint) (price uint))
    (let (
            (artifact-data (unwrap! (map-get? artifacts artifact-id) ERR-NOT-FOUND))
            (listing-id (+ (var-get last-listing-id) u1))
            (seller tx-sender)
        )
        (asserts! (is-eq (get owner artifact-data) seller) ERR-UNAUTHORIZED)
        (asserts! (> price u0) ERR-INVALID-AMOUNT)
        (asserts! (not (var-get game-paused)) ERR-UNAUTHORIZED)
        
        (map-set marketplace-listings listing-id {
            seller: seller,
            price: price,
            artifact-id: artifact-id,
            active: true,
        })
        
        (var-set last-listing-id listing-id)
        (print {
            action: "list-artifact",
            seller: seller,
            artifact-id: artifact-id,
            listing-id: listing-id,
            price: price,
        })
        (ok listing-id)
    )
)

(define-public (buy-artifact (listing-id uint))
    (let (
            (listing (unwrap! (map-get? marketplace-listings listing-id) ERR-NOT-FOUND))
            (buyer tx-sender)
            (seller (get seller listing))
            (price (get price listing))
            (artifact-id (get artifact-id listing))
        )
        (asserts! (get active listing) ERR-UNAUTHORIZED)
        (asserts! (not (is-eq buyer seller)) ERR-UNAUTHORIZED)
        (asserts! (not (var-get game-paused)) ERR-UNAUTHORIZED)
        
        ;; Transfer STX from buyer to seller
        (unwrap! (stx-transfer? price buyer seller) ERR-INSUFFICIENT-FUNDS)
        
        ;; Transfer artifact ownership
        (map-set artifacts artifact-id 
            (merge (unwrap-panic (map-get? artifacts artifact-id)) {owner: buyer}))
        
        ;; Deactivate listing
        (map-set marketplace-listings listing-id 
            (merge listing {active: false}))
        
        (print {
            action: "buy-artifact",
            buyer: buyer,
            seller: seller,
            artifact-id: artifact-id,
            listing-id: listing-id,
            price: price,
        })
        (ok true)
    )
)

;; Leaderboard functions
(define-read-only (get-top-burners (limit uint))
    (ok "Leaderboard query - implement with indexing service")
)

(define-read-only (get-player-rank (player principal))
    (let ((stats (map-get? player-stats player)))
        (if (is-some stats)
            (ok (get total-burned (unwrap-panic stats)))
            ERR-NOT-FOUND
        )
    )
)

;; Marketplace read functions  
(define-read-only (get-marketplace-listing (listing-id uint))
    (map-get? marketplace-listings listing-id)
)

(define-read-only (get-active-listings)
    (ok "Active listings - implement with indexing service")
)
