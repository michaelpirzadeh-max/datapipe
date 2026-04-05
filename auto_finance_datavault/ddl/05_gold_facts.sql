CREATE SCHEMA IF NOT EXISTS mart;

-- One row per funding event (loan book snapshot grain).
CREATE TABLE IF NOT EXISTS mart.fact_funding (
    funding_sk          BIGSERIAL PRIMARY KEY,
    funding_event_id    VARCHAR(64) NOT NULL,
    loan_sk             BIGINT NOT NULL REFERENCES mart.dim_loan (loan_sk),
    dealer_sk           BIGINT NOT NULL REFERENCES mart.dim_dealer (dealer_sk),
    vehicle_sk          BIGINT NOT NULL REFERENCES mart.dim_vehicle (vehicle_sk),
    customer_sk         BIGINT NOT NULL REFERENCES mart.dim_customer (customer_sk),
    funding_date_key    INTEGER NOT NULL REFERENCES mart.dim_date (date_key),
    funded_amount       NUMERIC(14, 2) NOT NULL,
    funded_apr          NUMERIC(6, 4) NOT NULL,
    first_payment_date_key INTEGER NOT NULL REFERENCES mart.dim_date (date_key),
    funding_dts         TIMESTAMPTZ NOT NULL,
    UNIQUE (funding_event_id)
);

-- Payment time series: one row per scheduled installment (actuals when paid).
CREATE TABLE IF NOT EXISTS mart.fact_payment (
    payment_fact_sk     BIGSERIAL PRIMARY KEY,
    payment_line_id     VARCHAR(64) NOT NULL,
    loan_sk             BIGINT NOT NULL REFERENCES mart.dim_loan (loan_sk),
    due_date_key        INTEGER NOT NULL REFERENCES mart.dim_date (date_key),
    paid_date_key       INTEGER REFERENCES mart.dim_date (date_key),
    installment_number  SMALLINT NOT NULL,
    scheduled_amount    NUMERIC(12, 2) NOT NULL,
    paid_amount         NUMERIC(12, 2),
    days_late           INTEGER,
    payment_status      VARCHAR(24) NOT NULL,
    UNIQUE (payment_line_id)
);

CREATE INDEX IF NOT EXISTS idx_fact_payment_loan_due ON mart.fact_payment (loan_sk, due_date_key);
