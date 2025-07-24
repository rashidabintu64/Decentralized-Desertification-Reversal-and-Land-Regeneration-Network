;; Drought-Resistant Ecosystem Creation Contract
;; Establishes resilient plant communities in degraded areas

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-ECOSYSTEM-NOT-FOUND (err u401))
(define-constant ERR-INVALID-STATUS (err u402))
(define-constant ERR-INVALID-INPUT (err u403))
(define-constant ERR-SPECIES-NOT-FOUND (err u404))

;; Data Variables
(define-data-var ecosystem-counter uint u0)
(define-data-var species-counter uint u0)
(define-data-var total-area-restored uint u0)

;; Data Maps
(define-map ecosystems
  { ecosystem-id: uint }
  {
    manager: principal,
    location: (string-ascii 100),
    area-hectares: uint,
    climate-zone: (string-ascii 50),
    soil-type: (string-ascii 50),
    average-rainfall: uint,
    temperature-range: (string-ascii 30),
    status: (string-ascii 20),
    establishment-date: uint,
    target-species-count: uint,
    current-species-count: uint,
    biodiversity-index: uint,
    survival-rate: uint
  }
)

(define-map native-species
  { species-id: uint }
  {
    scientific-name: (string-ascii 100),
    common-name: (string-ascii 100),
    species-type: (string-ascii 30),
    drought-tolerance: uint,
    water-requirements: uint,
    growth-rate: (string-ascii 20),
    ecological-function: (string-ascii 100),
    companion-species: (list 5 uint),
    seed-availability: bool
  }
)

(define-map ecosystem-plantings
  { ecosystem-id: uint, species-id: uint }
  {
    planting-date: uint,
    quantity-planted: uint,
    survival-count: uint,
    growth-stage: (string-ascii 30),
    health-status: (string-ascii 20),
    last-assessment: uint
  }
)

(define-map monitoring-data
  { ecosystem-id: uint, assessment-date: uint }
  {
    vegetation-cover: uint,
    species-diversity: uint,
    soil-moisture: uint,
    erosion-control: uint,
    wildlife-activity: uint,
    carbon-sequestration: uint,
    overall-health: uint
  }
)

;; Private Functions
(define-private (is-valid-status (status (string-ascii 20)))
  (or (is-eq status "planning")
      (is-eq status "preparation")
      (is-eq status "planting")
      (is-eq status "establishment")
      (is-eq status "mature")))

(define-private (is-valid-species-type (species-type (string-ascii 30)))
  (or (is-eq species-type "tree")
      (is-eq species-type "shrub")
      (is-eq species-type "grass")
      (is-eq species-type "succulent")
      (is-eq species-type "legume")))

(define-private (calculate-biodiversity-index (species-count uint) (total-area uint))
  (if (is-eq total-area u0)
    u0
    (/ (* species-count u100) total-area)))

;; Public Functions

;; Create a new ecosystem restoration site
(define-public (create-ecosystem
  (location (string-ascii 100))
  (area-hectares uint)
  (climate-zone (string-ascii 50))
  (soil-type (string-ascii 50))
  (average-rainfall uint)
  (temperature-range (string-ascii 30))
  (target-species-count uint))
  (let ((ecosystem-id (+ (var-get ecosystem-counter) u1)))
    (asserts! (> area-hectares u0) ERR-INVALID-INPUT)
    (asserts! (> target-species-count u0) ERR-INVALID-INPUT)

    (map-set ecosystems
      { ecosystem-id: ecosystem-id }
      {
        manager: tx-sender,
        location: location,
        area-hectares: area-hectares,
        climate-zone: climate-zone,
        soil-type: soil-type,
        average-rainfall: average-rainfall,
        temperature-range: temperature-range,
        status: "planning",
        establishment-date: u0,
        target-species-count: target-species-count,
        current-species-count: u0,
        biodiversity-index: u0,
        survival-rate: u0
      })

    (var-set ecosystem-counter ecosystem-id)
    (var-set total-area-restored
      (+ (var-get total-area-restored) area-hectares))
    (ok ecosystem-id)))

;; Add a native species to the database
(define-public (add-native-species
  (scientific-name (string-ascii 100))
  (common-name (string-ascii 100))
  (species-type (string-ascii 30))
  (drought-tolerance uint)
  (water-requirements uint)
  (growth-rate (string-ascii 20))
  (ecological-function (string-ascii 100))
  (companion-species (list 5 uint)))
  (let ((species-id (+ (var-get species-counter) u1)))
    (asserts! (is-valid-species-type species-type) ERR-INVALID-INPUT)
    (asserts! (<= drought-tolerance u10) ERR-INVALID-INPUT)

    (map-set native-species
      { species-id: species-id }
      {
        scientific-name: scientific-name,
        common-name: common-name,
        species-type: species-type,
        drought-tolerance: drought-tolerance,
        water-requirements: water-requirements,
        growth-rate: growth-rate,
        ecological-function: ecological-function,
        companion-species: companion-species,
        seed-availability: true
      })

    (var-set species-counter species-id)
    (ok species-id)))

;; Plant species in ecosystem
(define-public (plant-species
  (ecosystem-id uint)
  (species-id uint)
  (quantity uint))
  (let ((ecosystem (unwrap! (map-get? ecosystems { ecosystem-id: ecosystem-id }) ERR-ECOSYSTEM-NOT-FOUND))
        (species (unwrap! (map-get? native-species { species-id: species-id }) ERR-SPECIES-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get manager ecosystem)) ERR-NOT-AUTHORIZED)
    (asserts! (> quantity u0) ERR-INVALID-INPUT)
    (asserts! (get seed-availability species) ERR-INVALID-INPUT)

    (map-set ecosystem-plantings
      { ecosystem-id: ecosystem-id, species-id: species-id }
      {
        planting-date: block-height,
        quantity-planted: quantity,
        survival-count: quantity,
        growth-stage: "seedling",
        health-status: "healthy",
        last-assessment: block-height
      })

    (map-set ecosystems
      { ecosystem-id: ecosystem-id }
      (merge ecosystem {
        current-species-count: (+ (get current-species-count ecosystem) u1),
        status: "planting"
      }))

    (ok true)))

;; Update planting status
(define-public (update-planting-status
  (ecosystem-id uint)
  (species-id uint)
  (survival-count uint)
  (growth-stage (string-ascii 30))
  (health-status (string-ascii 20)))
  (let ((ecosystem (unwrap! (map-get? ecosystems { ecosystem-id: ecosystem-id }) ERR-ECOSYSTEM-NOT-FOUND))
        (planting (unwrap! (map-get? ecosystem-plantings
          { ecosystem-id: ecosystem-id, species-id: species-id }) ERR-SPECIES-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get manager ecosystem)) ERR-NOT-AUTHORIZED)
    (asserts! (<= survival-count (get quantity-planted planting)) ERR-INVALID-INPUT)

    (map-set ecosystem-plantings
      { ecosystem-id: ecosystem-id, species-id: species-id }
      (merge planting {
        survival-count: survival-count,
        growth-stage: growth-stage,
        health-status: health-status,
        last-assessment: block-height
      }))

    ;; Update ecosystem survival rate
    (let ((total-planted (get quantity-planted planting))
          (survival-rate (if (is-eq total-planted u0) u0
            (/ (* survival-count u100) total-planted))))
      (map-set ecosystems
        { ecosystem-id: ecosystem-id }
        (merge ecosystem { survival-rate: survival-rate })))

    (ok true)))

;; Record monitoring assessment
(define-public (record-assessment
  (ecosystem-id uint)
  (vegetation-cover uint)
  (species-diversity uint)
  (soil-moisture uint)
  (erosion-control uint)
  (wildlife-activity uint)
  (carbon-sequestration uint))
  (let ((ecosystem (unwrap! (map-get? ecosystems { ecosystem-id: ecosystem-id }) ERR-ECOSYSTEM-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get manager ecosystem)) ERR-NOT-AUTHORIZED)
    (asserts! (<= vegetation-cover u100) ERR-INVALID-INPUT)
    (asserts! (<= species-diversity u100) ERR-INVALID-INPUT)

    (let ((overall-health (/ (+ vegetation-cover species-diversity soil-moisture
                               erosion-control wildlife-activity) u5)))
      (map-set monitoring-data
        { ecosystem-id: ecosystem-id, assessment-date: block-height }
        {
          vegetation-cover: vegetation-cover,
          species-diversity: species-diversity,
          soil-moisture: soil-moisture,
          erosion-control: erosion-control,
          wildlife-activity: wildlife-activity,
          carbon-sequestration: carbon-sequestration,
          overall-health: overall-health
        })

      (map-set ecosystems
        { ecosystem-id: ecosystem-id }
        (merge ecosystem {
          biodiversity-index: (calculate-biodiversity-index
            (get current-species-count ecosystem)
            (get area-hectares ecosystem))
        })))

    (ok true)))

;; Update ecosystem status
(define-public (update-ecosystem-status (ecosystem-id uint) (new-status (string-ascii 20)))
  (let ((ecosystem (unwrap! (map-get? ecosystems { ecosystem-id: ecosystem-id }) ERR-ECOSYSTEM-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get manager ecosystem)) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-status new-status) ERR-INVALID-INPUT)

    (map-set ecosystems
      { ecosystem-id: ecosystem-id }
      (merge ecosystem { status: new-status }))

    (ok true)))

;; Read-only functions

(define-read-only (get-ecosystem (ecosystem-id uint))
  (map-get? ecosystems { ecosystem-id: ecosystem-id }))

(define-read-only (get-species (species-id uint))
  (map-get? native-species { species-id: species-id }))

(define-read-only (get-planting (ecosystem-id uint) (species-id uint))
  (map-get? ecosystem-plantings { ecosystem-id: ecosystem-id, species-id: species-id }))

(define-read-only (get-assessment (ecosystem-id uint) (assessment-date uint))
  (map-get? monitoring-data { ecosystem-id: ecosystem-id, assessment-date: assessment-date }))

(define-read-only (get-ecosystem-count)
  (var-get ecosystem-counter))

(define-read-only (get-species-count)
  (var-get species-counter))

(define-read-only (get-total-area-restored)
  (var-get total-area-restored))
