CREATE SCHEMA IF NOT EXISTS dv;

-- Descriptive context on loan hub (application + risk context).
CREATE TABLE IF NOT EXISTS dv.sat_loan_application_detail (
    loan_hk             CHAR(32) NOT NULL REFERENCES dv.hub_loan (loan_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    load_end_dts        TIMESTAMPTZ,
    record_source       VARCHAR(64) NOT NULL,
    hash_diff           CHAR(32) NOT NULL,
    province_code       CHAR(2) NOT NULL,
    annual_salary       NUMERIC(14, 2) NOT NULL,
    requested_amount    NUMERIC(14, 2) NOT NULL,
    term_months         SMALLINT NOT NULL,
    application_dts     TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (loan_hk, load_dts)
);

-- Daily pricing / rate engine outcome (append-only in real life; Type-1-style overwrite OK for sample).
CREATE TABLE IF NOT EXISTS dv.sat_loan_pricing_daily (
    loan_hk             CHAR(32) NOT NULL REFERENCES dv.hub_loan (loan_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    load_end_dts        TIMESTAMPTZ,
    record_source       VARCHAR(64) NOT NULL,
    hash_diff           CHAR(32) NOT NULL,
    pricing_run_id      VARCHAR(64) NOT NULL,
    pricing_run_date    DATE NOT NULL,
    salary_band         VARCHAR(32) NOT NULL,
    offered_apr         NUMERIC(6, 4) NOT NULL,
    PRIMARY KEY (loan_hk, load_dts)
);

-- Transactional / event satellite for lifecycle (approval, reject, resubmit).
CREATE TABLE IF NOT EXISTS dv.sat_loan_lifecycle_event (
    loan_hk             CHAR(32) NOT NULL REFERENCES dv.hub_loan (loan_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    hash_diff           CHAR(32) NOT NULL,
    lifecycle_event_id  VARCHAR(64) NOT NULL,
    event_type          VARCHAR(32) NOT NULL,
    event_status        VARCHAR(32) NOT NULL,
    event_dts           TIMESTAMPTZ NOT NULL,
    decision_reason     VARCHAR(500),
    PRIMARY KEY (loan_hk, lifecycle_event_id, load_dts)
);

CREATE TABLE IF NOT EXISTS dv.sat_vehicle_spec (
    vehicle_hk          CHAR(32) NOT NULL REFERENCES dv.hub_vehicle (vehicle_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    load_end_dts        TIMESTAMPTZ,
    record_source       VARCHAR(64) NOT NULL,
    hash_diff           CHAR(32) NOT NULL,
    make                VARCHAR(64) NOT NULL,
    model               VARCHAR(64) NOT NULL,
    model_year          SMALLINT NOT NULL,
    trim_code           VARCHAR(32),
    msrp_amount         NUMERIC(12, 2),
    PRIMARY KEY (vehicle_hk, load_dts)
);

CREATE TABLE IF NOT EXISTS dv.sat_dealer_profile (
    dealer_hk           CHAR(32) NOT NULL REFERENCES dv.hub_dealer (dealer_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    load_end_dts        TIMESTAMPTZ,
    record_source       VARCHAR(64) NOT NULL,
    hash_diff           CHAR(32) NOT NULL,
    dealer_name         VARCHAR(200) NOT NULL,
    region_code         VARCHAR(16),
    effective_from      DATE NOT NULL,
    PRIMARY KEY (dealer_hk, load_dts)
);

CREATE TABLE IF NOT EXISTS dv.sat_payment_schedule_line (
    loan_payment_hk     CHAR(32) NOT NULL REFERENCES dv.lnk_loan_payment (loan_payment_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    load_end_dts        TIMESTAMPTZ,
    record_source       VARCHAR(64) NOT NULL,
    hash_diff           CHAR(32) NOT NULL,
    installment_number  SMALLINT NOT NULL,
    due_date            DATE NOT NULL,
    scheduled_amount    NUMERIC(12, 2) NOT NULL,
    paid_amount         NUMERIC(12, 2),
    paid_dts            TIMESTAMPTZ,
    payment_status      VARCHAR(24) NOT NULL,
    PRIMARY KEY (loan_payment_hk, load_dts)
);

CREATE TABLE IF NOT EXISTS dv.sat_funding_event (
    loan_hk             CHAR(32) NOT NULL REFERENCES dv.hub_loan (loan_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    hash_diff           CHAR(32) NOT NULL,
    funding_event_id    VARCHAR(64) NOT NULL,
    funded_amount       NUMERIC(14, 2) NOT NULL,
    funded_apr          NUMERIC(6, 4) NOT NULL,
    first_payment_date  DATE NOT NULL,
    funding_dts         TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (loan_hk, funding_event_id, load_dts)
);
