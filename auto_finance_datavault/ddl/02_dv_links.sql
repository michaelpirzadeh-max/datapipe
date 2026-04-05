CREATE SCHEMA IF NOT EXISTS dv;

CREATE TABLE IF NOT EXISTS dv.lnk_loan_vehicle (
    loan_vehicle_hk     CHAR(32) NOT NULL PRIMARY KEY,
    loan_hk             CHAR(32) NOT NULL REFERENCES dv.hub_loan (loan_hk),
    vehicle_hk          CHAR(32) NOT NULL REFERENCES dv.hub_vehicle (vehicle_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    CONSTRAINT uq_lnk_loan_vehicle UNIQUE (loan_hk, vehicle_hk)
);

CREATE TABLE IF NOT EXISTS dv.lnk_loan_dealer (
    loan_dealer_hk      CHAR(32) NOT NULL PRIMARY KEY,
    loan_hk             CHAR(32) NOT NULL REFERENCES dv.hub_loan (loan_hk),
    dealer_hk           CHAR(32) NOT NULL REFERENCES dv.hub_dealer (dealer_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    CONSTRAINT uq_lnk_loan_dealer UNIQUE (loan_hk, dealer_hk)
);

CREATE TABLE IF NOT EXISTS dv.lnk_loan_payment (
    loan_payment_hk     CHAR(32) NOT NULL PRIMARY KEY,
    loan_hk             CHAR(32) NOT NULL REFERENCES dv.hub_loan (loan_hk),
    payment_hk          CHAR(32) NOT NULL REFERENCES dv.hub_payment (payment_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    CONSTRAINT uq_lnk_loan_payment UNIQUE (loan_hk, payment_hk)
);

CREATE TABLE IF NOT EXISTS dv.lnk_loan_customer (
    loan_customer_hk    CHAR(32) NOT NULL PRIMARY KEY,
    loan_hk             CHAR(32) NOT NULL REFERENCES dv.hub_loan (loan_hk),
    customer_hk         CHAR(32) NOT NULL REFERENCES dv.hub_customer (customer_hk),
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    CONSTRAINT uq_lnk_loan_customer UNIQUE (loan_hk, customer_hk)
);
