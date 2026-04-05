-- Operational Hub — Data Vault 2.0 hubs (business keys only + metadata).
CREATE SCHEMA IF NOT EXISTS dv;

CREATE TABLE IF NOT EXISTS dv.hub_loan (
    loan_hk             CHAR(32) NOT NULL PRIMARY KEY,
    loan_bk             VARCHAR(32) NOT NULL,
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    CONSTRAINT uq_hub_loan_bk UNIQUE (loan_bk)
);

CREATE TABLE IF NOT EXISTS dv.hub_vehicle (
    vehicle_hk          CHAR(32) NOT NULL PRIMARY KEY,
    vehicle_bk          VARCHAR(32) NOT NULL,
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    CONSTRAINT uq_hub_vehicle_bk UNIQUE (vehicle_bk)
);

CREATE TABLE IF NOT EXISTS dv.hub_dealer (
    dealer_hk           CHAR(32) NOT NULL PRIMARY KEY,
    dealer_bk           VARCHAR(32) NOT NULL,
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    CONSTRAINT uq_hub_dealer_bk UNIQUE (dealer_bk)
);

CREATE TABLE IF NOT EXISTS dv.hub_payment (
    payment_hk          CHAR(32) NOT NULL PRIMARY KEY,
    payment_bk          VARCHAR(64) NOT NULL,
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    CONSTRAINT uq_hub_payment_bk UNIQUE (payment_bk)
);

-- Enrichment: applicant as separate hub (common in auto finance).
CREATE TABLE IF NOT EXISTS dv.hub_customer (
    customer_hk         CHAR(32) NOT NULL PRIMARY KEY,
    customer_bk         VARCHAR(32) NOT NULL,
    load_dts            TIMESTAMPTZ NOT NULL,
    record_source       VARCHAR(64) NOT NULL,
    CONSTRAINT uq_hub_customer_bk UNIQUE (customer_bk)
);
