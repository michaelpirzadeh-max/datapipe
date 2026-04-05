-- Bronze / Raw Hub — 1:1 with source CSV column names (Postgres).
-- Load order: reference data first, then transactions.

CREATE SCHEMA IF NOT EXISTS bronze;

CREATE TABLE IF NOT EXISTS bronze.dealer_directory (
    dealer_code         VARCHAR(32) PRIMARY KEY,
    dealer_name         VARCHAR(200) NOT NULL,
    region_code         VARCHAR(16),
    effective_from      DATE NOT NULL,
    file_batch_id       VARCHAR(64) NOT NULL,
    ingest_dts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bronze.vehicle_asset_registry (
    vin                 VARCHAR(32) PRIMARY KEY,
    make                VARCHAR(64) NOT NULL,
    model               VARCHAR(64) NOT NULL,
    model_year          SMALLINT NOT NULL,
    trim_code           VARCHAR(32),
    msrp_amount         NUMERIC(12, 2),
    file_batch_id       VARCHAR(64) NOT NULL,
    ingest_dts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bronze.loan_application_extract (
    loan_application_id VARCHAR(32) PRIMARY KEY,
    applicant_customer_id VARCHAR(32) NOT NULL,
    dealer_code         VARCHAR(32) NOT NULL REFERENCES bronze.dealer_directory (dealer_code),
    vin                 VARCHAR(32) NOT NULL REFERENCES bronze.vehicle_asset_registry (vin),
    province_code       CHAR(2) NOT NULL,
    annual_salary       NUMERIC(14, 2) NOT NULL,
    requested_amount    NUMERIC(14, 2) NOT NULL,
    term_months         SMALLINT NOT NULL,
    application_dts     TIMESTAMPTZ NOT NULL,
    file_batch_id       VARCHAR(64) NOT NULL,
    ingest_dts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bronze.daily_pricing_engine_export (
    pricing_run_id      VARCHAR(64) PRIMARY KEY,
    loan_application_id VARCHAR(32) NOT NULL REFERENCES bronze.loan_application_extract (loan_application_id),
    province_code       CHAR(2) NOT NULL,
    annual_salary       NUMERIC(14, 2) NOT NULL,
    salary_band         VARCHAR(32) NOT NULL,
    offered_apr         NUMERIC(6, 4) NOT NULL,
    pricing_run_date    DATE NOT NULL,
    file_batch_id       VARCHAR(64) NOT NULL,
    ingest_dts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bronze.loan_lifecycle_events (
    lifecycle_event_id  VARCHAR(64) PRIMARY KEY,
    loan_application_id VARCHAR(32) NOT NULL REFERENCES bronze.loan_application_extract (loan_application_id),
    event_type          VARCHAR(32) NOT NULL,
    event_status        VARCHAR(32) NOT NULL,
    event_dts           TIMESTAMPTZ NOT NULL,
    decision_reason     VARCHAR(500),
    file_batch_id       VARCHAR(64) NOT NULL,
    ingest_dts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bronze.loan_funding_event (
    funding_event_id    VARCHAR(64) PRIMARY KEY,
    loan_application_id VARCHAR(32) NOT NULL REFERENCES bronze.loan_application_extract (loan_application_id),
    funded_amount       NUMERIC(14, 2) NOT NULL,
    funded_apr          NUMERIC(6, 4) NOT NULL,
    first_payment_date  DATE NOT NULL,
    funding_dts         TIMESTAMPTZ NOT NULL,
    file_batch_id       VARCHAR(64) NOT NULL,
    ingest_dts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bronze.payment_schedule_extract (
    payment_line_id     VARCHAR(64) PRIMARY KEY,
    loan_application_id VARCHAR(32) NOT NULL REFERENCES bronze.loan_application_extract (loan_application_id),
    installment_number  SMALLINT NOT NULL,
    due_date            DATE NOT NULL,
    scheduled_amount    NUMERIC(12, 2) NOT NULL,
    paid_amount         NUMERIC(12, 2),
    paid_dts            TIMESTAMPTZ,
    payment_status      VARCHAR(24) NOT NULL,
    file_batch_id       VARCHAR(64) NOT NULL,
    ingest_dts          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
